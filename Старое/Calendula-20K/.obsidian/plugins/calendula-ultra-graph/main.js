const path = require("path");
const { ItemView, Plugin } = require("obsidian");

const TECHNICAL_OBSIDIAN_SCRIPTS_ROOT =
  process.env.OBSIDIAN_TECHNICAL_OBSIDIAN_SCRIPTS_ROOT ||
  "C:/obsidian/Main/Technical/Scripts/Obsidian";

const TECHNICAL_RENDERING_SCRIPTS_ROOT =
  process.env.OBSIDIAN_TECHNICAL_RENDERING_SCRIPTS_ROOT ||
  "C:/obsidian/Main/Technical/Scripts/Rendering";

const {
  CanvasBackend,
  GraphStoreClient,
  buildCriticalRenderPlan,
} = require(path.resolve(TECHNICAL_RENDERING_SCRIPTS_ROOT, "graph-critical-frame.js"));
const {
  GraphStabilityController,
  IncidentLog,
} = require(path.resolve(TECHNICAL_OBSIDIAN_SCRIPTS_ROOT, "graph-stability.js"));
const {
  BudgetPolicy,
  FrameGovernor,
  IOGovernor,
  MemoryGovernor,
} = require(path.resolve(TECHNICAL_OBSIDIAN_SCRIPTS_ROOT, "graph-governors.js"));
const { buildQueryPlan } = require(path.resolve(TECHNICAL_OBSIDIAN_SCRIPTS_ROOT, "graph-query-engine.js"));

const VIEW_TYPE = "calendula-ultra-graph";
const BASE_FRAME_BUDGET_MS = 8;
const INTERACTIVE_FRAME_BUDGET_MS = 4;
const MAX_DEVICE_PIXEL_RATIO = 2;
const INTERACTION_COOLDOWN_MS = 180;
const HEALTH_UPDATE_INTERVAL_MS = 250;
const STEADY_NODE_BUDGET = 3000;
const STEADY_EDGE_BUDGET = 1000;

function requestFrame(callback) {
  const raf = window.requestAnimationFrame || globalThis.requestAnimationFrame;
  if (typeof raf === "function") return raf.call(window, callback);
  return window.setTimeout(callback, 16);
}

function cancelFrame(id) {
  const cancel = window.cancelAnimationFrame || globalThis.cancelAnimationFrame;
  if (typeof cancel === "function") {
    cancel.call(window, id);
    return;
  }
  window.clearTimeout?.(id);
}

function resolveGraphStoreRoot() {
  return path.resolve(__dirname, "..", "..", "graph-store");
}

class UltraGraphView extends ItemView {
  constructor(leaf) {
    super(leaf);
    this.canvas = null;
    this.ctx = null;
    this.backend = null;
    this.statusEl = null;
    this.healthEl = null;
    this.storeClient = null;
    this.stability = null;
    this.budgetPolicy = new BudgetPolicy({ nodeBudget: STEADY_NODE_BUDGET, edgeBudget: STEADY_EDGE_BUDGET, targetFrameMs: 16 });
    this.frameGovernor = new FrameGovernor();
    this.memoryGovernor = new MemoryGovernor();
    this.ioGovernor = new IOGovernor();
    this.snapshot = null;
    this.failureState = null;
    this.lastPlan = null;
    this.queryPlan = null;
    this.frameStats = null;
    this.frameId = null;
    this.localFrameId = 0;
    this.camera = { x: 0, y: 0, zoom: 1 };
    this.drag = null;
    this.drawn = 0;
    this.visited = 0;
    this.visibleNodes = 0;
    this.visibleEdges = 0;
    this.lastFrameAt = performance.now();
    this.fps = 0;
    this.frameBudgetMs = BASE_FRAME_BUDGET_MS;
    this.renderStride = 1;
    this.mode = "steady";
    this.degradationReason = "warming-up";
    this.lastInteractionAt = Number.NEGATIVE_INFINITY;
    this.lastHealthUpdateAt = 0;
    this.inputHandlers = null;
    this.resizeHandler = () => {
      this.resize();
      this.restartProgressivePaint();
    };
  }

  getViewType() {
    return VIEW_TYPE;
  }

  getDisplayText() {
    return "Calendula Ultra Graph";
  }

  getIcon() {
    return "network";
  }

