const { Plugin, Notice } = require("obsidian");

const GRAPH_PATH = ".obsidian/graph.json";
const PROFILE_PATH = ".obsidian/graph-profiles.json";
const GUARD_DATA_PATH = ".obsidian/calendula-graph-guard-data.json";
const FAST_PROFILE = "fast-backbone";
const FULL_PROFILE = "full-danger";
const ULTRA_GRAPH_VIEW_TYPE = "calendula-ultra-graph";
const MAX_INCIDENTS = 50;

const HEAVY_LEAF_TYPES = new Set([
  "backlink",
  "outgoing-link",
  "search",
  "tag",
  "all-properties",
  "outline",
]);

const FALLBACK_FAST_GRAPH = {
  "collapse-filter": false,
  search: "tag:#graph/backbone",
  showTags: false,
  showAttachments: false,
  hideUnresolved: true,
  showOrphans: false,
  "collapse-color-groups": false,
  colorGroups: [
    {
      query: "tag:#graph/backbone path:Calendula",
      color: { a: 1, r: 0.12, g: 0.58, b: 0.95 },
    },
    {
      query: "tag:#graph/backbone -path:Calendula",
      color: { a: 1, r: 1, g: 0.56, b: 0.12 },
    },
  ],
  "collapse-display": false,
  showArrow: false,
  textFadeMultiplier: 0,
  nodeSizeMultiplier: 0.72,
  lineSizeMultiplier: 0.34,
  "collapse-forces": false,
  centerStrength: 0.045,
  repelStrength: 1.15,
  linkStrength: 0.035,
  linkDistance: 26,
  scale: 0.05,
  close: false,
};

function getProfileGraphSettings(profile) {
  if (!profile) return null;
  return profile.graphSettings || profile;
}

function isPolicyProfile(profile) {
  return Boolean(profile && profile.graphSettings);
}

