module.exports = function createBuiltInGraphPlugin(obsidian) {
  const { Notice, Plugin, PluginSettingTab, Setting, setIcon } = obsidian;

  const PLUGIN_LABEL = "\u0416\u0438\u0437\u043d\u044c";
  const GRAPH_VIEW_TYPE = "graph";
  const DEFAULT_SETTINGS = {
    autoOpenGraph: true,
    autoCycleLinks: true,
    cycleIntervalMs: 300000,
    batchSize: 5,
    pulseCount: 3,
    detachHoldMs: 15000,
    restoreHoldMs: 5000,
    bufferLimit: 12,
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

  function injectStyles() {
    if (typeof document === "undefined") return;
    if (document.getElementById("life-plugin-styles")) return;
    const style = document.createElement("style");
    style.id = "life-plugin-styles";
    style.textContent = `
      .life-plugin-card {
        border: 1px solid var(--background-modifier-border);
        background: linear-gradient(180deg, rgba(120, 170, 255, 0.08), rgba(120, 170, 255, 0.03));
        border-radius: 14px;
        padding: 14px 16px;
        margin: 14px 0 18px;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.08);
      }
      .life-plugin-card h3 {
        margin: 0 0 8px;
        font-size: 1.05em;
      }
      .life-plugin-card p {
        margin: 0 0 12px;
        color: var(--text-muted);
      }
      .life-plugin-actions {
        display: flex;
        flex-wrap: wrap;
        gap: 8px;
      }
      .life-plugin-action {
        border: 1px solid var(--background-modifier-border);
        border-radius: 999px;
        padding: 8px 14px;
        background: var(--background-primary);
        color: var(--text-normal);
        cursor: pointer;
        transition: transform 120ms ease, background 120ms ease, border-color 120ms ease;
      }
      .life-plugin-action:hover {
        transform: translateY(-1px);
        border-color: var(--interactive-accent);
        background: var(--background-secondary-alt);
      }
      .life-plugin-action.is-primary {
        background: var(--interactive-accent);
        color: var(--text-on-accent);
        border-color: var(--interactive-accent);
      }
      .life-plugin-action.is-danger {
        background: rgba(255, 100, 100, 0.12);
        color: var(--text-normal);
      }
    `;
    document.head.appendChild(style);
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

  function sleep(ms) {
    return new Promise((resolve) => window.setTimeout(resolve, ms));
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
      const { label } = parseWikiLinkBody(match[1]);
      const replacement = label || match[1];
      candidates.push({
        start: match.index,
        end: match.index + match[0].length,
        original: match[0],
        replacement,
      });
    }
    return candidates;
  }

  class GraphSettingsTab extends PluginSettingTab {
    constructor(app, plugin) {
      super(app, plugin);
      this.plugin = plugin;
    }

    display() {
      const { containerEl } = this;
      clearElement(containerEl);
      injectStyles();
      containerEl.createEl("h2", { text: PLUGIN_LABEL });

      const card = containerEl.createDiv({ cls: "life-plugin-card" });
      card.createEl("h3", { text: "Quick controls" });
      card.createEl("p", {
        text: "Run the living cycle, restore everything, or reopen the built-in graph.",
      });

      const actions = card.createDiv({ cls: "life-plugin-actions" });

      const cycleButton = actions.createEl("button", {
        text: "Run cycle",
        cls: "life-plugin-action is-primary",
      });
      cycleButton.addEventListener("click", () => {
        void this.plugin.cycleLinks(true);
      });

      const restoreButton = actions.createEl("button", {
        text: "Restore now",
        cls: "life-plugin-action is-danger",
      });
      restoreButton.addEventListener("click", () => {
        void this.plugin.recoverFromBuffer(true);
      });

      const graphButton = actions.createEl("button", {
        text: "Open graph",
        cls: "life-plugin-action",
      });
      graphButton.addEventListener("click", () => {
        void this.plugin.openBuiltInGraph(true);
      });

      new Setting(containerEl)
        .setName("Open built-in Graph")
        .setDesc("Open Obsidian's built-in Graph view automatically when the vault loads.")
        .addToggle((toggle) =>
          toggle.setValue(this.plugin.settings.autoOpenGraph).onChange(async (value) => {
            this.plugin.settings.autoOpenGraph = value;
            await this.plugin.saveState();
          }),
        );

      new Setting(containerEl)
        .setName("Auto cycle links")
        .setDesc("Automatically remove and restore wiki links in batches.")
        .addToggle((toggle) =>
          toggle.setValue(this.plugin.settings.autoCycleLinks).onChange(async (value) => {
            this.plugin.settings.autoCycleLinks = value;
            await this.plugin.saveState();
          }),
        );

      new Setting(containerEl)
        .setName("Cycle interval")
        .setDesc("How often a link batch is detached and then restored, in milliseconds.")
        .addSlider((slider) =>
          slider
            .setLimits(30000, 900000, 30000)
            .setValue(this.plugin.settings.cycleIntervalMs)
            .setDynamicTooltip()
            .onChange(async (value) => {
              this.plugin.settings.cycleIntervalMs = value;
              await this.plugin.saveState();
              this.plugin.restartTimer();
            }),
        );

      new Setting(containerEl)
        .setName("Batch size")
        .setDesc("How many notes get one link detached per cycle.")
        .addSlider((slider) =>
          slider
            .setLimits(1, 20, 1)
            .setValue(this.plugin.settings.batchSize)
            .setDynamicTooltip()
            .onChange(async (value) => {
              this.plugin.settings.batchSize = value;
              await this.plugin.saveState();
            }),
        );

      new Setting(containerEl)
        .setName("Pulse count")
        .setDesc("How many detach/restore pulses run in one cycle.")
        .addSlider((slider) =>
          slider
            .setLimits(1, 10, 1)
            .setValue(this.plugin.settings.pulseCount)
            .setDynamicTooltip()
            .onChange(async (value) => {
              this.plugin.settings.pulseCount = value;
              await this.plugin.saveState();
            }),
        );

      new Setting(containerEl)
        .setName("Detach hold")
        .setDesc("How long links stay detached before they are restored.")
        .addSlider((slider) =>
          slider
            .setLimits(3000, 120000, 3000)
            .setValue(this.plugin.settings.detachHoldMs)
            .setDynamicTooltip()
            .onChange(async (value) => {
              this.plugin.settings.detachHoldMs = value;
              await this.plugin.saveState();
            }),
        );

      new Setting(containerEl)
        .setName("Restore hold")
        .setDesc("How long to wait after restoring before starting the next pulse.")
        .addSlider((slider) =>
          slider
            .setLimits(1000, 30000, 1000)
            .setValue(this.plugin.settings.restoreHoldMs)
            .setDynamicTooltip()
            .onChange(async (value) => {
              this.plugin.settings.restoreHoldMs = value;
              await this.plugin.saveState();
            }),
        );

      new Setting(containerEl)
        .setName("Buffer limit")
        .setDesc("How many recent detach snapshots the safety buffer remembers.")
        .addSlider((slider) =>
          slider
            .setLimits(3, 50, 1)
            .setValue(this.plugin.settings.bufferLimit)
            .setDynamicTooltip()
            .onChange(async (value) => {
              this.plugin.settings.bufferLimit = value;
              await this.plugin.saveState();
            }),
        );

      containerEl.createEl("p", {
        text: "This plugin edits wiki links in your notes, so keep it enabled only if you want the text itself to change and then be restored.",
      });
    }
  }

  return class BuiltInGraphPlugin extends Plugin {
    async onload() {
      try {
        injectStyles();
        const data = (await this.loadData()) || {};
        const legacySettings = data.settings || data;
        this.settings = Object.assign({}, DEFAULT_SETTINGS, legacySettings);
        this.activeBatch = data.activeBatch || null;
        this.safetyBuffer = Array.isArray(data.safetyBuffer) ? data.safetyBuffer : [];
        this.interval = null;
        this.busy = false;
        this.cycleId = 0;

        this.addCommand({
          id: "open-live-graph",
          name: `Open ${PLUGIN_LABEL} graph`,
          callback: () => {
            void this.openBuiltInGraph();
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
            void this.restoreActiveBatch(true);
          },
        });

        const ribbon = this.addRibbonIcon("activity", `Cycle ${PLUGIN_LABEL} links`, () => {
          void this.cycleLinks(true);
        });
        if (ribbon) {
          setLifeIcon(ribbon);
        }

        this.addSettingTab(new GraphSettingsTab(this.app, this));

        this.app.workspace.onLayoutReady(() => {
          if (this.settings.autoOpenGraph) {
            void this.openBuiltInGraph().catch((error) => {
              console.error(`[${PLUGIN_LABEL}] graph open failed`, error);
            });
          }
          void this.recoverFromBuffer().catch((error) => {
            console.error(`[${PLUGIN_LABEL}] recovery restore failed`, error);
          });
          this.restartTimer();
          if (this.settings.autoCycleLinks) {
            void this.cycleLinks(true).catch((error) => {
              console.error(`[${PLUGIN_LABEL}] initial cycle failed`, error);
            });
          }
        });
      } catch (error) {
        console.error(`[${PLUGIN_LABEL}] failed to load`, error);
        new Notice(`${PLUGIN_LABEL} failed to load. Check the console.`);
      }
    }

    async onunload() {
      this.stopTimer();
      if (this.activeBatch?.files?.length || this.hasDetachedBuffer()) {
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

    async saveState() {
      await this.saveData({
        settings: this.settings,
        activeBatch: this.activeBatch,
        safetyBuffer: this.safetyBuffer,
      });
    }

    trimBuffer() {
      const limit = Math.max(1, Number(this.settings.bufferLimit) || 12);
      if (this.safetyBuffer.length > limit) {
        this.safetyBuffer = this.safetyBuffer.slice(-limit);
      }
    }

    async recordDetachedBatch(batch) {
      const entry = {
        id: `${Date.now()}-${Math.random().toString(16).slice(2)}`,
        createdAt: new Date().toISOString(),
        status: "detached",
        files: batch.files.map((file) => ({ ...file })),
      };
      this.safetyBuffer.push(entry);
      this.trimBuffer();
      this.cycleId = entry.id;
      this.activeBatch = { files: batch.files.map((file) => ({ ...file })), cycleId: entry.id };
      await this.saveState();
      return entry;
    }

    async markBufferRestored(entryId) {
      const entry = this.safetyBuffer.find((item) => item.id === entryId);
      if (entry) {
        entry.status = "restored";
        entry.restoredAt = new Date().toISOString();
      }
      if (this.activeBatch?.cycleId === entryId) {
        this.activeBatch = null;
      }
      await this.saveState();
    }

    async recoverFromBuffer(force = false) {
      const detachedEntries = this.safetyBuffer.filter((entry) => entry.status === "detached");
      if (!detachedEntries.length) {
        return true;
      }

      for (const entry of detachedEntries) {
        for (const snapshot of entry.files) {
          const file = this.app.vault.getAbstractFileByPath(snapshot.path);
          if (!file) continue;
          const current = await this.app.vault.read(file);
          if (force || current === snapshot.detached) {
            await this.app.vault.modify(file, snapshot.original);
          }
        }
        entry.status = "restored";
        entry.restoredAt = new Date().toISOString();
      }

      this.activeBatch = null;
      await this.saveState();
      return true;
    }

    async openBuiltInGraph(showNotice = false) {
      let leaf = this.app.workspace.getLeavesOfType(GRAPH_VIEW_TYPE)[0];
      if (!leaf) {
        leaf = this.app.workspace.getLeaf(true);
      }
      await leaf.setViewState({
        type: GRAPH_VIEW_TYPE,
        active: true,
        state: {},
      });
      if (typeof this.app.workspace.revealLeaf === "function") {
        this.app.workspace.revealLeaf(leaf);
      }
      if (showNotice) {
        new Notice(`${PLUGIN_LABEL}: opened built-in Graph`);
      }
    }

    getMarkdownFiles() {
      return this.app.vault
        .getMarkdownFiles()
        .filter((file) => !file.path.startsWith("."));
    }

    async pickBatchCandidates(batchSize) {
      const files = shuffle(this.getMarkdownFiles());
      const candidates = [];
      for (const file of files) {
        if (candidates.length >= batchSize) break;
        const text = await this.app.vault.read(file);
        const links = extractWikiLinkCandidates(text);
        if (!links.length) continue;
        const link = links[Math.floor(Math.random() * links.length)];
        candidates.push({
          path: file.path,
          original: text,
          detached: replaceRange(text, link.start, link.end, link.replacement),
        });
      }
      return candidates;
    }

    async cycleLinks(showNotice = false) {
      if (this.busy) return;
      this.busy = true;
      try {
        await this.recoverFromBuffer(false);

        const pulseCount = Math.max(1, Number(this.settings.pulseCount) || 3);
        for (let pulse = 0; pulse < pulseCount; pulse += 1) {
          const batchSize = Math.max(1, Number(this.settings.batchSize) || 5);
          const candidates = await this.pickBatchCandidates(batchSize);
          if (!candidates.length) {
            new Notice(`${PLUGIN_LABEL}: no wiki links found to cycle.`);
            return;
          }

          for (const snapshot of candidates) {
            const file = this.app.vault.getAbstractFileByPath(snapshot.path);
            if (!file) continue;
            const current = await this.app.vault.read(file);
            if (current !== snapshot.original) continue;
            await this.app.vault.modify(file, snapshot.detached);
          }

          const entry = await this.recordDetachedBatch({ files: candidates });
          await this.openBuiltInGraph(false);

          if (showNotice && pulse === 0) {
            new Notice(`${PLUGIN_LABEL}: detached ${candidates.length} link(s)`);
          }

          await sleep(Math.max(0, Number(this.settings.detachHoldMs) || 0));
          await this.recoverFromBuffer(false);
          await this.markBufferRestored(entry.id);
          await sleep(Math.max(0, Number(this.settings.restoreHoldMs) || 0));
        }
      } finally {
        this.busy = false;
      }
    }
  };
};