  async onOpen() {
    this.containerEl.empty();
    this.containerEl.addClass("calendula-ultra-graph-view");
    const shell = this.containerEl.createDiv({ cls: "calendula-ultra-shell" });
    const toolbar = shell.createDiv({ cls: "calendula-ultra-toolbar" });
    toolbar.createEl("strong", { text: "Calendula Ultra Graph" });
    this.statusEl = toolbar.createDiv({ cls: "calendula-ultra-status", text: "loading graph store" });
    this.healthEl = shell.createDiv({ cls: "calendula-ultra-health", text: "Health: loading graph store" });
    this.canvas = shell.createEl("canvas", { cls: "calendula-ultra-canvas" });
    this.ctx = this.canvas.getContext("2d");
    this.backend = new CanvasBackend({ canvas: this.canvas, ctx: this.ctx });
    const graphStoreRoot = resolveGraphStoreRoot();
    this.stability = new GraphStabilityController({
      incidentLog: new IncidentLog({ filePath: path.join(graphStoreRoot, "graph.incidents.jsonl") }),
    });
    this.storeClient = new GraphStoreClient({ storeRoot: graphStoreRoot, includeEdges: true, edgeMode: "csr" });
    this.attachInput();
    this.resize();
    this.loadGraphSnapshot();
    this.start();
  }

  async onClose() {
    this.stop();
    this.detachInput();
    this.backend?.dispose();
    this.backend = null;
    this.storeClient = null;
    this.stability = null;
    this.snapshot = null;
    this.failureState = null;
    this.lastPlan = null;
    this.queryPlan = null;
    this.frameStats = null;
    this.ctx = null;
    this.canvas = null;
    this.statusEl = null;
    this.healthEl = null;
  }

  loadGraphSnapshot() {
    try {
      const loaded = this.storeClient.loadSnapshot({ includeEdges: true });
      if (!loaded.ok) {
        this.snapshot = null;
        this.failureState = loaded.failureState;
        this.stability?.recordStoreLoadResult(loaded);
        return;
      }
      this.snapshot = loaded.snapshot;
      this.failureState = null;
      this.queryPlan = buildQueryPlan({ snapshot: this.snapshot, id: "ultra-default-query", edgePolicy: "visible" });
      this.memoryGovernor.observeSnapshot(this.snapshot);
      this.ioGovernor.observeSnapshot(this.snapshot);
      this.stability?.recordStoreLoadResult(loaded);
      this.restartProgressivePaint();
    } catch (error) {
      this.snapshot = null;
      this.failureState = Object.freeze({
        contract: "FailureState/v9.0",
        severity: "blocking",
        code: "STORE_CLIENT_THROW",
        message: String(error?.message || error),
        activeDir: null,
        failures: Object.freeze([]),
        cause: String(error?.stack || error),
      });
      this.stability?.recordStoreLoadResult({ ok: false, failureState: this.failureState, failures: [] });
    }
  }

  resize() {
    if (!this.canvas) return;
    const rect = this.canvas.getBoundingClientRect();
    const width = Math.max(640, Math.floor(rect.width || 1280));
    const height = Math.max(420, Math.floor(rect.height || 720));
    const dpr = Math.max(1, Math.min(MAX_DEVICE_PIXEL_RATIO, window.devicePixelRatio || 1));
    this.canvas.width = Math.floor(width * dpr);
    this.canvas.height = Math.floor(height * dpr);
    this.canvas.style.width = `${width}px`;
    this.canvas.style.height = `${height}px`;
    this.ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    this.width = width;
    this.height = height;
  }

  attachInput() {
    if (this.inputHandlers || !this.canvas) return;
    const onWheel = (event) => {
      event.preventDefault();
      const delta = event.deltaY > 0 ? 0.9 : 1.1;
      this.camera.zoom = Math.max(0.1, Math.min(8, this.camera.zoom * delta));
      this.markInteraction();
    };
    const onPointerDown = (event) => {
      this.canvas.setPointerCapture?.(event.pointerId);
      this.drag = { x: event.clientX, y: event.clientY, cameraX: this.camera.x, cameraY: this.camera.y };
      this.markInteraction();
    };
    const onPointerMove = (event) => {
      if (!this.drag) return;
      this.camera.x = this.drag.cameraX - (event.clientX - this.drag.x) / this.camera.zoom;
      this.camera.y = this.drag.cameraY - (event.clientY - this.drag.y) / this.camera.zoom;
      this.markInteraction();
    };
    const onPointerUp = () => {
      this.drag = null;
      this.markInteraction();
    };

    this.inputHandlers = { onWheel, onPointerDown, onPointerMove, onPointerUp };
    this.canvas.addEventListener("wheel", onWheel, { passive: false });
    this.canvas.addEventListener("pointerdown", onPointerDown);
    this.canvas.addEventListener("pointermove", onPointerMove);
    this.canvas.addEventListener("pointerup", onPointerUp);
    this.canvas.addEventListener("pointercancel", onPointerUp);
    window.addEventListener("resize", this.resizeHandler);
  }