module.exports = class CalendulaGraphGuard extends Plugin {
  async onload() {
    this.guardTimer = null;

    this.addCommand({
      id: "open-fast-backbone-graph",
      name: "Open fast backbone graph",
      callback: async () => {
        await this.applyProfile(FAST_PROFILE, { reason: "command", allowDanger: false });
        await this.openSingleGraphLeaf();
        new Notice("Calendula-20K fast graph profile applied.");
      },
    });

    this.addCommand({
      id: "repair-performance-profile",
      name: "Repair performance profile",
      callback: async () => {
        const result = await this.guardFastProfile("manual-repair");
        new Notice(result.repaired ? "Calendula-20K repaired." : "Calendula-20K is already safe.");
      },
    });

    this.addCommand({
      id: "open-calendula-ultra-graph",
      name: "Open Calendula Ultra Graph",
      callback: async () => {
        await this.guardFastProfile("open-ultra-graph");
        await this.openUltraGraphLeaf();
        new Notice("Calendula Ultra Graph opened with safe native graph profile guarded.");
      },
    });

    this.addCommand({
      id: "apply-full-graph-profile",
      name: "Apply full graph profile (danger)",
      callback: async () => {
        await this.applyProfile(FULL_PROFILE, { reason: "explicit-danger-command", allowDanger: true });
        new Notice("Full graph profile applied. This is intentionally slow and never used for startup.");
      },
    });

    this.app.workspace.onLayoutReady(async () => {
      await this.guardFastProfile("layout-ready");
      this.guardTimer = window.setInterval(() => {
        void this.guardFastProfile("timer");
      }, 15000);
      this.registerInterval(this.guardTimer);
    });
  }

  async readJson(filePath, fallback) {
    try {
      const raw = await this.app.vault.adapter.read(filePath);
      return JSON.parse(raw);
    } catch (error) {
      return fallback;
    }
  }

  async writeJson(filePath, value) {
    await this.app.vault.adapter.write(filePath, `${JSON.stringify(value, null, 2)}\n`);
  }

  async getProfileDocument() {
    const document = await this.readJson(PROFILE_PATH, null);
    if (document?.profiles) return document;
    return {
      schemaVersion: 1,
      defaultProfile: FAST_PROFILE,
      startupProfile: FAST_PROFILE,
      profiles: {
        [FAST_PROFILE]: FALLBACK_FAST_GRAPH,
        [FULL_PROFILE]: {
          ...FALLBACK_FAST_GRAPH,
          search: "",
          nodeSizeMultiplier: 0.25,
          lineSizeMultiplier: 0.12,
          repelStrength: 0.35,
          linkStrength: 0.012,
          linkDistance: 12,
          scale: 0.012,
        },
      },
    };
  }

  async getProfile(profileName) {
    const document = await this.getProfileDocument();
    const profile = document.profiles?.[profileName] || document.profiles?.[document.defaultProfile] || null;
    return {
      document,
      profile,
      graphSettings: getProfileGraphSettings(profile) || FALLBACK_FAST_GRAPH,
    };
  }

  validateProfile(profileName, profile, { allowDanger = false, startup = false } = {}) {
    if (!profile) {
      return { ok: false, reason: `profile-missing:${profileName}` };
    }
    if (!isPolicyProfile(profile)) {
      return { ok: true, reason: "legacy-profile" };
    }
    if (startup && profile.startupAllowed === false) {
      return { ok: false, reason: `startup-disallowed:${profileName}` };
    }
    if ((profile.danger || profile.requiresConfirmation) && !allowDanger) {
      return { ok: false, reason: `danger-confirmation-required:${profileName}` };
    }
    if (profile.renderer === "native" && profile.startupAllowed !== false) {
      const graph = getProfileGraphSettings(profile);
      if (!graph?.search) {
        return { ok: false, reason: `native-startup-empty-search:${profileName}` };
      }
    }
    return { ok: true, reason: "ok" };
  }

  async applyProfile(profileName, options = {}) {
    const { profile, graphSettings } = await this.getProfile(profileName);
    const validation = this.validateProfile(profileName, profile, options);
    if (!validation.ok) {
      await this.logIncident({
        type: "profile-rejected",
        reason: validation.reason,
        profileName,
      });
      throw new Error(validation.reason);
    }
    await this.writeJson(GRAPH_PATH, graphSettings);
    await this.logIncident({
      type: "profile-applied",
      reason: options.reason || "unknown",
      profileName,
      danger: Boolean(profile?.danger),
    });
    return graphSettings;
  }

  isUnsafeGraph(graph) {
    if (!graph) return { unsafe: true, reason: "graph-missing" };
    if (graph.search !== FALLBACK_FAST_GRAPH.search) {
      return { unsafe: true, reason: "search-drift" };
    }
    if (graph.hideUnresolved !== true) {
      return { unsafe: true, reason: "hide-unresolved-drift" };
    }
    if (graph.showOrphans !== false) {
      return { unsafe: true, reason: "show-orphans-drift" };
    }
    if ((Number(graph.repelStrength) || 0) > 1.5) {
      return { unsafe: true, reason: "repel-strength-drift" };
    }
    if ((Number(graph.linkDistance) || 0) > 30) {
      return { unsafe: true, reason: "link-distance-drift" };
    }
    if ((Number(graph.nodeSizeMultiplier) || 0) > 0.8) {
      return { unsafe: true, reason: "node-size-drift" };
    }
    return { unsafe: false, reason: "safe" };
  }

  async guardFastProfile(reason = "timer") {
    const current = await this.readJson(GRAPH_PATH, null);
    const graphSafety = this.isUnsafeGraph(current);
    const workspaceRepair = await this.repairRuntimeWorkspace(reason);
    let repaired = workspaceRepair.repaired;

    if (graphSafety.unsafe) {
      await this.applyProfile(FAST_PROFILE, {
        reason: `quarantine:${reason}:${graphSafety.reason}`,
        allowDanger: false,
        startup: true,
      });
      repaired = true;
    }

    if (repaired) {
      await this.logIncident({
        type: "quarantine-repair",
        reason,
        graphReason: graphSafety.reason,
        workspaceRepair,
      });
    }

    return { repaired, graphReason: graphSafety.reason, workspaceRepair };
  }

  async repairRuntimeWorkspace(reason = "timer") {
    const graphTrim = await this.trimGraphLeaves();
    const heavyTrim = await this.trimHeavyLeaves();
    return {
      reason,
      repaired: graphTrim.detached > 0 || heavyTrim.detached > 0,
      graphLeavesDetached: graphTrim.detached,
      heavyLeavesDetached: heavyTrim.detached,
    };
  }

  async trimGraphLeaves() {
    const leaves =
      typeof this.app.workspace.getLeavesOfType === "function"
        ? this.app.workspace.getLeavesOfType("graph")
        : [];
    let detached = 0;
    for (const leaf of leaves.slice(1)) {
      if (typeof leaf.detach === "function") {
        await leaf.detach();
        detached += 1;
      }
    }
    return { detached };
  }

  async trimHeavyLeaves() {
    const workspace = this.app.workspace;
    if (typeof workspace.iterateAllLeaves !== "function") {
      return { detached: 0 };
    }
    const leavesToDetach = [];
    workspace.iterateAllLeaves((leaf) => {
      const type = leaf?.view?.getViewType?.() || leaf?.view?.getState?.()?.type;
      if (HEAVY_LEAF_TYPES.has(type)) {
        leavesToDetach.push(leaf);
      }
    });
    let detached = 0;
    for (const leaf of leavesToDetach) {
      if (typeof leaf.detach === "function") {
        await leaf.detach();
        detached += 1;
      }
    }
    return { detached };
  }

  async openSingleGraphLeaf() {
    await this.trimGraphLeaves();
    const leaves =
      typeof this.app.workspace.getLeavesOfType === "function"
        ? this.app.workspace.getLeavesOfType("graph")
        : [];
    const leaf = leaves[0] || this.app.workspace.getLeaf(false);
    await leaf.setViewState({ type: "graph", active: true, state: {} });
    if (typeof this.app.workspace.revealLeaf === "function") {
      this.app.workspace.revealLeaf(leaf);
    }
  }

  async openUltraGraphLeaf() {
    const leaf = this.app.workspace.getLeaf(false);
    await leaf.setViewState({ type: ULTRA_GRAPH_VIEW_TYPE, active: true, state: {} });
    if (typeof this.app.workspace.revealLeaf === "function") {
      this.app.workspace.revealLeaf(leaf);
    }
  }

  async logIncident(entry) {
    const now = new Date().toISOString();
    const data = await this.readJson(GUARD_DATA_PATH, {
      schemaVersion: 1,
      repairCount: 0,
      lastRepairAt: null,
      lastDriftReason: null,
      incidents: [],
    });
    const incident = { at: now, ...entry };
    const incidents = Array.isArray(data.incidents) ? data.incidents : [];
    incidents.push(incident);
    data.incidents = incidents.slice(-MAX_INCIDENTS);
    if (entry.type === "quarantine-repair" || entry.type === "profile-applied") {
      data.repairCount = (Number(data.repairCount) || 0) + 1;
      data.lastRepairAt = now;
      data.lastDriftReason = entry.graphReason || entry.reason || null;
    }
    await this.writeJson(GUARD_DATA_PATH, data);
  }
};
