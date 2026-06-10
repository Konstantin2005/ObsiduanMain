const { ItemView, Plugin } = require("obsidian");

const VIEW_TYPE = "calendula-ultra-graph";
const NODE_COUNT = 20000;
const BASE_FRAME_BUDGET_MS = 8;
const INTERACTIVE_FRAME_BUDGET_MS = 4;
const MAX_DEVICE_PIXEL_RATIO = 2;
const INTERACTION_COOLDOWN_MS = 180;
const HEALTH_UPDATE_INTERVAL_MS = 250;

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

function makeSyntheticNodes(count, width, height) {
  const nodes = new Float32Array(count * 2);
  const goldenAngle = Math.PI * (3 - Math.sqrt(5));
  const maxRadius = Math.max(160, Math.min(width, height) * 0.46);
  for (let i = 0; i < count; i += 1) {
    const radius = maxRadius * Math.sqrt((i + 0.5) / count);
    const angle = i * goldenAngle;
    nodes[i * 2] = Math.cos(angle) * radius;
    nodes[i * 2 + 1] = Math.sin(angle) * radius;
  }
  return nodes;
}

class UltraGraphView extends ItemView {
  constructor(leaf) {
    super(leaf);
    this.canvas = null;
    this.ctx = null;
    this.statusEl = null;
    this.healthEl = null;
    this.nodes = null;
    this.frameId = null;
    this.camera = { x: 0, y: 0, zoom: 1 };
    this.drag = null;
    this.cursor = 0;
    this.drawn = 0;
    this.visited = 0;
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
    this.statusEl = toolbar.createDiv({ cls: "calendula-ultra-status", text: "warming up" });
    this.healthEl = shell.createDiv({ cls: "calendula-ultra-health", text: "Health: warming up" });
    this.canvas = shell.createEl("canvas", { cls: "calendula-ultra-canvas" });
    this.ctx = this.canvas.getContext("2d");
    this.attachInput();
    this.resize();
    this.nodes = makeSyntheticNodes(NODE_COUNT, this.canvas.width, this.canvas.height);
    this.start();
  }

  async onClose() {
    this.stop();
    this.detachInput();
    this.nodes = null;
    this.ctx = null;
    this.canvas = null;
    this.statusEl = null;
    this.healthEl = null;
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
    this.cursor = 0;
    this.drawn = 0;
    this.visited = 0;
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

  renderFrame() {
    if (!this.ctx || !this.nodes) return;
    const now = performance.now();
    const delta = Math.max(1, now - this.lastFrameAt);
    this.lastFrameAt = now;
    this.fps = this.fps ? this.fps * 0.9 + (1000 / delta) * 0.1 : 1000 / delta;
    this.updateFrameBudget(now);

    if (this.cursor === 0) {
      this.drawn = 0;
      this.visited = 0;
      this.ctx.clearRect(0, 0, this.width, this.height);
      this.drawBackground();
    }

    const start = performance.now();
    const centerX = this.width / 2;
    const centerY = this.height / 2;
    const zoom = this.camera.zoom;
    const radius = zoom < 0.45 ? 1.1 : 1.8;
    this.ctx.fillStyle = zoom < 0.45 ? "rgba(96, 180, 255, 0.52)" : "rgba(96, 180, 255, 0.74)";
    this.ctx.beginPath();

    const stride = this.renderStride;
    while (this.cursor < NODE_COUNT && performance.now() - start < this.frameBudgetMs) {
      const x = (this.nodes[this.cursor * 2] - this.camera.x) * zoom + centerX;
      const y = (this.nodes[this.cursor * 2 + 1] - this.camera.y) * zoom + centerY;
      this.cursor += stride;
      this.visited += stride;
      if (x < -8 || x > this.width + 8 || y < -8 || y > this.height + 8) continue;
      this.ctx.rect(x - radius, y - radius, radius * 2, radius * 2);
      this.drawn += 1;
    }
    this.ctx.fill();

    if (this.cursor >= NODE_COUNT) {
      this.cursor = 0;
    }
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
    return Object.freeze({
      nodeCount: NODE_COUNT,
      drawn: this.drawn,
      visited: Math.min(NODE_COUNT, this.visited),
      cursor: this.cursor,
      fps: Number(this.fps.toFixed(1)),
      mode: this.mode,
      reason: this.degradationReason,
      frameBudgetMs: Number(this.frameBudgetMs.toFixed(2)),
      renderStride: this.renderStride,
      zoom: Number(this.camera.zoom.toFixed(3)),
      devicePixelRatio: Math.max(1, Math.min(MAX_DEVICE_PIXEL_RATIO, window.devicePixelRatio || 1)),
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
    this.statusEl.setText(
      `synthetic ${NODE_COUNT.toLocaleString()} nodes | drawn ${this.drawn.toLocaleString()} | zoom ${this.camera.zoom.toFixed(2)} | ${this.fps.toFixed(0)} fps | ${this.mode} | budget ${this.frameBudgetMs.toFixed(1)}ms | stride ${this.renderStride}`,
    );
  }

  updateHealthPanel(now) {
    if (!this.healthEl || now - this.lastHealthUpdateAt < HEALTH_UPDATE_INTERVAL_MS) return;
    this.lastHealthUpdateAt = now;
    const health = this.getHealthSnapshot();
    this.healthEl.setText(
      `Health: ${health.mode} (${health.reason}) | budget ${health.frameBudgetMs}ms | stride ${health.renderStride} | visited ${health.visited.toLocaleString()}/${health.nodeCount.toLocaleString()} | DPR ${health.devicePixelRatio}`,
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
