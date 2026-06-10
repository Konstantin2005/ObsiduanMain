module.exports = function createBuiltInGraphPlugin(obsidian) {
  const {
    ItemView,
    Plugin,
    PluginSettingTab,
    Setting,
    setIcon,
  } = obsidian;
  const zlib = require("zlib");

  const BaseItemView = typeof ItemView === "function" ? ItemView : class {};
  const BasePluginSettingTab =
    typeof PluginSettingTab === "function" ? PluginSettingTab : class {};
  const BasePlugin = typeof Plugin === "function" ? Plugin : class {};
  const hasRequiredApi =
    typeof ItemView === "function" &&
    typeof Plugin === "function" &&
    typeof PluginSettingTab === "function" &&
    typeof Setting === "function" &&
    typeof setIcon === "function";

  const PLUGIN_LABEL = "\u0416\u0438\u0437\u043d\u044c";
  const PANEL_VIEW_TYPE = "life-panel";

  const DEFAULT_SETTINGS = {
    autoOpenPanel: true,
    autoCycleLinks: false,
    cycleIntervalMs: 300000,
    batchSize: 5,
    pulseCount: 3,
    detachHoldMs: 15000,
    restoreHoldMs: 5000,
    bufferLimit: 12,
    cycleMode: "prune-heavy",
  };

  function svgEl(tag, attrs = {}) {
    const el = document.createElementNS("http://www.w3.org/2000/svg", tag);
    for (const [key, value] of Object.entries(attrs)) {
      if (value === undefined || value === null) continue;
      el.setAttribute(key, String(value));
    }
    return el;
  }

  function clearElement(element) {
    if (!element) return;
    if (typeof element.empty === "function") {
      element.empty();
    } else {
      element.innerHTML = "";
    }
  }

  function sleep(ms) {
    return new Promise((resolve) => window.setTimeout(resolve, ms));
  }

  function encodeSnapshotText(text) {
    if (typeof text !== "string" || text.length < 1024) {
      return text;
    }

    const compressed = zlib.deflateSync(Buffer.from(text, "utf8")).toString("base64");
    return compressed.length + 16 < text.length ? `~z~${compressed}` : text;
  }

  function decodeSnapshotText(text) {
    if (typeof text !== "string") {
      return "";
    }

    if (!text.startsWith("~z~")) {
      return text;
    }

    return zlib.inflateSync(Buffer.from(text.slice(3), "base64")).toString("utf8");
  }

  function packSnapshot(snapshot) {
    return {
      ...snapshot,
      original: encodeSnapshotText(snapshot.original),
      detached: encodeSnapshotText(snapshot.detached),
    };
  }

  function unpackSnapshot(snapshot) {
    if (!snapshot) return snapshot;
    return {
      ...snapshot,
      original: decodeSnapshotText(snapshot.original),
      detached: decodeSnapshotText(snapshot.detached),
    };
  }

  function packEntry(entry) {
    return {
      ...entry,
      files: Array.isArray(entry?.files) ? entry.files.map(packSnapshot) : [],
    };
  }

  function unpackEntry(entry) {
    return {
      ...entry,
      files: Array.isArray(entry?.files) ? entry.files.map(unpackSnapshot) : [],
    };
  }

  async function sleepWithStop(ms, shouldStop) {
    const total = Math.max(0, Number(ms) || 0);
    const step = 250;
    for (let elapsed = 0; elapsed < total; elapsed += step) {
      if (shouldStop()) return false;
      await sleep(Math.min(step, total - elapsed));
    }
    return !shouldStop();
  }

  function injectStyles() {
    if (typeof document === "undefined") return;
    if (
      typeof document.getElementById === "function" &&
      document.getElementById("life-plugin-styles")
    ) {
      return;
    }
    const style = document.createElement("style");
    style.id = "life-plugin-styles";
    style.textContent = `
      .life-panel-shell {
        display: flex;
        flex-direction: column;
        gap: 8px;
        padding: 8px;
      }
      .life-mini-window {
        display: flex;
        flex-direction: column;
        gap: 10px;
        padding: 10px;
        border: 1px solid var(--background-modifier-border);
        border-radius: 12px;
        background: var(--background-secondary);
        box-shadow: 0 8px 20px rgba(0, 0, 0, 0.06);
      }
      .life-mini-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 8px;
      }
      .life-mini-title {
        font-size: 0.98em;
        font-weight: 700;
        margin: 0;
      }
      .life-mini-status {
        color: var(--text-muted);
        font-size: 0.78em;
        line-height: 1.3;
      }
      .life-mini-control {
        display: flex;
        flex-direction: column;
        gap: 6px;
      }
      .life-mini-label {
        font-size: 0.8em;
        color: var(--text-muted);
      }
      .life-mini-slider-row {
        display: grid;
        grid-template-columns: auto 1fr;
        align-items: center;
        gap: 8px;
      }
      .life-mini-value {
        min-width: 3.5em;
        text-align: right;
        font-variant-numeric: tabular-nums;
        color: var(--text-muted);
        font-size: 0.8em;
      }
      .life-mini-slider {
        width: 100%;
      }
      .life-mini-toggle {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        min-height: 30px;
        padding: 0 10px;
        border: 1px solid var(--background-modifier-border);
        border-radius: 999px;
        background: var(--background-primary);
        color: var(--text-normal);
        cursor: pointer;
      }
      .life-mini-state {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        min-height: 30px;
        padding: 0 10px;
        border: 1px solid var(--background-modifier-border);
        border-radius: 999px;
        background: rgba(255, 255, 255, 0.04);
        color: var(--text-muted);
        cursor: default;
        font-size: 0.8em;
      }
      .life-mini-state.is-active {
        border-color: var(--interactive-accent);
        background: rgba(120, 170, 255, 0.16);
        color: var(--text-normal);
      }
      .life-mini-toggle.is-active {
        border-color: var(--interactive-accent);
        background: rgba(120, 170, 255, 0.16);
      }
      .life-mini-note {
        color: var(--text-muted);
        font-size: 0.76em;
      }
    `;
    const mountTarget = document.head || document.body;
    if (mountTarget && typeof mountTarget.appendChild === "function") {
      mountTarget.appendChild(style);
    }
  }

  function setLifeIcon(element) {
    if (typeof document === "undefined" || !element) return;
    const svg = svgEl("svg", {
      viewBox: "0 0 24 24",
      width: "18",
      height: "18",
      fill: "none",
      class: "life-ribbon-icon",
    });
    svg.appendChild(
      svgEl("path", {
        d: "M4 12.2c1.7-2.7 3.2-4.1 4.5-4.1 1.6 0 2.4 2 3.5 4.7 1-2.2 2-4 3.7-4 1.5 0 2.7 1.2 4.3 4.2",
        stroke: "currentColor",
        "stroke-width": 1.9,
        "stroke-linecap": "round",
        "stroke-linejoin": "round",
      }),
    );
    svg.appendChild(
      svgEl("path", {
        d: "M4 12.2h2.4l1.4-2.6 1.8 5 1.8-3.3 1.1 1.9h2.8",
        stroke: "currentColor",
        "stroke-width": 1.9,
        "stroke-linecap": "round",
        "stroke-linejoin": "round",
      }),
    );
    svg.appendChild(
      svgEl("circle", {
        cx: 12,
        cy: 12,
        r: 8.5,
        stroke: "currentColor",
        "stroke-width": 1.3,
        opacity: 0.35,
      }),
    );
    clearElement(element);
    element.appendChild(svg);
  }

  function shuffle(items) {
    const out = items.slice();
    for (let i = out.length - 1; i > 0; i -= 1) {
      const j = Math.floor(Math.random() * (i + 1));
      [out[i], out[j]] = [out[j], out[i]];
    }
    return out;
  }

  function replaceRange(text, start, end, replacement) {
    return `${text.slice(0, start)}${replacement}${text.slice(end)}`;
  }

  function parseWikiLinkBody(body) {
    const aliasIndex = body.indexOf("|");
    const target = aliasIndex >= 0 ? body.slice(0, aliasIndex) : body;
    const alias = aliasIndex >= 0 ? body.slice(aliasIndex + 1) : "";
    return {
      target: target.trim(),
      label: (alias || target).trim(),
    };
  }

  function extractWikiLinkCandidates(text) {
    const candidates = [];
    const re = /\[\[([^\]]+)\]\]/g;
    let match;
    while ((match = re.exec(text))) {
      if (match.index > 0 && text[match.index - 1] === "!") continue;
      const { target, label } = parseWikiLinkBody(match[1]);
      candidates.push({
        start: match.index,
        end: match.index + match[0].length,
        original: match[0],
        target,
        detached: label || match[1],
      });
    }
    return candidates;
  }

  function formatMs(ms) {
    const value = Math.max(0, Number(ms) || 0);
    if (value >= 60000) {
      return `${Math.round(value / 60000)}m`;
    }
    return `${Math.round(value / 1000)}s`;
  }

  function pickTempoLabel(settings) {
    const interval = Number(settings.cycleIntervalMs) || 0;
    if (interval <= 180000) return "Lively";
    if (interval <= 360000) return "Balanced";
    return "Gentle";
  }

  function pickModeLabel(mode) {
    switch (mode) {
      case "prune-heavy":
        return "Prune Hubs";
      case "equalize":
        return "Equalize";
      case "regrow":
        return "Regrow";
      case "cascade-one":
        return "To One";
      default:
        return "Prune Hubs";
    }
  }

  function pickModeHint(mode) {
    switch (mode) {
      case "prune-heavy":
        return "Remove links from the most connected notes first.";
      case "equalize":
        return "Push highly connected notes down until the graph feels even.";
      case "regrow":
        return "Restore the latest detached batch and let the graph breathe back in.";
      case "cascade-one":
        return "Gradually reduce every note to one connected link, then bring the links back.";
      default:
        return "Remove links from the most connected notes first.";
    }
  }

  class LifePanelView extends BaseItemView {
    constructor(leaf, plugin) {
      super(leaf);
      this.plugin = plugin;
      this.statusEl = null;
      this.rootEl = null;
      this.lastStatusText = "";
    }

    getViewType() {
      return PANEL_VIEW_TYPE;
    }

    getDisplayText() {
      return PLUGIN_LABEL;
    }

    getIcon() {
      return "activity";
    }

    async onOpen() {
      clearElement(this.containerEl);
      this.rootEl = this.containerEl.createDiv({ cls: "life-panel-shell" });
      this.render();
    }

    async onClose() {
      this.plugin.panelViews.delete(this);
    }

    render() {
      if (!this.rootEl) return;
      clearElement(this.rootEl);
      injectStyles();
      this.plugin.renderSettingsBlock(this.rootEl, this);
    }

    refreshStatus() {
      if (!this.statusEl) return;
      const detached = this.plugin.safetyBuffer.filter((entry) => entry.status === "detached").length;
      const text = `Buffer: ${this.plugin.safetyBuffer.length} | Detached: ${detached} | ${this.plugin.busy ? "busy" : "idle"}`;
      if (text === this.lastStatusText) return;
      this.lastStatusText = text;
      this.statusEl.setText(text);
    }
  }

  class LifeSettingsTab extends BasePluginSettingTab {
    constructor(app, plugin) {
      super(app, plugin);
      this.plugin = plugin;
    }

    display() {
      const { containerEl } = this;
      clearElement(containerEl);
      injectStyles();
      containerEl.createEl("h2", { text: PLUGIN_LABEL });
      this.plugin.renderSettingsBlock(containerEl);
    }
  }

  return class BuiltInGraphPlugin extends BasePlugin {
    async onload() {
      try {
        if (!hasRequiredApi) {
          console.error(`[${PLUGIN_LABEL}] missing required Obsidian exports`);
          return;
        }
        injectStyles();
        const data = (await this.loadData()) || {};
        const legacySettings = data.settings || data;
        this.settings = Object.assign({}, DEFAULT_SETTINGS, legacySettings);
        this.activeBatch = data.activeBatch ? unpackEntry(data.activeBatch) : null;
        this.safetyBuffer = Array.isArray(data.safetyBuffer) ? data.safetyBuffer.map(unpackEntry) : [];
        this.interval = null;
        this.busy = false;
        this.stopRequested = false;
        this.panelViews = new Set();

        this.registerView(PANEL_VIEW_TYPE, (leaf) => {
          const view = new LifePanelView(leaf, this);
          this.panelViews.add(view);
          return view;
        });

        this.addCommand({
          id: "open-life-panel",
          name: `Open ${PLUGIN_LABEL} panel`,
          callback: () => {
            void this.openLifePanel();
          },
        });

        this.addCommand({
          id: "cycle-live-links",
          name: `Cycle ${PLUGIN_LABEL} links`,
          callback: () => {
            void this.cycleLinks(true);
          },
        });

        this.addCommand({
          id: "restore-live-links",
          name: `Restore ${PLUGIN_LABEL} links`,
          callback: () => {
            void this.recoverFromBuffer(true);
          },
        });

        const ribbon = this.addRibbonIcon("activity", `Open ${PLUGIN_LABEL} panel`, () => {
          void this.openLifePanel();
        });
        if (ribbon) {
          setLifeIcon(ribbon);
        }

        this.addSettingTab(new LifeSettingsTab(this.app, this));

        this.app.workspace.onLayoutReady(() => {
          void this.recoverFromBuffer().catch((error) => {
            console.error(`[${PLUGIN_LABEL}] recovery restore failed`, error);
          });
          this.restartTimer();
          if (this.settings.autoOpenPanel) {
            void this.openLifePanel().catch((error) => {
              console.error(`[${PLUGIN_LABEL}] panel open failed`, error);
            });
          }
          if (this.settings.autoCycleLinks) {
            void this.cycleLinks(true).catch((error) => {
              console.error(`[${PLUGIN_LABEL}] initial cycle failed`, error);
            });
          }
        });
      } catch (error) {
        console.error(`[${PLUGIN_LABEL}] failed to load`, error);
      }
    }

    async onunload() {
      this.stopTimer();
      this.panelViews.clear();
      if (this.hasDetachedBuffer()) {
        try {
          await this.recoverFromBuffer(true);
        } catch (error) {
          console.error(`[${PLUGIN_LABEL}] unload restore failed`, error);
        }
      }
    }

    hasDetachedBuffer() {
      return this.safetyBuffer.some((entry) => entry.status === "detached");
    }

    restartTimer() {
      this.stopTimer();
      if (!this.settings.autoCycleLinks) return;
      this.interval = window.setInterval(() => {
        if (this.busy) return;
        void this.cycleLinks(false).catch((error) => {
          console.error(`[${PLUGIN_LABEL}] cycle failed`, error);
        });
      }, this.settings.cycleIntervalMs);
    }

    stopTimer() {
      if (this.interval) {
        window.clearInterval(this.interval);
        this.interval = null;
      }
    }

    async stopCycle(save = false) {
      this.stopRequested = true;
      this.settings.autoCycleLinks = false;
      this.stopTimer();
      if (save) {
        await this.saveState();
      }
      this.refreshPanelViews();
      return true;
    }

    async setLiveMovement(enabled) {
      if (enabled === this.settings.autoCycleLinks) return;
      if (!enabled) {
        await this.stopCycle(true);
        return;
      }

      this.settings.autoCycleLinks = true;
      await this.saveState();
      this.restartTimer();
      this.refreshPanelViews();
      void this.cycleLinks(true).catch((error) => {
        console.error(`[${PLUGIN_LABEL}] live cycle failed`, error);
      });
    }

    async saveState() {
      await this.saveData({
        settings: this.settings,
        activeBatch: this.activeBatch ? packEntry(this.activeBatch) : null,
        safetyBuffer: this.safetyBuffer.map(packEntry),
      });
    }

    trimBuffer() {
      const limit = Math.max(1, Number(this.settings.bufferLimit) || 12);
      if (this.safetyBuffer.length > limit) {
        this.safetyBuffer = this.safetyBuffer.slice(-limit);
      }
    }

    getLastDetachedEntry() {
      for (let i = this.safetyBuffer.length - 1; i >= 0; i -= 1) {
        const entry = this.safetyBuffer[i];
        if (entry.status === "detached") {
          return entry;
        }
      }
      return null;
    }

    async openLifePanel() {
      const leaf =
        this.app.workspace.getLeavesOfType(PANEL_VIEW_TYPE)[0] ||
        (typeof this.app.workspace.getRightLeaf === "function"
          ? this.app.workspace.getRightLeaf(false)
          : null);
      if (!leaf) return;
      await leaf.setViewState({
        type: PANEL_VIEW_TYPE,
        active: true,
        state: {},
      });
      if (typeof this.app.workspace.revealLeaf === "function") {
        this.app.workspace.revealLeaf(leaf);
      }
      this.refreshPanelViews();
    }

    refreshPanelViews() {
      for (const view of this.panelViews) {
        if (view?.render) {
          view.render();
        }
      }
    }

    async readFileLinkStats(file) {
      const text = await this.app.vault.read(file);
      return {
        text,
        links: extractWikiLinkCandidates(text),
      };
    }

    resolveLinkedTarget(file, link) {
      const cache = this.app.metadataCache;
      if (!cache || typeof cache.getFirstLinkpathDest !== "function") {
        return true;
      }
      return Boolean(cache.getFirstLinkpathDest(link.target, file.path));
    }

    async chooseCandidates(batchSize) {
      const files = shuffle(this.app.vault.getMarkdownFiles().filter((file) => !file.path.startsWith(".")));
      const stats = [];
      for (const file of files) {
        const { text, links } = await this.readFileLinkStats(file);
        const connectedLinks = links.filter((link) => this.resolveLinkedTarget(file, link));
        if (!connectedLinks.length) continue;
        stats.push({ file, text, links: connectedLinks, linkCount: connectedLinks.length });
      }

      if (!stats.length) {
        return [];
      }

      const mode = this.settings.cycleMode || "prune-heavy";
      if (mode === "regrow" || mode === "cascade-one") {
        return [];
      }

      const ranked = stats
        .map((item) => ({
          path: item.file.path,
          original: item.text,
          detached: this.detachOneLink(item.text, mode, item.links),
          linkCount: item.linkCount,
        }))
        .sort((left, right) => {
          if (left.linkCount !== right.linkCount) return right.linkCount - left.linkCount;
          return left.path.localeCompare(right.path);
        });

      const overloaded = ranked.filter((item) => item.linkCount > 1);
      const fallback = ranked.filter((item) => item.linkCount <= 1);
      if (mode === "equalize") {
        if (!overloaded.length) {
          return [];
        }
        return overloaded.slice(0, batchSize);
      }
      return ranked.slice(0, batchSize);
    }

    async chooseCascadeCandidates() {
      const files = shuffle(this.app.vault.getMarkdownFiles().filter((file) => !file.path.startsWith(".")));
      const ranked = [];
      for (const file of files) {
        const { text, links } = await this.readFileLinkStats(file);
        const connectedLinks = links.filter((link) => this.resolveLinkedTarget(file, link));
        if (connectedLinks.length <= 1) continue;
        ranked.push({
          path: file.path,
          original: text,
          links: connectedLinks,
          linkCount: connectedLinks.length,
          detached: this.detachOneLink(text, "cascade-one", connectedLinks),
        });
      }

      return ranked.sort((left, right) => {
        if (left.linkCount !== right.linkCount) return right.linkCount - left.linkCount;
        return left.path.localeCompare(right.path);
      });
    }

    detachOneLink(text, mode, links = null) {
      const linkList = Array.isArray(links) && links.length ? links : extractWikiLinkCandidates(text);
      if (!linkList.length) return text;

      let link = linkList[0];
      if (mode === "prune-heavy") {
        link = linkList[0];
      } else if (mode === "equalize" && linkList.length > 1) {
        link = linkList[linkList.length - 1];
      } else if (mode === "regrow") {
        return text;
      } else {
        link = linkList[Math.floor(Math.random() * linkList.length)];
      }

      return replaceRange(text, link.start, link.end, link.detached);
    }

    async setCycleMode(mode) {
      this.settings.cycleMode = mode;
      await this.saveState();
      this.refreshPanelViews();
    }

    renderSettingsBlock(containerEl, view = null) {
      const card = containerEl.createDiv({ cls: "life-mini-window" });

      const header = card.createDiv({ cls: "life-mini-header" });
      header.createEl("div", { text: PLUGIN_LABEL, cls: "life-mini-title" });
      header.createEl("div", {
        text: this.settings.autoCycleLinks ? "Вкл" : "Выкл",
        cls: `life-mini-state${this.settings.autoCycleLinks ? " is-active" : ""}`,
      });

      const statusText = this.settings.autoCycleLinks
        ? `Живое движение включено · ${formatMs(this.settings.cycleIntervalMs)}`
        : `Живое движение выключено · ${formatMs(this.settings.cycleIntervalMs)}`;
      if (view) {
        view.statusEl = card.createDiv({ cls: "life-mini-status", text: statusText });
        view.lastStatusText = statusText;
      } else {
        card.createDiv({ cls: "life-mini-status", text: statusText });
      }

      const speedControl = card.createDiv({ cls: "life-mini-control" });
      speedControl.createEl("div", { text: "Скорость", cls: "life-mini-label" });
      const speedRow = speedControl.createDiv({ cls: "life-mini-slider-row" });
      const speedValue = speedRow.createEl("div", {
        text: formatMs(this.settings.cycleIntervalMs),
        cls: "life-mini-value",
      });
      const speedInput = speedRow.createEl("input");
      speedInput.type = "range";
      speedInput.min = "30000";
      speedInput.max = "900000";
      speedInput.step = "30000";
      speedInput.value = String(this.settings.cycleIntervalMs);
      speedInput.classList.add("life-mini-slider");
      speedInput.addEventListener("input", async () => {
        const value = Math.max(30000, Math.min(900000, Number(speedInput.value) || 30000));
        speedValue.setText(formatMs(value));
        this.settings.cycleIntervalMs = value;
        await this.saveState();
        this.restartTimer();
        this.refreshPanelViews();
      });

      const liveControl = card.createDiv({ cls: "life-mini-control" });
      liveControl.createEl("div", { text: "Живое движение", cls: "life-mini-label" });
      liveControl.createEl("div", {
        text: "Держит цикл ссылок в работе.",
        cls: "life-mini-note",
      });
      const liveRow = liveControl.createDiv({ cls: "life-mini-slider-row" });
      liveRow.createDiv({ cls: "life-mini-value", text: "" });
      const liveToggle = liveRow.createEl("button", {
        text: this.settings.autoCycleLinks ? "Вкл" : "Выкл",
        cls: `life-mini-toggle${this.settings.autoCycleLinks ? " is-active" : ""}`,
      });
      liveToggle.addEventListener("click", async () => {
        await this.setLiveMovement(!this.settings.autoCycleLinks);
      });

      if (!view) {
        const modeSetting = new Setting(containerEl)
          .setName("\u0420\u0435\u0436\u0438\u043c")
          .setDesc("\u041f\u043b\u0430\u0432\u043d\u043e \u0443\u0431\u0438\u0440\u0430\u0435\u0442 \u043b\u0438\u0448\u043d\u0438\u0435 \u0441\u0441\u044b\u043b\u043a\u0438 \u0434\u043e \u043e\u0434\u043d\u043e\u0439, \u0430 \u043f\u043e\u0442\u043e\u043c \u0432\u043e\u0437\u0432\u0440\u0430\u0449\u0430\u0435\u0442 \u0438\u0445 \u043e\u0431\u0440\u0430\u0442\u043d\u043e.");
        modeSetting.addDropdown((dropdown) =>
          dropdown
            .addOption("prune-heavy", "Prune hubs")
            .addOption("equalize", "Equalize")
            .addOption("regrow", "Regrow")
            .addOption("cascade-one", "To one")
            .setValue(this.settings.cycleMode)
            .onChange(async (value) => {
              await this.setCycleMode(value);
            }),
        );
      }
    }

    async recordDetachedBatch(files) {
      const entry = {
        id: `${Date.now()}-${Math.random().toString(16).slice(2)}`,
        createdAt: new Date().toISOString(),
        status: "detached",
        files: files.map((file) => ({ ...file })),
      };
      this.safetyBuffer.push(entry);
      this.trimBuffer();
      this.activeBatch = { cycleId: entry.id, files: files.map((file) => ({ ...file })) };
      await this.saveState();
      this.refreshPanelViews();
      return entry;
    }

    async recoverFromBuffer(force = false) {
      const detachedEntries = this.safetyBuffer.filter((entry) => entry.status === "detached");
      if (!detachedEntries.length) {
        return true;
      }

      const blocked = [];
      for (const entry of detachedEntries) {
        let entryRestored = true;
        for (const snapshot of entry.files) {
          const file = this.app.vault.getAbstractFileByPath(snapshot.path);
          if (!file) continue;
          const current = await this.app.vault.read(file);
          if (!force && current !== snapshot.detached) {
            blocked.push(snapshot.path);
            entryRestored = false;
            continue;
          }
          if (current !== snapshot.original) {
            await this.app.vault.modify(file, snapshot.original);
          }
        }
        if (entryRestored || force) {
          entry.status = "restored";
          entry.restoredAt = new Date().toISOString();
        }
      }

      this.activeBatch = this.getLastDetachedEntry();
      await this.saveState();
      this.refreshPanelViews();

      if (blocked.length && !force) {
        console.warn(`[${PLUGIN_LABEL}] restore paused because some files changed externally.`);
        return false;
      }

      return true;
    }

    async cycleLinks() {
      if (this.busy) return 0;
      this.stopRequested = false;
      this.busy = true;
      let completed = 0;
      try {
        const restored = await this.recoverFromBuffer(false);
        if (!restored || this.stopRequested) return completed;

        const pulseCount = Math.max(1, Number(this.settings.pulseCount) || 3);
        for (let pulse = 0; pulse < pulseCount; pulse += 1) {
          if (this.stopRequested) break;
          const batchSize = Math.max(1, Number(this.settings.batchSize) || 5);
          const mode = this.settings.cycleMode || "prune-heavy";
          if (mode === "cascade-one") {
            const drainHoldMs = Math.max(0, Number(this.settings.detachHoldMs) || 0);
            let drainedAny = false;
            while (!this.stopRequested) {
              const candidates = await this.chooseCascadeCandidates();
              if (!candidates.length) {
                break;
              }

              for (const snapshot of candidates) {
                const file = this.app.vault.getAbstractFileByPath(snapshot.path);
                if (!file) continue;
                const current = await this.app.vault.read(file);
                if (current !== snapshot.original) continue;
                await this.app.vault.modify(file, snapshot.detached);
              }

              await this.recordDetachedBatch(candidates);
              await this.openLifePanel();
              completed += 1;
              drainedAny = true;

              if (!(await sleepWithStop(drainHoldMs, () => this.stopRequested))) {
                break;
              }
            }

            if (!drainedAny) {
              break;
            }
            if (this.stopRequested) break;
            if (!(await sleepWithStop(Math.max(0, Number(this.settings.restoreHoldMs) || 0), () => this.stopRequested))) {
              break;
            }
            await this.recoverFromBuffer(false);
            await this.refreshPanelViews();
            break;
          }

          if (mode === "regrow") {
            const regrown = await this.recoverFromBuffer(true);
            if (!regrown || this.stopRequested) return completed;
            await this.openLifePanel();
            completed += 1;
            if (!(await sleepWithStop(Math.max(0, Number(this.settings.restoreHoldMs) || 0), () => this.stopRequested))) {
              break;
            }
            continue;
          }

          const candidates = await this.chooseCandidates(batchSize);
          if (!candidates.length || this.stopRequested) {
            console.warn(`[${PLUGIN_LABEL}] no wiki links found to cycle.`);
            return completed;
          }

          for (const snapshot of candidates) {
            const file = this.app.vault.getAbstractFileByPath(snapshot.path);
            if (!file) continue;
            const current = await this.app.vault.read(file);
            if (current !== snapshot.original) continue;
            await this.app.vault.modify(file, snapshot.detached);
          }

          const entry = await this.recordDetachedBatch(candidates);
          await this.openLifePanel();

          if (!(await sleepWithStop(Math.max(0, Number(this.settings.detachHoldMs) || 0), () => this.stopRequested))) {
            break;
          }
          await this.recoverFromBuffer(false);
          entry.status = "restored";
          entry.restoredAt = new Date().toISOString();
          await this.saveState();
          await this.refreshPanelViews();

          if (!(await sleepWithStop(Math.max(0, Number(this.settings.restoreHoldMs) || 0), () => this.stopRequested))) {
            break;
          }
          completed += 1;
        }

        return completed;
      } finally {
        this.busy = false;
        this.stopRequested = false;
        this.refreshPanelViews();
      }
    }
  };
};
