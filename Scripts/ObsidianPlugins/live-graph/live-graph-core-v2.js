module.exports = function createLiveGraphPlugin(obsidian) {
  const {
    ItemView,
    Notice,
    Plugin,
    PluginSettingTab,
    Setting,
    setIcon,
  } = obsidian;

  const VIEW_TYPE = "live-graph-view";
  const DEFAULT_SETTINGS = {
    autoOpen: true,
    maxNodes: 72,
    tickMs: 1500,
    keepRatio: 0.72,
    cycleWindow: 5,
    ghostEdgeRatio: 0.18,
    maxGhostEdges: 24,
  };

  function shuffle(items) {
    const out = items.slice();
    for (let i = out.length - 1; i > 0; i -= 1) {
      const j = Math.floor(Math.random() * (i + 1));
      [out[i], out[j]] = [out[j], out[i]];
    }
    return out;
  }

  function clamp(value, min, max) {
    return Math.min(max, Math.max(min, value));
  }

  function pairKey(a, b) {
    return a < b ? `${a}||${b}` : `${b}||${a}`;
  }

  function shortName(file) {
    return file.basename || file.name || file.path;
  }

  function colorFromString(str) {
    let hash = 0;
    for (let i = 0; i < str.length; i += 1) {
      hash = (hash << 5) - hash + str.charCodeAt(i);
      hash |= 0;
    }
    return `hsl(${Math.abs(hash) % 360} 75% 62%)`;
  }

  function svgEl(tag, attrs = {}) {
    const el = document.createElementNS("http://www.w3.org/2000/svg", tag);
    for (const [key, value] of Object.entries(attrs)) {
      if (value === undefined || value === null) continue;
      el.setAttribute(key, String(value));
    }
    return el;
  }

  class LiveGraphView extends ItemView {
    constructor(leaf, plugin) {
      super(leaf);
      this.plugin = plugin;
      this.interval = null;
      this.paused = false;
      this.sample = [];
      this.edgeOrder = [];
      this.edgeCursor = 0;
      this.positions = new Map();
      this.graphEl = null;
      this.shellEl = null;
      this.statusEl = null;
      this.pauseBtn = null;
      this.svgEl = null;
      this.emptyEl = null;
    }

    getViewType() {
      return VIEW_TYPE;
    }

    getDisplayText() {
      return "Live Graph";
    }

    getIcon() {
      return "activity";
    }

    async onOpen() {
      this.containerEl.empty();
      this.containerEl.addClass("live-graph-shell");

      this.shellEl = this.containerEl.createDiv({ cls: "live-graph-shell-inner" });
      const toolbar = this.shellEl.createDiv({ cls: "live-graph-toolbar" });

      const titleBox = toolbar.createDiv({ cls: "live-graph-titlebox" });
      titleBox.createEl("div", { text: "Live Graph", cls: "live-graph-title" });
      this.statusEl = titleBox.createEl("div", {
        text: "Cycling connections",
        cls: "live-graph-status",
      });

      const controls = toolbar.createDiv({ cls: "live-graph-controls" });

      const refreshBtn = controls.createEl("button", { cls: "live-graph-btn" });
      refreshBtn.type = "button";
      setIcon(refreshBtn, "refresh-cw");
      refreshBtn.setAttribute("aria-label", "Reseed graph");
      refreshBtn.addEventListener("click", () => this.renderGraph(true));

      this.pauseBtn = controls.createEl("button", { cls: "live-graph-btn" });
      this.pauseBtn.type = "button";
      setIcon(this.pauseBtn, "pause");
      this.pauseBtn.setAttribute("aria-label", "Pause animation");
      this.pauseBtn.addEventListener("click", () => this.togglePause());

      const centerBtn = controls.createEl("button", { cls: "live-graph-btn" });
      centerBtn.type = "button";
      setIcon(centerBtn, "scan-search");
      centerBtn.setAttribute("aria-label", "Reset cycle");
      centerBtn.addEventListener("click", () => {
        this.edgeCursor = 0;
        this.positions.clear();
        this.renderGraph(true);
      });

      this.graphEl = this.shellEl.createDiv({ cls: "live-graph-canvas" });
      this.svgEl = svgEl("svg", {
        class: "live-graph-svg",
        preserveAspectRatio: "none",
      });
      this.graphEl.appendChild(this.svgEl);

      this.emptyEl = this.graphEl.createDiv({
        cls: "live-graph-empty",
        text: "Loading live graph…",
      });

      this.renderGraph(true);
      this.interval = window.setInterval(() => {
        if (!this.paused) {
          this.renderGraph(false);
        }
      }, this.plugin.settings.tickMs);
    }

    async onClose() {
      if (this.interval) {
        window.clearInterval(this.interval);
        this.interval = null;
      }
    }

    togglePause() {
      this.paused = !this.paused;
      if (this.pauseBtn) {
        this.pauseBtn.empty();
        setIcon(this.pauseBtn, this.paused ? "play" : "pause");
        this.pauseBtn.setAttribute(
          "aria-label",
          this.paused ? "Resume animation" : "Pause animation",
        );
      }
      if (this.statusEl) {
        this.statusEl.setText(this.paused ? "Paused" : "Cycling connections");
      }
    }

    getMarkdownFiles() {
      return this.plugin.app.vault
        .getMarkdownFiles()
        .filter((file) => !file.path.startsWith("."));
    }

    makeSample(files, maxNodes, forceReseed) {
      const existingPaths = new Set(this.sample.map((file) => file.path));
      const byPath = new Map(files.map((file) => [file.path, file]));

      if (forceReseed || !this.sample.length) {
        return shuffle(files).slice(0, maxNodes);
      }

      const keepTarget = Math.min(
        maxNodes,
        Math.max(1, Math.round(maxNodes * this.plugin.settings.keepRatio)),
      );
      const kept = [];
      for (const path of shuffle(Array.from(existingPaths))) {
        const file = byPath.get(path);
        if (!file) continue;
        kept.push(file);
        if (kept.length >= keepTarget) break;
      }

      const rest = shuffle(files.filter((file) => !kept.some((item) => item.path === file.path)));
      const sample = kept.concat(rest.slice(0, maxNodes - kept.length));
      if (sample.length < maxNodes) {
        const filler = shuffle(files).filter(
          (file) => !sample.some((item) => item.path === file.path),
        );
        sample.push(...filler.slice(0, maxNodes - sample.length));
      }
      return sample.slice(0, maxNodes);
    }

    buildEdges(sample) {
      const sampleSet = new Set(sample.map((file) => file.path));
      const resolved = this.plugin.app.metadataCache.resolvedLinks || {};
      const edgeMap = new Map();
      const degree = new Map();

      for (const file of sample) {
        const outgoing = resolved[file.path] || {};
        for (const target of Object.keys(outgoing)) {
          if (!sampleSet.has(target) || target === file.path) continue;
          const key = pairKey(file.path, target);
          if (!edgeMap.has(key)) {
            edgeMap.set(key, { key, a: file.path, b: target, ghost: false });
          }
          degree.set(file.path, (degree.get(file.path) || 0) + 1);
          degree.set(target, (degree.get(target) || 0) + 1);
        }
      }

      const ghostTarget = Math.min(
        this.plugin.settings.maxGhostEdges,
        Math.max(6, Math.round(sample.length * this.plugin.settings.ghostEdgeRatio)),
      );
      let safety = sample.length * sample.length * 4;
      while (edgeMap.size < ghostTarget + 1 && safety > 0) {
        safety -= 1;
        const first = sample[Math.floor(Math.random() * sample.length)];
        const second = sample[Math.floor(Math.random() * sample.length)];
        if (!first || !second || first.path === second.path) continue;
        const key = pairKey(first.path, second.path);
        if (edgeMap.has(key)) continue;
        edgeMap.set(key, { key, a: first.path, b: second.path, ghost: true });
      }

      const edges = Array.from(edgeMap.values()).sort((left, right) =>
        left.key.localeCompare(right.key),
      );
      const signature = edges.map((edge) => edge.key).join("|");
      return { edges, degree, signature };
    }

    disabledKeysForCycle() {
      const total = this.edgeOrder.length;
      const windowSize = Math.min(
        Math.max(1, Math.floor(this.plugin.settings.cycleWindow)),
        total,
      );
      const disabled = new Set();
      if (!total) return disabled;
      for (let i = 0; i < windowSize; i += 1) {
        const index = (this.edgeCursor + i) % total;
        disabled.add(this.edgeOrder[index].key);
      }
      return disabled;
    }

    ensurePositions(sample, width, height, reseed = false) {
      const next = new Map();
      for (const file of sample) {
        const existing = !reseed ? this.positions.get(file.path) : null;
        const x = existing
          ? clamp(existing.x + (Math.random() - 0.5) * 22, 46, width - 46)
          : 80 + Math.random() * (width - 160);
        const y = existing
          ? clamp(existing.y + (Math.random() - 0.5) * 22, 46, height - 46)
          : 80 + Math.random() * (height - 160);
        next.set(file.path, { x, y });
      }
      this.positions = next;
    }

    renderGraph(forceReseed = false) {
      const files = this.getMarkdownFiles();
      if (!files.length) {
        this.showEmpty("No markdown files found.");
        return;
      }

      const rect = this.graphEl.getBoundingClientRect();
      const width = Math.max(700, Math.floor(rect.width || 1000));
      const height = Math.max(460, Math.floor(rect.height || 700));
      this.svgEl.setAttribute("viewBox", `0 0 ${width} ${height}`);
      this.svgEl.innerHTML = "";

      const maxNodes = Math.min(this.plugin.settings.maxNodes, files.length);
      const sample = this.makeSample(files, maxNodes, forceReseed);
      const sampleSignature = sample.map((file) => file.path).join("|");
      const { edges, degree, signature } = this.buildEdges(sample);

      if (
        forceReseed ||
        !this.sample.length ||
        this.sample.length !== sample.length ||
        this.sampleSignature !== sampleSignature
      ) {
        this.sample = sample;
        this.sampleSignature = sampleSignature;
        this.edgeCursor = 0;
        this.positions.clear();
      }

      const topologyChanged = this.edgeSignature !== signature;
      this.edgeSignature = signature;
      this.edgeOrder = edges;

      if (topologyChanged || forceReseed) {
        this.edgeCursor = 0;
      } else if (this.edgeOrder.length) {
        this.edgeCursor = (this.edgeCursor + 1) % this.edgeOrder.length;
      }

      this.ensurePositions(this.sample, width, height, forceReseed);
      const disabledKeys = this.disabledKeysForCycle();

      const bg = svgEl("rect", {
        x: 0,
        y: 0,
        width,
        height,
        rx: 24,
        ry: 24,
        class: "live-graph-bg",
      });
      this.svgEl.appendChild(bg);

      const defs = svgEl("defs");
      const filter = svgEl("filter", {
        id: "live-graph-glow",
        x: "-20%",
        y: "-20%",
        width: "140%",
        height: "140%",
      });
      filter.appendChild(svgEl("feGaussianBlur", { stdDeviation: "2.25", result: "blur" }));
      const merge = svgEl("feMerge");
      merge.appendChild(svgEl("feMergeNode", { in: "blur" }));
      merge.appendChild(svgEl("feMergeNode", { in: "SourceGraphic" }));
      filter.appendChild(merge);
      defs.appendChild(filter);
      this.svgEl.appendChild(defs);

      const edgesLayer = svgEl("g", { class: "live-graph-edges" });
      for (const edge of this.edgeOrder) {
        const a = this.positions.get(edge.a);
        const b = this.positions.get(edge.b);
        if (!a || !b) continue;
        const disabled = disabledKeys.has(edge.key);
        edgesLayer.appendChild(
          svgEl("line", {
            x1: a.x,
            y1: a.y,
            x2: b.x,
            y2: b.y,
            class: disabled
              ? `live-graph-edge disabled${edge.ghost ? " ghost" : ""}`
              : `live-graph-edge${edge.ghost ? " ghost" : ""}`,
            opacity: disabled ? 0.08 : 0.95,
          }),
        );
      }
      this.svgEl.appendChild(edgesLayer);

      const nodesLayer = svgEl("g", { class: "live-graph-nodes" });
      for (const file of this.sample) {
        const pos = this.positions.get(file.path);
        if (!pos) continue;
        const links = degree.get(file.path) || 0;
        const radius = clamp(5 + Math.sqrt(links), 5, 14);
        const group = svgEl("g", {
          class: "live-graph-node",
          "data-path": file.path,
        });
        group.appendChild(
          svgEl("circle", {
            cx: pos.x,
            cy: pos.y,
            r: radius,
            class: "live-graph-node-dot",
            fill: colorFromString(file.path),
          }),
        );
        const label = svgEl("text", {
          x: pos.x + radius + 7,
          y: pos.y + 4,
          class: "live-graph-node-label",
        });
        label.textContent = shortName(file).slice(0, 36);
        group.appendChild(label);
        group.setAttribute("title", file.path);
        group.addEventListener("click", async () => {
          const target = this.plugin.app.vault.getAbstractFileByPath(file.path);
          if (target) {
            await this.plugin.app.workspace.getLeaf(true).openFile(target);
          } else {
            new Notice(`Cannot open ${file.path}`);
          }
        });
        nodesLayer.appendChild(group);
      }
      this.svgEl.appendChild(nodesLayer);

      if (this.statusEl) {
        this.statusEl.setText(
          `${this.edgeOrder.length} links • ${disabledKeys.size} off • ${this.paused ? "paused" : "cycling"}`,
        );
      }

      this.showEmpty("");
    }

    showEmpty(message) {
      if (!this.emptyEl) return;
      if (message) {
        this.emptyEl.setText(message);
        this.emptyEl.style.display = "grid";
      } else {
        this.emptyEl.style.display = "none";
      }
    }
  }

  class LiveGraphSettingsTab extends PluginSettingTab {
    constructor(app, plugin) {
      super(app, plugin);
      this.plugin = plugin;
    }

    display() {
      const { containerEl } = this;
      containerEl.empty();
      containerEl.createEl("h2", { text: "Live Graph" });

      new Setting(containerEl)
        .setName("Auto open")
        .setDesc("Open the live graph automatically when the vault loads.")
        .addToggle((toggle) =>
          toggle.setValue(this.plugin.settings.autoOpen).onChange(async (value) => {
            this.plugin.settings.autoOpen = value;
            await this.plugin.saveSettings();
          }),
        );

      new Setting(containerEl)
        .setName("Max nodes")
        .setDesc("How many notes the live graph samples at once.")
        .addSlider((slider) =>
          slider
            .setLimits(24, 180, 4)
            .setValue(this.plugin.settings.maxNodes)
            .setDynamicTooltip()
            .onChange(async (value) => {
              this.plugin.settings.maxNodes = value;
              await this.plugin.saveSettings();
            }),
        );

      new Setting(containerEl)
        .setName("Tick interval")
        .setDesc("How often the graph advances in milliseconds.")
        .addSlider((slider) =>
          slider
            .setLimits(500, 5000, 100)
            .setValue(this.plugin.settings.tickMs)
            .setDynamicTooltip()
            .onChange(async (value) => {
              this.plugin.settings.tickMs = value;
              await this.plugin.saveSettings();
            }),
        );

      new Setting(containerEl)
        .setName("Disabled links")
        .setDesc("How many links stay off in the moving cycle.")
        .addSlider((slider) =>
          slider
            .setLimits(1, 20, 1)
            .setValue(this.plugin.settings.cycleWindow)
            .setDynamicTooltip()
            .onChange(async (value) => {
              this.plugin.settings.cycleWindow = value;
              await this.plugin.saveSettings();
            }),
        );
    }
  }

  return class LiveGraphPlugin extends Plugin {
    async onload() {
      this.settings = Object.assign({}, DEFAULT_SETTINGS, (await this.loadData()) || {});
      this.registerView(VIEW_TYPE, (leaf) => new LiveGraphView(leaf, this));
      this.addCommand({
        id: "open-live-graph",
        name: "Open Live Graph",
        callback: () => this.openLiveGraph(),
      });
      this.addRibbonIcon("activity", "Open Live Graph", () => this.openLiveGraph());
      this.addSettingTab(new LiveGraphSettingsTab(this.app, this));

      this.app.workspace.onLayoutReady(() => {
        if (this.settings.autoOpen) {
          this.openLiveGraph();
        }
      });
    }

    async onunload() {
      const leaves = this.app.workspace.getLeavesOfType(VIEW_TYPE);
      for (const leaf of leaves) {
        await leaf.detach();
      }
    }

    async openLiveGraph() {
      let leaf = this.app.workspace.getLeavesOfType(VIEW_TYPE)[0];
      if (!leaf) {
        leaf = this.app.workspace.getLeaf(true);
      }
      await leaf.setViewState({ type: VIEW_TYPE, active: true });
      this.app.workspace.revealLeaf(leaf);
    }

    async saveSettings() {
      await this.saveData(this.settings);
    }
  };
};
