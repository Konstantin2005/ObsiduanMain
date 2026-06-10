module.exports = function createBuiltInGraphPlugin(obsidian) {
  const { Notice, Plugin, PluginSettingTab, Setting, setIcon } = obsidian;

  const PLUGIN_LABEL = "\u0416\u0438\u0437\u043d\u044c";
  const GRAPH_VIEW_TYPE = "graph";
  const DEFAULT_SETTINGS = {
    autoOpen: true,
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
        .setName("Auto open")
        .setDesc("Open the built-in graph automatically when the vault loads.")
        .addToggle((toggle) =>
          toggle.setValue(this.plugin.settings.autoOpen).onChange(async (value) => {
            this.plugin.settings.autoOpen = value;
            await this.plugin.saveSettings();
          }),
        );

      containerEl.createEl("p", {
        text: "This version uses Obsidian's встроенный Graph view instead of a custom panel.",
      });
    }
  }

  return class BuiltInGraphPlugin extends Plugin {
    async onload() {
      try {
        this.settings = Object.assign({}, DEFAULT_SETTINGS, (await this.loadData()) || {});
        this.addCommand({
          id: "open-live-graph",
          name: `Open ${PLUGIN_LABEL}`,
          callback: () => {
            void this.openBuiltInGraph();
          },
        });
        const ribbon = this.addRibbonIcon("activity", `Open ${PLUGIN_LABEL}`, () => {
          void this.openBuiltInGraph();
        });
        if (ribbon) {
          setLifeIcon(ribbon);
        }
        this.addSettingTab(new GraphSettingsTab(this.app, this));

        this.app.workspace.onLayoutReady(() => {
          void this.openBuiltInGraph(true).catch((error) => {
            console.error(`[${PLUGIN_LABEL}] auto-open failed`, error);
          });
        });
      } catch (error) {
        console.error(`[${PLUGIN_LABEL}] failed to load`, error);
        new Notice(`${PLUGIN_LABEL} failed to load. Check the console.`);
      }
    }

    async openBuiltInGraph(showNotice = false) {
      try {
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
      } catch (error) {
        console.error(`[${PLUGIN_LABEL}] failed to open graph view`, error);
        throw error;
      }
    }

    async onunload() {}

    async saveSettings() {
      await this.saveData(this.settings);
    }
  };
};
