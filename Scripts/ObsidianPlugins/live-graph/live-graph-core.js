module.exports = function createLiveGraphPlugin(obsidian) {
  const {
    ItemView,
    Notice,
    Plugin,
    PluginSettingTab,
    Setting,
    setIcon,
  } = obsidian;

  const BaseItemView = typeof ItemView === "function" ? ItemView : class {};
  const BasePluginSettingTab =
    typeof PluginSettingTab === "function" ? PluginSettingTab : class {};
  const BasePlugin = typeof Plugin === "function" ? Plugin : class {};
  const hasRequiredApi =
    typeof ItemView === "function" &&
    typeof Plugin === "function" &&
    typeof PluginSettingTab === "function" &&
    typeof Setting === "function" &&
    typeof setIcon === "function" &&
    typeof Notice === "function";

  const VIEW_TYPE = "live-graph-view";
  const DEFAULT_SETTINGS = {
    autoOpen: true,
    maxNodes: 64,
    tickMs: 1600,
    keepRatio: 0.72,
    randomEdgeRatio: 0.18,
    maxRandomEdges: 24,
  };

  const PLUGIN_LABEL = "Live Graph";

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

  class LiveGraphView extends BaseItemView {
    constructor(leaf, plugin) {
      super(leaf);
      this.plugin = plugin;
      this.interval = null;
      this.paused = false;
      this.sample = [];
      this.sampleVaultVersion = -1;
      this.sampleAge = 0;
      this.cachedFiles = [];
      this.cachedFilesVersion = -1;
      this.positions = new Map();
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
        text: "Sampling vault connections",
        cls: "live-graph-status",
      });

      const controls = toolbar.createDiv({ cls: "live-graph-controls" });

      const refreshBtn = controls.createEl("button", { cls: "live-graph-btn" });
      refreshBtn.type = "button";
      setIcon(refreshBtn, "refresh-cw");
      refreshBtn.setAttribute("aria-label", "Shuffle graph");
      refreshBtn.addEventListener("click", () => this.renderGraph(true));

      this.pauseBtn = controls.createEl("button", { cls: "live-graph-btn" });
      this.pauseBtn.type = "button";
      setIcon(this.pauseBtn, "pause");
      this.pauseBtn.setAttribute("aria-label", "Pause animation");
      this.pauseBtn.addEventListener("click", () => this.togglePause());

      const centerBtn = controls.createEl("button", { cls: "live-graph-btn" });
      centerBtn.type = "button";
      setIcon(centerBtn, "scan-search");
      centerBtn.setAttribute("aria-label", "Reseed positions");
      centerBtn.addEventListener("click", () => {
        this.positions.clear();
        this.renderGraph(true);
      });

      this.graphEl = this.shellEl.createDiv({ cls: "live-graph-canvas" });
      this.svgEl = svgEl("svg", {
        class: "live-graph-svg",
        viewBox: "0 0 1000 700",
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
        this.statusEl.setText(this.paused ? "Paused" : "Sampling vault connections");
      }
    }

    getMarkdownFiles() {
      const version = this.plugin.graphVersion || 0;
      if (this.cachedFilesVersion !== version) {
        this.cachedFiles = this.plugin.app.vault
          .getMarkdownFiles()
          .filter((file) => !file.path.startsWith("."));
        this.cachedFilesVersion = version;
      }
      return this.cachedFiles;
    }

    randomSubset(files, maxNodes) {
      const limit = Math.min(maxNodes, files.length);
      const sample = files.slice(0, limit);
      for (let i = limit; i < files.length; i += 1) {
        const j = Math.floor(Math.random() * (i + 1));
        if (j < limit) {
          sample[j] = files[i];
        }
      }
      return sample;
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
      this.graphEl.removeClass("live-graph-empty-state");

      const maxNodes = Math.min(this.plugin.settings.maxNodes, files.length);
      const vaultVersion = this.cachedFilesVersion;
      const reseedInterval = files.length >= 5000 ? 8 : files.length >= 2000 ? 5 : 3;
      const shouldReseed =
        forceReseed ||
        !this.sample.length ||
        this.sampleVaultVersion !== vaultVersion ||
        this.sampleAge >= reseedInterval ||
        this.sample.length !== maxNodes;
      const nextSample = shouldReseed ? this.pickSample(files, maxNodes, true) : this.sample;
      this.sample = nextSample;
      this.sampleVaultVersion = vaultVersion;
      this.sampleAge = shouldReseed ? 0 : this.sampleAge + 1;

      const sampleSet = new Set(nextSample.map((file) => file.path));
      const resolved = this.plugin.app.metadataCache.resolvedLinks || {};
      const edges = new Map();
      const degree = new Map();

      for (const file of nextSample) {
        const outgoing = resolved[file.path] || {};
        for (const target of Object.keys(outgoing)) {
          if (!sampleSet.has(target) || target === file.path) continue;
          const key = pairKey(file.path, target);
          if (!edges.has(key)) {
            edges.set(key, { a: file.path, b: target, ghost: false });
          }
          degree.set(file.path, (degree.get(file.path) || 0) + 1);
          degree.set(target, (degree.get(target) || 0) + 1);
        }
      }

      const randomTarget = Math.min(
        this.plugin.settings.maxRandomEdges,
        Math.max(6, Math.round(nextSample.length * this.plugin.settings.randomEdgeRatio)),
      );
      let safety = nextSample.length * nextSample.length * 4;
      while (edges.size < randomTarget + 1 && safety > 0) {
        safety -= 1;
        const first = nextSample[Math.floor(Math.random() * nextSample.length)];
        const second = nextSample[Math.floor(Math.random() * nextSample.length)];
        if (!first || !second || first.path === second.path) continue;
        const key = pairKey(first.path, second.path);
        if (edges.has(key)) continue;
        edges.set(key, { a: first.path, b: second.path, ghost: true });
      }

      const newPositions = new Map();
      for (const file of nextSample) {
        const key = file.path;
        const existing = this.positions.get(key);
        const x = existing
          ? clamp(existing.x + (Math.random() - 0.5) * 26, 44, width - 44)
          : 80 + Math.random() * (width - 160);
        const y = existing
          ? clamp(existing.y + (Math.random() - 0.5) * 26, 44, height - 44)
          : 80 + Math.random() * (height - 160);
        newPositions.set(key, { x, y });
      }
      this.positions = newPositions;

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
      defs.appendChild(
        svgEl("filter", {
          id: "live-graph-glow",
          x: "-20%",
          y: "-20%",
          width: "140%",
          height: "140%",
        }),
      );
      const glow = defs.querySelector("filter");
      glow.appendChild(svgEl("feGaussianBlur", { stdDeviation: "2.5", result: "blur" }));
      glow.appendChild(svgEl("feMerge"));
      const merge = glow.querySelector("feMerge");
      merge.appendChild(svgEl("feMergeNode", { in: "blur" }));
      merge.appendChild(svgEl("feMergeNode", { in: "SourceGraphic" }));
      this.svgEl.appendChild(defs);

      const edgesLayer = svgEl("g", { class: "live-graph-edges" });
      for (const edge of edges.values()) {
        const a = this.positions.get(edge.a);
        const b = this.positions.get(edge.b);
        if (!a || !b) continue;
        edgesLayer.appendChild(
          svgEl("line", {
            x1: a.x,
            y1: a.y,
            x2: b.x,
            y2: b.y,
            class: edge.ghost ? "live-graph-edge ghost" : "live-graph-edge",
          }),
        );
      }
      this.svgEl.appendChild(edgesLayer);

      const nodesLayer = svgEl("g", { class: "live-graph-nodes" });
      for (const file of nextSample) {
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
        group.appendChild(
          svgEl("text", {
            x: pos.x + radius + 7,
            y: pos.y + 4,
            class: "live-graph-node-label",
          }),
        );
        const label = group.querySelector("text");
        label.textContent = shortName(file).slice(0, 36);
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
          `${nextSample.length} nodes • ${edges.size} links • ${this.paused ? "paused" : "live"}`,
        );
      }

      this.showEmpty("");
    }

    pickSample(files, maxNodes, forceReseed) {
      const byPath = new Map(files.map((file) => [file.path, file]));
      if (forceReseed || !this.sample.length) {
        return this.randomSubset(files, maxNodes);
      }

      const keepTarget = Math.min(
        maxNodes,
        Math.max(1, Math.round(maxNodes * this.plugin.settings.keepRatio)),
      );
      const kept = [];
      for (const path of shuffle(this.sample.map((file) => file.path))) {
        const file = byPath.get(path);
        if (!file) continue;
        kept.push(file);
        if (kept.length >= keepTarget) break;
      }

      const rest = files.filter((file) => !kept.some((item) => item.path === file.path));
      const sample = kept.concat(this.randomSubset(rest, maxNodes - kept.length));
      if (sample.length < maxNodes) {
        const filler = files.filter((file) => !sample.some((item) => item.path === file.path));
        sample.push(...this.randomSubset(filler, maxNodes - sample.length));
      }
      return sample;
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

  class LiveGraphSettingsTab extends BasePluginSettingTab {
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
            .setLimits(16, 180, 4)
            .setValue(this.plugin.settings.maxNodes)
            .setDynamicTooltip()
            .onChange(async (value) => {
              this.plugin.settings.maxNodes = value;
              await this.plugin.saveSettings();
            }),
        );

      new Setting(containerEl)
        .setName("Tick interval")
        .setDesc("How often the live graph reshuffles in milliseconds.")
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
    }
  }

  return class LiveGraphPlugin extends BasePlugin {
    async onload() {
      if (!hasRequiredApi) {
        const error = new Error("Missing required Obsidian API exports");
        console.error(`[${PLUGIN_LABEL}] failed to load`, error);
        if (typeof Notice === "function") {
          new Notice(`${PLUGIN_LABEL} cannot start in this Obsidian build.`);
        }
        return;
      }
      this.settings = Object.assign({}, DEFAULT_SETTINGS, (await this.loadData()) || {});
      this.graphVersion = 0;
      const bumpGraphVersion = () => {
        this.graphVersion += 1;
      };
      this.registerEvent(this.app.vault.on("create", bumpGraphVersion));
      this.registerEvent(this.app.vault.on("delete", bumpGraphVersion));
      this.registerEvent(this.app.vault.on("rename", bumpGraphVersion));
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
        const rightLeaf =
          typeof this.app.workspace.getRightLeaf === "function"
            ? this.app.workspace.getRightLeaf(false)
            : null;
        leaf = rightLeaf || this.app.workspace.getLeaf(true);
      }
      await leaf.setViewState({ type: VIEW_TYPE, active: true });
      if (typeof this.app.workspace.revealLeaf === "function") {
        this.app.workspace.revealLeaf(leaf);
      }
    }

    async saveSettings() {
      await this.saveData(this.settings);
    }
  };
};