  detachInput() {
    if (!this.inputHandlers || !this.canvas) return;
    const { onWheel, onPointerDown, onPointerMove, onPointerUp } = this.inputHandlers;
    this.canvas.removeEventListener?.("wheel", onWheel);
    this.canvas.removeEventListener?.("pointerdown", onPointerDown);
    this.canvas.removeEventListener?.("pointermove", onPointerMove);
    this.canvas.removeEventListener?.("pointerup", onPointerUp);
    this.canvas.removeEventListener?.("pointercancel", onPointerUp);
    window.removeEventListener?.("resize", this.resizeHandler);
    this.inputHandlers = null;
  }

  markInteraction() {
    this.lastInteractionAt = performance.now();
    this.restartProgressivePaint();
  }

  restartProgressivePaint() {
    this.drawn = 0;
    this.visited = 0;
    this.visibleNodes = 0;
    this.visibleEdges = 0;
  }

  start() {
    if (this.frameId) return;
    const tick = () => {
      this.frameId = requestFrame(tick);
      this.renderFrame();
    };
    this.frameId = requestFrame(tick);
  }

  stop() {
    if (this.frameId) {
      cancelFrame(this.frameId);
      this.frameId = null;
    }
  }

  makeFrameBudgets() {
    const resolved = this.budgetPolicy.resolve({
      mode: this.mode,
      framePressure: this.frameGovernor.getSnapshot().pressure,
      memoryPressure: this.memoryGovernor.getSnapshot().pressure,
      ioPressure: this.ioGovernor.getSnapshot().pressure,
      inputBurst: this.mode === "interactive",
    });
    return { ...resolved, frameBudgetMs: this.frameBudgetMs };
  }

  renderFrame() {
    if (!this.ctx) return;
    const now = performance.now();
    const delta = Math.max(1, now - this.lastFrameAt);
    this.lastFrameAt = now;
    this.fps = this.fps ? this.fps * 0.9 + (1000 / delta) * 0.1 : 1000 / delta;
    this.updateFrameBudget(now);

    this.ctx.clearRect(0, 0, this.width, this.height);
    this.drawBackground();

    const stabilitySnapshot = this.stability?.getSnapshot();
    if (!this.snapshot || this.failureState || stabilitySnapshot?.canRender === false) {
      this.drawn = 0;
      this.visited = 0;
      this.visibleNodes = 0;
      this.visibleEdges = 0;
      this.updateStatus();
      this.updateHealthPanel(now);
      return;
    }

    this.localFrameId += 1;
    const plan = buildCriticalRenderPlan({
      snapshot: this.snapshot,
      camera: {
        x: this.camera.x,
        y: this.camera.y,
        width: this.width,
        height: this.height,
        zoom: this.camera.zoom,
      },
      budgets: this.makeFrameBudgets(),
      frameId: this.localFrameId,
      profileId: "calendula-ultra-v9",
      mode: this.mode,
      reason: this.degradationReason,
      queryPlan: this.queryPlan,
    });
    this.lastPlan = plan;
    this.frameStats = this.backend.draw(plan);
    this.frameGovernor.recordFrameStats(this.frameStats);
    this.stability?.recordFrameStats(this.frameStats);
    if (this.frameStats.failureState) {
      this.failureState = this.frameStats.failureState;
    }

    this.drawn = this.frameStats.drawn.nodes;
    this.visited = this.snapshot.nodeCount;
    this.visibleNodes = plan.nodes.length;
    this.visibleEdges = plan.edges.length;
    this.updateStatus();
    this.updateHealthPanel(now);
  }

  updateFrameBudget(now) {
    const interactive = now - this.lastInteractionAt < INTERACTION_COOLDOWN_MS;
    if (interactive) {
      this.mode = "interactive";
      this.degradationReason = "input-burst";
      this.frameBudgetMs = INTERACTIVE_FRAME_BUDGET_MS;
      this.renderStride = this.camera.zoom < 0.6 ? 3 : 2;
      return;
    }
    if (this.fps && this.fps < 24) {
      this.mode = "emergency";
      this.degradationReason = "fps-below-24";
      this.frameBudgetMs = Math.max(3, this.frameBudgetMs * 0.7);
      this.renderStride = this.camera.zoom < 0.6 ? 6 : 4;
      return;
    }
    if (this.fps && this.fps < 42) {
      this.mode = "degraded";
      this.degradationReason = "fps-below-42";
      this.frameBudgetMs = Math.max(3, this.frameBudgetMs * 0.84);
      this.renderStride = this.camera.zoom < 0.6 ? 4 : 2;
      return;
    }
    this.mode = "steady";
    this.degradationReason = "healthy";
    this.renderStride = this.camera.zoom < 0.32 ? 2 : 1;
    if (this.fps > 55) {
      this.frameBudgetMs = Math.min(BASE_FRAME_BUDGET_MS, this.frameBudgetMs + 0.35);
    }
  }

