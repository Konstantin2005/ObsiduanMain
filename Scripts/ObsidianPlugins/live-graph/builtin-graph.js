module.exports = function createBuiltInGraphPlugin(obsidian) {
  const { Notice, Plugin, PluginSettingTab, Setting, setIcon } = obsidian;

  const PLUGIN_LABEL = "\u0416\u0438\u0437\u043d\u044c";
  const GRAPH_VIEW_TYPE = "graph";
  const DEFAULT_SETTINGS = {
    autoOpenGraph: true,
    autoCycleLinks: true,
    cycleIntervalMs: 300000,
    batchSize: 5,
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
      containerEl.createEl("h2", { text: PLUGIN_LABEL });

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

      containerEl.createEl("p", {
        text: "This plugin edits wiki links in your notes, so keep it enabled only if you want the text itself to change and then be restored.",
      });
    }
  }

  return class BuiltInGraphPlugin extends Plugin {
    async onload() {
      try {
        const data = (await this.loadData()) || {};
        const legacySettings = data.settings || data;
        this.settings = Object.assign({}, DEFAULT_SETTINGS, legacySettings);
        this.activeBatch = data.activeBatch || null;
        this.interval = null;
        this.busy = false;

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
          if (this.activeBatch?.files?.length) {
            void this.restoreActiveBatch(true).catch((error) => {
              console.error(`[${PLUGIN_LABEL}] recovery restore failed`, error);
            });
          }
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
      if (this.activeBatch?.files?.length) {
        try {
          await this.restoreActiveBatch(false);
        } catch (error) {
          console.error(`[${PLUGIN_LABEL}] unload restore failed`, error);
        }
      }
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
      });
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

    async restoreActiveBatch(force = false) {
      if (!this.activeBatch?.files?.length) return true;

      const pending = [];
      for (const snapshot of this.activeBatch.files) {
        const file = this.app.vault.getAbstractFileByPath(snapshot.path);
        if (!file) continue;

        const current = await this.app.vault.read(file);
        if (!force && current !== snapshot.detached) {
          pending.push(snapshot);
          continue;
        }

        if (current !== snapshot.original) {
          await this.app.vault.modify(file, snapshot.original);
        }
      }

      this.activeBatch = pending.length ? { files: pending } : null;
      await this.saveState();

      if (pending.length) {
        new Notice(`${PLUGIN_LABEL}: some files changed and were not restored.`);
        return false;
      }

      return true;
    }

    async cycleLinks(showNotice = false) {
      if (this.busy) return;
      this.busy = true;
      try {
        if (this.activeBatch?.files?.length) {
          const restored = await this.restoreActiveBatch(false);
          if (!restored) return;
        }

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

        this.activeBatch = { files: candidates };
        await this.saveState();
        await this.openBuiltInGraph(false);

        if (showNotice) {
          new Notice(`${PLUGIN_LABEL}: detached ${candidates.length} link(s)`);
        }
      } finally {
        this.busy = false;
      }
    }
  };
};
