module.exports = function createBuiltInGraphPlugin(obsidian) {
  const {
    ItemView,
    Plugin,
    PluginSettingTab,
    Setting,
    setIcon,
  } = obsidian;
  const fs = require("fs");
  const path = require("path");
  const zlib = require("zlib");
  const fsp = fs.promises;

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
  const RECOVERY_DIR_NAME = "live-graph-recovery";
  const RECOVERY_FILE_NAME = "active-batch.json";

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

  function getVaultBasePath(plugin) {
    const adapter = plugin?.app?.vault?.adapter;
    if (!adapter || typeof adapter.basePath !== "string" || !adapter.basePath) {
      return null;
    }
    return adapter.basePath;
  }

  function getRecoveryDir(plugin) {
    const basePath = getVaultBasePath(plugin);
    if (!basePath) return null;
    return path.join(basePath, ".obsidian", "plugins", "live-graph", RECOVERY_DIR_NAME);
  }

  function getRecoveryFilePath(plugin, fileName = RECOVERY_FILE_NAME) {
    const dir = getRecoveryDir(plugin);
    return dir ? path.join(dir, fileName) : null;
  }

  function getRecoveryFileRef(fileName = RECOVERY_FILE_NAME) {
    return `${RECOVERY_DIR_NAME}/${fileName}`;
  }

  function sanitizeStateEntry(entry) {
    if (!entry) return null;
    return {
      id: entry.id || entry.cycleId || null,
      cycleId: entry.cycleId || entry.id || null,
      createdAt: entry.createdAt || null,
      restoredAt: entry.restoredAt || null,
      status: entry.status || "detached",
      fileRef: entry.fileRef || null,
      fileCount: Array.isArray(entry.files) ? entry.files.length : Number(entry.fileCount) || 0,
    };
  }

  async function ensureRecoveryDir(plugin) {
    const recoveryDir = getRecoveryDir(plugin);
    if (!recoveryDir) {
      throw new Error("Unable to resolve live-graph recovery directory.");
    }
    await fsp.mkdir(recoveryDir, { recursive: true });
    return recoveryDir;
  }

  async function writeJsonFile(filePath, value) {
    await fsp.writeFile(filePath, `${JSON.stringify(value, null, 2)}\n`, "utf8");
  }

  async function readJsonFile(filePath) {
    const raw = await fsp.readFile(filePath, "utf8");
    return JSON.parse(raw);
  }

  async function writeRecoveryEntry(plugin, entry) {
    if (!entry) return null;
    const recoveryDir = await ensureRecoveryDir(plugin);
    const entryId = entry.id || entry.cycleId;
    if (!entryId) {
      throw new Error("Cannot persist live-graph entry without an id.");
    }
    const filePath = path.join(recoveryDir, `${entryId}.json`);
    await writeJsonFile(filePath, packEntry(entry));
    return {
      id: entryId,
      fileRef: getRecoveryFileRef(`${entryId}.json`),
    };
  }

  async function readRecoveryEntry(plugin, fileRef) {
    if (!fileRef) return null;
    const basePath = getVaultBasePath(plugin);
    if (!basePath) return null;
    const filePath = path.join(basePath, ".obsidian", "plugins", "live-graph", fileRef);
    if (!fs.existsSync(filePath)) {
      return null;
    }
    return unpackEntry(await readJsonFile(filePath));
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
      .life-mini-mode-row {
        display: flex;
        flex-wrap: wrap;
        gap: 6px;
      }
      .life-mini-mode-chip {
        border: 1px solid var(--background-modifier-border);
        border-radius: 999px;
        padding: 5px 10px;
        background: var(--background-primary);
        color: var(--text-normal);
        cursor: pointer;
        font-size: 0.78em;
      }
      .life-mini-mode-chip.is-active {
        border-color: var(--interactive-accent);
        background: rgba(120, 170, 255, 0.16);
      }
      .life-graph-stage {
        position: relative;
        min-height: 360px;
        overflow: hidden;
        border: 1px solid var(--background-modifier-border);
        border-radius: 16px;
        background:
          radial-gradient(circle at 20% 20%, rgba(120, 170, 255, 0.18), transparent 30%),
          radial-gradient(circle at 80% 30%, rgba(255, 165, 80, 0.14), transparent 32%),
          linear-gradient(135deg, rgba(255, 255, 255, 0.04), rgba(0, 0, 0, 0.08));
      }
      .life-graph-canvas {
        display: block;
        width: 100%;
        min-height: 360px;
      }
      .life-graph-caption {
        position: absolute;
        left: 12px;
        bottom: 10px;
        padding: 4px 8px;
        border-radius: 999px;
        background: rgba(0, 0, 0, 0.22);
        color: var(--text-muted);
        font-size: 0.72em;
        pointer-events: none;
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

  function requestFrame(callback) {
    if (typeof window !== "undefined" && typeof window.requestAnimationFrame === "function") {
      return window.requestAnimationFrame(callback);
    }
    if (typeof setTimeout === "function") {
      return setTimeout(() => callback(Date.now()), 16);
    }
    callback(Date.now());
    return 0;
  }

  function cancelFrame(frameId) {
    if (!frameId) return;
    if (typeof window !== "undefined" && typeof window.cancelAnimationFrame === "function") {
      window.cancelAnimationFrame(frameId);
      return;
    }
    if (typeof clearTimeout === "function") {
      clearTimeout(frameId);
    }
  }

  function pickGraphProfile(nodeCount, edgeCount) {
    if (nodeCount >= 10000 || edgeCount >= 20000) {
      return {
        mode: "ultra",
        chunked: true,
        chunkSize: 360,
        labelLimit: 0,
        nodeRadius: 1.6,
        edgeAlpha: 0.16,
      };
    }
    if (nodeCount >= 4000 || edgeCount >= 8000) {
      return {
        mode: "heavy",
        chunked: true,
        chunkSize: 520,
        labelLimit: 80,
        nodeRadius: 2,
        edgeAlpha: 0.2,
      };
    }
    return {
      mode: "standard",
      chunked: false,
      chunkSize: Infinity,
      labelLimit: 260,
      nodeRadius: 2.8,
      edgeAlpha: 0.32,
    };
  }

  function normalizeLinkTarget(target) {
    return String(target || "")
      .trim()
      .replace(/\\/g, "/")
      .replace(/\.md$/i, "");
  }

  function noteBaseName(filePath) {
    return path.basename(String(filePath || "").replace(/\\/g, "/"), ".md");
  }

  class LifePanelView extends BaseItemView {
    constructor(leaf, plugin) {
      super(leaf);
      this.plugin = plugin;
      this.statusEl = null;
      this.rootEl = null;
      this.graphStageEl = null;
      this.graphCanvas = null;
      this.graphCaptionEl = null;
      this.lastStatusText = "";
      this.markdownFileCache = null;
      this.nodeIndexCache = null;
      this.rafId = null;
      this.paintFrameId = null;
      this.currentProfile = null;
      this.lastPaintSummary = null;
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
      this.renderGraph(true);
      this.startRenderLoop();
    }

    async onClose() {
      this.stopRenderLoop();
      this.plugin.panelViews.delete(this);
    }

    render() {
      if (!this.rootEl) return;
      clearElement(this.rootEl);
      injectStyles();
      this.plugin.renderSettingsBlock(this.rootEl, this);
      this.graphStageEl = this.rootEl.createDiv({ cls: "life-graph-stage" });
      this.graphCanvas = this.graphStageEl.createEl("canvas", { cls: "life-graph-canvas" });
      this.graphCaptionEl = this.graphStageEl.createDiv({
        cls: "life-graph-caption",
        text: "Graph renderer warming up",
      });
    }

    refreshStatus() {
      if (!this.statusEl) return;
      const detached = this.plugin.safetyBuffer.filter((entry) => entry.status === "detached").length;
      const text = `Buffer: ${this.plugin.safetyBuffer.length} | Detached: ${detached} | ${this.plugin.busy ? "busy" : "idle"}`;
      if (text === this.lastStatusText) return;
      this.lastStatusText = text;
      this.statusEl.setText(text);
    }

    startRenderLoop() {
      if (this.rafId) return;
      const tick = () => {
        this.rafId = null;
        this.renderGraph(false);
        this.rafId = requestFrame(tick);
      };
      this.rafId = requestFrame(tick);
    }

    stopRenderLoop() {
      cancelFrame(this.rafId);
      cancelFrame(this.paintFrameId);
      this.rafId = null;
      this.paintFrameId = null;
    }

    getMarkdownFilesCached() {
      if (!this.markdownFileCache) {
        const files =
          typeof this.plugin.app?.vault?.getMarkdownFiles === "function"
            ? this.plugin.app.vault.getMarkdownFiles()
            : [];
        this.markdownFileCache = files.filter((file) => file && !String(file.path || "").startsWith("."));
        this.nodeIndexCache = null;
      }
      return this.markdownFileCache;
    }

    getNodeIndexes(files) {
      if (this.nodeIndexCache && this.nodeIndexCache.files === files) {
        return this.nodeIndexCache;
      }

      const byPath = new Map();
      const byBase = new Map();
      const nodes = files.map((file, index) => {
        const id = String(file.path || file.name || `note-${index}`);
        const cleanPath = normalizeLinkTarget(id);
        const base = file.basename || noteBaseName(id);
        const node = {
          id,
          cleanPath,
          base,
          index,
          x: 0,
          y: 0,
        };
        byPath.set(cleanPath, node);
        byPath.set(`${cleanPath}.md`, node);
        if (!byBase.has(base)) {
          byBase.set(base, node);
        }
        return node;
      });

      this.nodeIndexCache = { files, nodes, byPath, byBase };
      return this.nodeIndexCache;
    }

    buildGraph(skipResolvedLinks = false) {
      const files = this.getMarkdownFilesCached();
      const index = this.getNodeIndexes(files);
      const edges = [];
      const resolvedLinks = skipResolvedLinks
        ? {}
        : this.plugin.app?.metadataCache?.resolvedLinks || {};

      for (const [sourcePath, targets] of Object.entries(resolvedLinks || {})) {
        const source =
          index.byPath.get(normalizeLinkTarget(sourcePath)) ||
          index.byPath.get(String(sourcePath || ""));
        if (!source || !targets) continue;

        for (const targetPath of Object.keys(targets)) {
          const normalized = normalizeLinkTarget(targetPath);
          const target =
            index.byPath.get(normalized) ||
            index.byPath.get(`${normalized}.md`) ||
            index.byBase.get(noteBaseName(normalized));
          if (!target || target === source) continue;
          edges.push({ source, target });
        }
      }

      return {
        nodes: index.nodes,
        edges,
      };
    }

    layoutGraph(nodes, width, height) {
      const count = Math.max(1, nodes.length);
      const centerX = width / 2;
      const centerY = height / 2;
      const maxRadius = Math.max(80, Math.min(width, height) * 0.43);
      const goldenAngle = Math.PI * (3 - Math.sqrt(5));

      for (const node of nodes) {
        const radius = maxRadius * Math.sqrt((node.index + 0.5) / count);
        const angle = node.index * goldenAngle;
        node.x = centerX + Math.cos(angle) * radius;
        node.y = centerY + Math.sin(angle) * radius;
      }
    }

    getCanvasContext() {
      if (!this.graphCanvas && this.rootEl) {
        this.render();
      }
      const canvas = this.graphCanvas;
      if (!canvas || typeof canvas.getContext !== "function") {
        return { canvas: null, ctx: null, width: 0, height: 0 };
      }

      const rect =
        typeof canvas.getBoundingClientRect === "function"
          ? canvas.getBoundingClientRect()
          : { width: 1200, height: 720 };
      const width = Math.max(320, Math.floor(rect.width || 1200));
      const height = Math.max(260, Math.floor(rect.height || 720));
      const pixelRatio =
        typeof window !== "undefined"
          ? Math.max(1, Math.min(2, Number(window.devicePixelRatio) || 1))
          : 1;
      canvas.width = Math.floor(width * pixelRatio);
      canvas.height = Math.floor(height * pixelRatio);
      canvas.style.width = `${width}px`;
      canvas.style.height = `${height}px`;

      const ctx = canvas.getContext("2d");
      if (ctx && typeof ctx.setTransform === "function") {
        ctx.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);
      }
      return { canvas, ctx, width, height };
    }

    drawFrame(ctx, graph, profile, frameIndex, totalFrames) {
      if (!ctx) return;
      const { nodes, edges } = graph;
      const totalItems = nodes.length + edges.length;
      const chunkSize = profile.chunked
        ? Math.max(1, Math.ceil(totalItems / totalFrames))
        : totalItems;
      const start = frameIndex * chunkSize;
      const end = Math.min(totalItems, start + chunkSize);

      if (frameIndex === 0) {
        if (typeof ctx.clearRect === "function") {
          ctx.clearRect(0, 0, 100000, 100000);
        }
        ctx.lineCap = "round";
      }

      for (let itemIndex = start; itemIndex < end; itemIndex += 1) {
        if (itemIndex < edges.length) {
          const edge = edges[itemIndex];
          if (typeof ctx.beginPath === "function") ctx.beginPath();
          ctx.strokeStyle = `rgba(150, 170, 205, ${profile.edgeAlpha})`;
          ctx.lineWidth = 0.8;
          if (typeof ctx.moveTo === "function") ctx.moveTo(edge.source.x, edge.source.y);
          if (typeof ctx.lineTo === "function") ctx.lineTo(edge.target.x, edge.target.y);
          if (typeof ctx.stroke === "function") ctx.stroke();
          continue;
        }

        const node = nodes[itemIndex - edges.length];
        if (!node) continue;
        if (typeof ctx.beginPath === "function") ctx.beginPath();
        ctx.fillStyle = node.id.includes("Calendula/") ? "rgba(80, 168, 255, 0.72)" : "rgba(255, 166, 72, 0.78)";
        if (typeof ctx.arc === "function") {
          ctx.arc(node.x, node.y, profile.nodeRadius, 0, Math.PI * 2);
        }
        if (typeof ctx.fill === "function") ctx.fill();
      }

      if (!profile.labelLimit || frameIndex !== totalFrames - 1) return;
      ctx.fillStyle = "rgba(220, 226, 240, 0.72)";
      ctx.textBaseline = "middle";
      for (const node of nodes.slice(0, profile.labelLimit)) {
        if (typeof ctx.fillText === "function") {
          ctx.fillText(node.base, node.x + 4, node.y);
        }
      }
    }

    paintGraph(graph, profile, width, height) {
      const { ctx } = this.getCanvasContext();
      this.layoutGraph(graph.nodes, width, height);
      cancelFrame(this.paintFrameId);
      this.paintFrameId = null;

      const totalItems = graph.nodes.length + graph.edges.length;
      const frames = profile.chunked
        ? Math.max(20, Math.ceil(totalItems / profile.chunkSize))
        : 1;
      const labelsSkipped = Math.max(0, graph.nodes.length - profile.labelLimit);
      this.lastPaintSummary = {
        nodes: graph.nodes.length,
        edges: graph.edges.length,
        frames,
        chunked: profile.chunked,
        labelsSkipped,
      };

      if (this.graphCaptionEl && typeof this.graphCaptionEl.setText === "function") {
        this.graphCaptionEl.setText(
          `${profile.mode}: ${graph.nodes.length} nodes, ${graph.edges.length} edges, ${frames} frame(s)`,
        );
      }

      let frameIndex = 0;
      const paintNext = () => {
        this.drawFrame(ctx, graph, profile, frameIndex, frames);
        frameIndex += 1;
        if (frameIndex < frames) {
          this.paintFrameId = requestFrame(paintNext);
        } else {
          this.paintFrameId = null;
        }
      };

      if (profile.chunked) {
        this.paintFrameId = requestFrame(paintNext);
      } else {
        paintNext();
      }
    }

    renderGraph(skipResolvedLinks = false) {
      const graph = this.buildGraph(skipResolvedLinks);
      const { width, height } = this.getCanvasContext();
      const profile = pickGraphProfile(graph.nodes.length, graph.edges.length);
      this.currentProfile = profile;
      this.paintGraph(graph, profile, width || 1200, height || 720);
      return graph;
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
        this.activeBatch = null;
        this.activeBatchMeta = null;
        this.safetyBuffer = [];
        this.persistedDetached = [];

        if (Array.isArray(data.persistedDetached)) {
          this.persistedDetached = data.persistedDetached
            .map((entry) => sanitizeStateEntry(entry))
            .filter(Boolean);
          this.safetyBuffer = this.persistedDetached.map((entry) => ({ ...entry }));
          this.activeBatchMeta = this.getLastDetachedEntry();
        } else if (data.activeBatchRef) {
          this.activeBatchMeta = sanitizeStateEntry(data.activeBatchRef);
        } else if (data.activeBatch) {
          this.activeBatch = unpackEntry(data.activeBatch);
          this.safetyBuffer = [this.activeBatch];
          this.activeBatchMeta = sanitizeStateEntry(this.activeBatch);
        }
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
          id: "open-live-graph",
          name: "Open native graph",
          callback: () => {
            void this.openLiveGraph();
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
      const detachedEntries = this.safetyBuffer.filter((entry) => entry.status === "detached");
      const persistedDetached = [];

      for (const entry of detachedEntries) {
        const hasInlineFiles = Array.isArray(entry.files) && entry.files.length > 0;
        if (hasInlineFiles) {
          const persisted = await writeRecoveryEntry(this, entry);
          entry.fileRef = persisted.fileRef;
        } else if (!entry.fileRef && entry.id) {
          entry.fileRef = getRecoveryFileRef(`${entry.id}.json`);
        }

        persistedDetached.push(sanitizeStateEntry(entry));
      }

      this.persistedDetached = persistedDetached;
      this.activeBatchMeta = this.getLastDetachedEntry() ? sanitizeStateEntry(this.getLastDetachedEntry()) : null;

      await this.saveData({
        settings: this.settings,
        activeBatchRef: this.activeBatchMeta,
        persistedDetached,
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

    async openLiveGraph() {
      const workspace = this.app?.workspace;
      if (!workspace) return;
      const leaf =
        (typeof workspace.getLeavesOfType === "function" ? workspace.getLeavesOfType("graph")[0] : null) ||
        (typeof workspace.getLeaf === "function" ? workspace.getLeaf(false) : null);
      if (!leaf || typeof leaf.setViewState !== "function") return;

      await leaf.setViewState({
        type: "graph",
        active: true,
        state: {},
      });

      if (typeof workspace.revealLeaf === "function") {
        workspace.revealLeaf(leaf);
      }
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

      card.createDiv({
        cls: "life-mini-note",
        text: `\u0420\u0435\u0436\u0438\u043c: ${pickModeLabel(this.settings.cycleMode)}`,
      });

      const modeControl = card.createDiv({ cls: "life-mini-control" });
      modeControl.createEl("div", { text: "\u0414\u0432\u0438\u0436\u0435\u043d\u0438\u0435", cls: "life-mini-label" });
      const modeRow = modeControl.createDiv({ cls: "life-mini-mode-row" });
      const modeDefs = [
        { mode: "prune-heavy", label: "\u0425\u0443\u0431\u044b" },
        { mode: "equalize", label: "\u0420\u0430\u0432\u043d\u043e" },
        { mode: "cascade-one", label: "\u0414\u043e 1" },
        { mode: "regrow", label: "\u041e\u0431\u0440\u0430\u0442\u043d\u043e" },
      ];
      for (const item of modeDefs) {
        const chip = modeRow.createEl("button", {
          text: item.label,
          cls: `life-mini-mode-chip${this.settings.cycleMode === item.mode ? " is-active" : ""}`,
        });
        chip.addEventListener("click", async () => {
          await this.setCycleMode(item.mode);
          this.refreshPanelViews();
        });
      }

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
      this.activeBatchMeta = sanitizeStateEntry(entry);
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
        if (!Array.isArray(entry.files) || !entry.files.length) {
          const loaded = await readRecoveryEntry(this, entry.fileRef || (entry.id ? getRecoveryFileRef(`${entry.id}.json`) : null));
          if (!loaded) {
            continue;
          }
          Object.assign(entry, loaded);
          entry.fileRef = entry.fileRef || getRecoveryFileRef(`${entry.id}.json`);
        }

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