  getHealthSnapshot() {
    const stats = this.frameStats;
    return Object.freeze({
      nodeCount: this.snapshot?.nodeCount || 0,
      edgeCount: this.snapshot?.edgeCount || 0,
      visibleNodes: this.visibleNodes,
      visibleEdges: this.visibleEdges,
      drawn: this.drawn,
      visited: this.visited,
      fps: Number(this.fps.toFixed(1)),
      mode: this.mode,
      reason: this.failureState?.code || this.degradationReason,
      frameBudgetMs: Number(this.frameBudgetMs.toFixed(2)),
      renderStride: this.renderStride,
      zoom: Number(this.camera.zoom.toFixed(3)),
      devicePixelRatio: Math.max(1, Math.min(MAX_DEVICE_PIXEL_RATIO, window.devicePixelRatio || 1)),
      timingsMs: Object.freeze({
        renderPlan: Number(stats?.timingsMs?.renderPlan || 0),
        visibleSet: Number(stats?.timingsMs?.visibleSet || 0),
        edgeBatch: Number(stats?.timingsMs?.edgeBatch || 0),
        draw: Number(stats?.timingsMs?.draw || 0),
      }),
      failure: this.failureState
        ? Object.freeze({
            severity: this.failureState.severity,
            code: this.failureState.code,
            message: this.failureState.message,
          })
        : null,
      stability: this.stability?.getSnapshot() || null,
      governors: Object.freeze({
        frame: this.frameGovernor.getSnapshot(),
        memory: this.memoryGovernor.getSnapshot(),
        io: this.ioGovernor.getSnapshot(),
      }),
    });
  }

  drawBackground() {
    const gradient = this.ctx.createLinearGradient(0, 0, this.width, this.height);
    gradient.addColorStop(0, "rgba(13, 23, 35, 0.98)");
    gradient.addColorStop(1, "rgba(32, 42, 45, 0.98)");
    this.ctx.fillStyle = gradient;
    this.ctx.fillRect(0, 0, this.width, this.height);
  }

  updateStatus() {
    if (!this.statusEl) return;
    if (this.failureState) {
      this.statusEl.setText(`store failure | ${this.failureState.severity} | ${this.failureState.code}`);
      return;
    }
    const nodeCount = this.snapshot?.nodeCount || 0;
    const edgeCount = this.snapshot?.edgeCount || 0;
    const planMs = Number(this.frameStats?.timingsMs?.renderPlan || 0).toFixed(2);
    const drawMs = Number(this.frameStats?.timingsMs?.draw || 0).toFixed(2);
    this.statusEl.setText(
      `real ${nodeCount.toLocaleString()} nodes / ${edgeCount.toLocaleString()} edges | visible ${this.visibleNodes.toLocaleString()} nodes, ${this.visibleEdges.toLocaleString()} edges | zoom ${this.camera.zoom.toFixed(2)} | ${this.fps.toFixed(0)} fps | ${this.mode} | plan ${planMs}ms | draw ${drawMs}ms`,
    );
  }

  updateHealthPanel(now) {
    if (!this.healthEl || now - this.lastHealthUpdateAt < HEALTH_UPDATE_INTERVAL_MS) return;
    this.lastHealthUpdateAt = now;
    const health = this.getHealthSnapshot();
    const failure = health.failure ? ` | failure ${health.failure.severity}/${health.failure.code}` : "";
    const stability = health.stability ? ` | state ${health.stability.state}` : "";
    this.healthEl.setText(
      `Health: ${health.mode} (${health.reason}) | budget ${health.frameBudgetMs}ms | stride ${health.renderStride} | visible ${health.visibleNodes.toLocaleString()}/${health.nodeCount.toLocaleString()} | edges ${health.visibleEdges.toLocaleString()} | plan ${health.timingsMs.renderPlan}ms | draw ${health.timingsMs.draw}ms | DPR ${health.devicePixelRatio}${failure}${stability}`,
    );
  }
}

module.exports = class CalendulaUltraGraphPlugin extends Plugin {
  async onload() {
    this.registerView(VIEW_TYPE, (leaf) => new UltraGraphView(leaf));
    this.addCommand({
      id: "open-calendula-ultra-graph",
      name: "Open Calendula Ultra Graph",
      callback: () => {
        void this.openView();
      },
    });
  }

  async onunload() {
    this.app.workspace.detachLeavesOfType?.(VIEW_TYPE);
  }

  async openView() {
    const leaf = this.app.workspace.getLeaf(false);
    await leaf.setViewState({ type: VIEW_TYPE, active: true });
    this.app.workspace.revealLeaf?.(leaf);
  }
};
