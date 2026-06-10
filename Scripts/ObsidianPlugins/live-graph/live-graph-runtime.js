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
  const NATIVE_GRAPH_VIEW_TYPE = "graph";
  const DEFAULT_SETTINGS = {
    autoOpen: true,
    maxNodes: 64,
    tickMs: 1600,
    keepRatio: 0.72,
    randomEdgeRatio: 0.18,
    maxRandomEdges: 24,
    nativeGraphThreshold: 5000,
  };

  const PLUGIN_LABEL = "Live Graph";

  function clearElement(element) {
    if (!element) return;
    if (typeof element.empty === "function") {
      element.empty();
    } else {
      element.innerHTML = "";
    }
  }

  function setLifeIcon(element) {
    if (typeof document === "undefined" || !element) return;
    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    svg.setAttribute("viewBox", "0 0 24 24");
    svg.setAttribute("width", "18");
    svg.setAttribute("height", "18");
    svg.setAttribute("fill", "none");
    svg.setAttribute("class", "life-ribbon-icon");

    const pathA = document.createElementNS("http://www.w3.org/2000/svg", "path");
    pathA.setAttribute(
      "d",
      "M4 12.2c1.7-2.7 3.2-4.1 4.5-4.1 1.6 0 2.4 2 3.5 4.7 1-2.2 2-4 3.7-4 1.5 0 2.7 1.2 4.3 4.2",
    );
    pathA.setAttribute("stroke", "currentColor");
    pathA.setAttribute("stroke-width", "1.9");
    pathA.setAttribute("stroke-linecap", "round");
    pathA.setAttribute("stroke-linejoin", "round");
    svg.appendChild(pathA);

    const pathB = document.createElementNS("http://www.w3.org/2000/svg", "path");
    pathB.setAttribute("d", "M4 12.2h2.4l1.4-2.6 1.8 5 1.8-3.3 1.1 1.9h2.8");
    pathB.setAttribute("stroke", "currentColor");
    pathB.setAttribute("stroke-width", "1.9");
    pathB.setAttribute("stroke-linecap", "round");
    pathB.setAttribute("stroke-linejoin", "round");
    svg.appendChild(pathB);

    const circle = document.createElementNS("http://www.w3.org/2000/svg", "circle");
    circle.setAttribute("cx", "12");
    circle.setAttribute("cy", "12");
    circle.setAttribute("r", "8.5");
    circle.setAttribute("stroke", "currentColor");
    circle.setAttribute("stroke-width", "1.3");
    circle.setAttribute("opacity", "0.35");
    svg.appendChild(circle);

    clearElement(element);
    element.appendChild(svg);
  }

  function shortName(file) {
    return file.basename || file.name || file.path;
  }

  function clamp(value, min, max) {
    return Math.min(max, Math.max(min, value));
  }

  function pairKey(a, b) {
    return a < b ? `${a}||${b}` : `${b}||${a}`;
  }

  function colorFromString(str) {
    let hash = 0;
    for (let i = 0; i < str.length; i += 1) {
      hash = (hash << 5) - hash + str.charCodeAt(i);
      hash |= 0;
    }
    return `hsl(${Math.abs(hash) % 360} 75% 62%)`;
  }

  function randomSubset(files, maxNodes) {
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

  function roundedRectPath(ctx, x, y, w, h, r) {
    const radius = Math.max(0, Math.min(r, Math.min(w, h) / 2));
    ctx.beginPath();
    ctx.moveTo(x + radius, y);
    ctx.lineTo(x + w - radius, y);
    ctx.quadraticCurveTo(x + w, y, x + w, y + radius);
    ctx.lineTo(x + w, y + h - radius);
    ctx.quadraticCurveTo(x + w, y + h, x + w - radius, y + h);
    ctx.lineTo(x + radius, y + h);
    ctx.quadraticCurveTo(x, y + h, x, y + h - radius);
    ctx.lineTo(x, y + radius);
    ctx.quadraticCurveTo(x, y, x + radius, y);
    ctx.closePath();
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
      this.sampleSignature = "";
      this.edgeSignature = "";
      this.cachedFiles = [];
      this.cachedFilesVersion = -1;
      this.edgeOrder = [];
      this.edgeCursor = 0;
      this.positions = new Map();
      this.graphEl = null;
      this.shellEl = null;
      this.statusEl = null;
      this.pauseBtn = null;
      this.canvasEl = null;
      this.emptyEl = null;
      this.hitTargets = [];
      this.canvasContext = null;
    }

    getViewType() {
      return VIEW_TYPE;
    }

    getDisplayText() {
      return PLUGIN_LABEL;
    }

    getIcon() {
      return "activity";
    }

    async onOpen() {
      clearElement(this.containerEl);
      this.containerEl.addClass("live-graph-shell");

      this.shellEl = this.containerEl.createDiv({ cls: "live-graph-shell-inner" });
      const toolbar = this.shellEl.createDiv({ cls: "live-graph-toolbar" });

      const titleBox = toolbar.createDiv({ cls: "live-graph-titlebox" });
      titleBox.createEl("div", { text: PLUGIN_LABEL, cls: "live-graph-title" });
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
      this.canvasEl = this.graphEl.createEl("canvas", {
        cls: "live-graph-canvas-layer",
      });
      this.canvasEl.addEventListener("click", (event) => this.handleCanvasClick(event));

      this.emptyEl = this.graphEl.createDiv({
        cls: "live-graph-empty",
        text: `Loading ${PLUGIN_LABEL}...`,
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
        clearElement(this.pauseBtn);
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
      const version = this.plugin.graphVersion || 0;
      if (this.cachedFilesVersion !== version) {
        this.cachedFiles = this.plugin.app.vault
          .getMarkdownFiles()
          .filter((file) => !file.path.startsWith("."));
        this.cachedFilesVersion = version;
      }
      return this.cachedFiles;
    }

    getLinkedMarkdownFiles(files) {
      const resolved = this.plugin.app.metadataCache.resolvedLinks || {};
      const fileSet = new Set(files.map((file) => file.path));
      const linkedPaths = new Set();

      for (const file of files) {
        const outgoing = resolved[file.path] || {};
        for (const target of Object.keys(outgoing)) {
          if (target === file.path || !fileSet.has(target)) continue;
          linkedPaths.add(file.path);
          linkedPaths.add(target);
        }
      }

      return files.filter((file) => linkedPaths.has(file.path));
    }

    pickSample(files, maxNodes, forceReseed) {
      const byPath = new Map(files.map((file) => [file.path, file]));
      if (forceReseed || !this.sample.length) {
        return randomSubset(files, maxNodes);
      }

      const keepTarget = Math.min(
        maxNodes,
        Math.max(1, Math.round(maxNodes * this.plugin.settings.keepRatio)),
      );
      const kept = [];
      const seen = new Set();
      for (const file of this.sample) {
        const keptFile = byPath.get(file.path);
        if (!keptFile || seen.has(file.path)) continue;
        kept.push(keptFile);
        seen.add(file.path);
        if (kept.length >= keepTarget) break;
      }

      const rest = files.filter((file) => !seen.has(file.path));
      const sample = kept.concat(randomSubset(rest, maxNodes - kept.length));
      if (sample.length < maxNodes) {
        const filler = files.filter((file) => !sample.some((item) => item.path === file.path));
        sample.push(...randomSubset(filler, maxNodes - sample.length));
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

      const randomEdgeTarget = Math.min(
        this.plugin.settings.maxRandomEdges,
        Math.max(6, Math.round(sample.length * this.plugin.settings.randomEdgeRatio)),
      );
      let safety = sample.length * sample.length * 4;
      while (edgeMap.size < randomEdgeTarget + 1 && safety > 0) {
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
      const windowSize = Math.min(Math.max(1, Math.floor(this.plugin.settings.cycleWindow)), total);
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

    getCanvasContext(width, height) {
      if (!this.canvasEl) return null;
      const dpr = Math.max(1, window.devicePixelRatio || 1);
      const targetWidth = Math.max(1, Math.floor(width * dpr));
      const targetHeight = Math.max(1, Math.floor(height * dpr));
      if (this.canvasEl.width !== targetWidth) {
        this.canvasEl.width = targetWidth;
      }
      if (this.canvasEl.height !== targetHeight) {
        this.canvasEl.height = targetHeight;
      }
      this.canvasEl.style.width = `${width}px`;
      this.canvasEl.style.height = `${height}px`;
      const ctx = this.canvasEl.getContext("2d");
      if (!ctx) return null;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      ctx.imageSmoothingEnabled = true;
      return ctx;
    }

    drawCanvasGraph(width, height, sample, edges, degree, disabledKeys) {
      const ctx = this.getCanvasContext(width, height);
      if (!ctx) {
        this.showEmpty("Canvas rendering is unavailable.");
        return;
      }

      ctx.clearRect(0, 0, width, height);
      ctx.save();
      const bg = ctx.createLinearGradient(0, 0, width, height);
      bg.addColorStop(0, "rgba(80, 120, 255, 0.16)");
      bg.addColorStop(0.5, "rgba(0, 0, 0, 0.04)");
      bg.addColorStop(1, "rgba(255, 132, 111, 0.10)");
      roundedRectPath(ctx, 0, 0, width, height, 24);
      ctx.fillStyle = bg;
      ctx.fill();
      ctx.strokeStyle = "rgba(255,255,255,0.08)";
      ctx.lineWidth = 1;
      ctx.stroke();
      ctx.restore();

      this.hitTargets = [];

      ctx.save();
      ctx.lineCap = "round";
      for (const edge of edges) {
        const a = this.positions.get(edge.a);
        const b = this.positions.get(edge.b);
        if (!a || !b) continue;
        const disabled = disabledKeys.has(edge.key);
        ctx.setLineDash(edge.ghost ? [5, 8] : []);
        ctx.strokeStyle = disabled
          ? edge.ghost
            ? "rgba(120, 120, 120, 0.14)"
            : "rgba(123, 148, 255, 0.08)"
          : edge.ghost
            ? "rgba(120, 120, 120, 0.26)"
            : "rgba(123, 148, 255, 0.38)";
        ctx.lineWidth = edge.ghost ? 1.1 : 1.45;
        ctx.beginPath();
        ctx.moveTo(a.x, a.y);
        ctx.lineTo(b.x, b.y);
        ctx.stroke();
      }
      ctx.restore();

      ctx.save();
      ctx.font = "12px var(--font-interface)";
      ctx.textBaseline = "middle";
      for (const file of sample) {
        const pos = this.positions.get(file.path);
        if (!pos) continue;
        const links = degree.get(file.path) || 0;
        const radius = clamp(5 + Math.sqrt(links), 5, 14);
        const label = shortName(file).slice(0, 36);
        const labelX = pos.x + radius + 7;
        const labelWidth = Math.min(width - labelX - 16, ctx.measureText(label).width + 6);
        const labelHeight = 18;
        const labelY = pos.y - labelHeight / 2;

        this.hitTargets.push({
          path: file.path,
          x: pos.x,
          y: pos.y,
          radius: radius + 4,
          labelX,
          labelY,
          labelWidth,
          labelHeight,
        });

        ctx.beginPath();
        ctx.fillStyle = colorFromString(file.path);
        ctx.arc(pos.x, pos.y, radius, 0, Math.PI * 2);
        ctx.fill();

        ctx.strokeStyle = "rgba(255,255,255,0.30)";
        ctx.lineWidth = 1.4;
        ctx.stroke();

        ctx.fillStyle = getComputedStyle(document.body).getPropertyValue("--text-normal") || "#eaeaea";
        ctx.fillText(label, labelX, pos.y);
      }
      ctx.restore();

      if (this.statusEl) {
        this.statusEl.setText(
          `${edges.length} links • ${disabledKeys.size} off • ${this.paused ? "paused" : "cycling"}`,
        );
      }
    }

    handleCanvasClick(event) {
      if (!this.canvasEl || !this.hitTargets.length) return;
      const rect = this.canvasEl.getBoundingClientRect();
      const x = event.clientX - rect.left;
      const y = event.clientY - rect.top;
      for (let i = this.hitTargets.length - 1; i >= 0; i -= 1) {
        const target = this.hitTargets[i];
        const labelHit =
          x >= target.labelX &&
          x <= target.labelX + target.labelWidth &&
          y >= target.labelY &&
          y <= target.labelY + target.labelHeight;
        const nodeHit = (x - target.x) ** 2 + (y - target.y) ** 2 <= target.radius ** 2;
        if (!labelHit && !nodeHit) continue;
        const file = this.plugin.app.vault.getAbstractFileByPath(target.path);
        if (file) {
          void this.plugin.app.workspace.getLeaf(true).openFile(file);
        } else {
          new Notice(`Cannot open ${target.path}`);
        }
        return;
      }
    }

    renderGraph(forceReseed = false) {
      const files = this.getMarkdownFiles();
      if (!files.length) {
        this.showEmpty("No markdown files found.");
        return;
      }

      const linkedFiles = this.getLinkedMarkdownFiles(files);
      if (linkedFiles.length < 2) {
        this.showEmpty("No linked notes found.");
        if (this.canvasEl) {
          const ctx = this.getCanvasContext(1000, 700);
          if (ctx) ctx.clearRect(0, 0, 1000, 700);
        }
        return;
      }

      const rect = this.graphEl.getBoundingClientRect();
      const width = Math.max(700, Math.floor(rect.width || 1000));
      const height = Math.max(460, Math.floor(rect.height || 700));
      const maxNodes = Math.min(this.plugin.settings.maxNodes, linkedFiles.length);
      const vaultVersion = this.cachedFilesVersion;
      const reseedInterval = linkedFiles.length >= 5000 ? 8 : linkedFiles.length >= 2000 ? 5 : 3;
      const shouldReseed =
        forceReseed ||
        !this.sample.length ||
        this.sampleVaultVersion !== vaultVersion ||
        this.sampleAge >= reseedInterval ||
        this.sample.length !== maxNodes;
      const sample = shouldReseed ? this.pickSample(linkedFiles, maxNodes, true) : this.sample;
      const sampleSignature = sample.map((file) => file.path).join("|");
      const { edges, degree, signature } = this.buildEdges(sample);

      if (shouldReseed || this.sampleSignature !== sampleSignature) {
        this.sample = sample;
        this.sampleSignature = sampleSignature;
        this.edgeCursor = 0;
        this.positions.clear();
      }
      this.sampleVaultVersion = vaultVersion;
      this.sampleAge = shouldReseed ? 0 : this.sampleAge + 1;

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
      this.drawCanvasGraph(width, height, this.sample, edges, degree, disabledKeys);
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

  class LiveGraphSettingsTab extends BasePluginSettingTab {
    constructor(app, plugin) {
      super(app, plugin);
      this.plugin = plugin;
    }

    display() {
      const { containerEl } = this;
      clearElement(containerEl);
      containerEl.createEl("h2", { text: PLUGIN_LABEL });

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
        .setName("Native Graph threshold")
        .setDesc("Vaults at or above this file count open Obsidian's built-in Graph view.")
        .addSlider((slider) =>
          slider
            .setLimits(1000, 20000, 500)
            .setValue(this.plugin.settings.nativeGraphThreshold)
            .setDynamicTooltip()
            .onChange(async (value) => {
              this.plugin.settings.nativeGraphThreshold = value;
              await this.plugin.saveSettings();
            }),
        );
    }
  }

  return class LiveGraphPlugin extends BasePlugin {
    async onload() {
      try {
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
          name: `Open ${PLUGIN_LABEL}`,
          callback: () => {
            void this.openLiveGraph();
          },
        });
        const ribbon = this.addRibbonIcon("activity", `Open ${PLUGIN_LABEL}`, () => {
          void this.openLiveGraph();
        });
        if (ribbon) {
          setLifeIcon(ribbon);
        }
        this.addSettingTab(new LiveGraphSettingsTab(this.app, this));

        this.app.workspace.onLayoutReady(() => {
          if (this.settings.autoOpen) {
            void this.openLiveGraph().catch((error) => {
              console.error(`[${PLUGIN_LABEL}] auto-open failed`, error);
            });
          }
        });
      } catch (error) {
        console.error(`[${PLUGIN_LABEL}] failed to load`, error);
        new Notice(`${PLUGIN_LABEL} failed to load. Check the console.`);
      }
    }

    async onunload() {
      const leaves = this.app.workspace.getLeavesOfType(VIEW_TYPE);
      for (const leaf of leaves) {
        try {
          await leaf.detach();
        } catch (error) {
          console.error(`[${PLUGIN_LABEL}] failed to detach view`, error);
        }
      }
    }

    getFileCount() {
      const files = this.app?.vault?.getMarkdownFiles?.() || [];
      return files.length;
    }

    async openNativeGraph() {
      try {
        let leaf = this.app.workspace.getLeavesOfType(NATIVE_GRAPH_VIEW_TYPE)[0];
        if (!leaf) {
          leaf = this.app.workspace.getLeaf(true);
        }
        await leaf.setViewState({
          type: NATIVE_GRAPH_VIEW_TYPE,
          active: true,
          state: {},
        });
        if (typeof this.app.workspace.revealLeaf === "function") {
          this.app.workspace.revealLeaf(leaf);
        }
      } catch (error) {
        console.error(`[${PLUGIN_LABEL}] failed to open native graph`, error);
        throw error;
      }
    }

    async openLiveGraph() {
      if (this.getFileCount() >= (this.settings.nativeGraphThreshold || 5000)) {
        await this.openNativeGraph();
        return;
      }

      try {
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
      } catch (error) {
        console.error(`[${PLUGIN_LABEL}] failed to open view`, error);
        throw error;
      }
    }

    async saveSettings() {
      await this.saveData(this.settings);
    }
  };
};
