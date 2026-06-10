const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const SCHEMA_VERSION = 6;
const STORE_VERSION = "2026.06.10.1";
const DEFAULT_VAULT = path.resolve(__dirname, "..", "..", "Calendula-20K");
const LINK_RE = /\[\[([^\]|#]+)(?:#[^\]|]*)?(?:\|[^\]]*)?\]\]/g;

function parseArgs(argv) {
  const args = {
    vault: DEFAULT_VAULT,
    out: null,
    keepNext: false,
  };
  for (let i = 2; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--vault") args.vault = path.resolve(argv[++i]);
    else if (arg === "--out") args.out = path.resolve(argv[++i]);
    else if (arg === "--keep-next") args.keepNext = true;
    else throw new Error(`Unknown argument: ${arg}`);
  }
  args.out = args.out || path.join(args.vault, ".obsidian", "graph-store");
  return args;
}

function assertInside(parent, child) {
  const relative = path.relative(parent, child);
  if (relative.startsWith("..") || path.isAbsolute(relative)) {
    throw new Error(`Refusing to write outside graph store: ${child}`);
  }
}

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function rmGeneratedDir(root, target) {
  assertInside(root, target);
  fs.rmSync(target, { recursive: true, force: true });
}

function vaultPath(root, file) {
  return path.relative(root, file).replace(/\\/g, "/");
}

function walkMarkdown(root) {
  const out = [];
  function walk(dir) {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      const relative = vaultPath(root, full);
      if (relative.startsWith(".obsidian/")) continue;
      if (entry.isDirectory()) walk(full);
      else if (entry.isFile() && entry.name.endsWith(".md")) out.push(full);
    }
  }
  walk(root);
  return out.sort((a, b) => vaultPath(root, a).localeCompare(vaultPath(root, b), "en"));
}

function normalizeTarget(target) {
  return String(target || "")
    .trim()
    .replace(/\\/g, "/")
    .replace(/\.md$/i, "");
}

function basename(filePath) {
  return path.basename(String(filePath || "").replace(/\\/g, "/"), ".md");
}

function classifyNode(filePath, text) {
  const typeMatch = text.match(/^type:\s*([A-Za-z0-9_-]+)\s*$/m);
  if (typeMatch?.[1] === "diary") return 1;
  if (typeMatch?.[1] === "person") return 2;
  if (filePath.startsWith("Calendula/")) return 1;
  if (filePath.startsWith("Соц Капитал/")) return 2;
  if (filePath.startsWith("System/GraphClusters/")) return 3;
  return 0;
}

function clusterName(filePath) {
  if (filePath.startsWith("Calendula/")) {
    const parts = filePath.split("/");
    return parts.length >= 3 ? `Diary-${parts[1]}` : "Diary";
  }
  if (filePath.startsWith("Соц Капитал/")) {
    const parts = filePath.split("/");
    return parts.length >= 2 ? `People-${parts[1]}` : "People";
  }
  if (filePath.startsWith("System/GraphClusters/")) return "GraphClusters";
  return "Other";
}

function stringId(table, value) {
  if (!table.map.has(value)) {
    table.map.set(value, table.values.length);
    table.values.push(value);
  }
  return table.map.get(value);
}

function writeJson(filePath, value) {
  fs.writeFileSync(filePath, `${JSON.stringify(value, null, 2)}\n`, "utf8");
}

function writeTypedArray(filePath, array) {
  const view = Buffer.from(array.buffer, array.byteOffset, array.byteLength);
  fs.writeFileSync(filePath, view);
}

function sha256File(filePath) {
  return crypto.createHash("sha256").update(fs.readFileSync(filePath)).digest("hex");
}

function makeCsr(nodeCount, edges, sourceKey, targetKey) {
  const counts = new Uint32Array(nodeCount);
  for (const edge of edges) counts[edge[sourceKey]] += 1;

  const offsets = new Uint32Array(nodeCount + 1);
  for (let i = 0; i < nodeCount; i += 1) {
    offsets[i + 1] = offsets[i] + counts[i];
  }

  const cursor = new Uint32Array(offsets);
  const targets = new Uint32Array(edges.length);
  const edgeIds = new Uint32Array(edges.length);
  for (let edgeId = 0; edgeId < edges.length; edgeId += 1) {
    const edge = edges[edgeId];
    const slot = cursor[edge[sourceKey]];
    targets[slot] = edge[targetKey];
    edgeIds[slot] = edgeId;
    cursor[edge[sourceKey]] += 1;
  }
  return { offsets, targets, edgeIds };
}

function buildGraph(vaultRoot) {
  const files = walkMarkdown(vaultRoot);
  const strings = {
    paths: { map: new Map(), values: [] },
    basenames: { map: new Map(), values: [] },
    clusters: { map: new Map(), values: [] },
  };

  const nodes = [];
  const byPath = new Map();
  const byBase = new Map();
  const duplicateBasenames = new Set();
  const fileTexts = new Map();

  for (const file of files) {
    const filePath = vaultPath(vaultRoot, file);
    const text = fs.readFileSync(file, "utf8");
    fileTexts.set(filePath, text);
    const base = basename(filePath);
    if (byBase.has(base)) duplicateBasenames.add(base);
    else byBase.set(base, nodes.length);
    byPath.set(filePath.replace(/\.md$/i, ""), nodes.length);
    nodes.push({
      id: nodes.length,
      path: filePath,
      base,
      type: classifyNode(filePath, text),
      cluster: clusterName(filePath),
      mtime: fs.statSync(file).mtimeMs,
    });
  }

  const edges = [];
  const unresolved = [];
  for (const node of nodes) {
    const text = fileTexts.get(node.path);
    let match;
    while ((match = LINK_RE.exec(text))) {
      const rawTarget = normalizeTarget(match[1]);
      const resolved =
        byPath.get(rawTarget) ??
        byPath.get(`${rawTarget}.md`) ??
        byBase.get(path.basename(rawTarget));
      if (resolved === undefined) {
        unresolved.push({ source: node.path, target: rawTarget });
        continue;
      }
      const lineStart = text.lastIndexOf("\n", match.index) + 1;
      const lineEnd = text.indexOf("\n", match.index);
      const line = text.slice(lineStart, lineEnd >= 0 ? lineEnd : text.length);
      const isBackbone = line.includes("Backbone link:");
      edges.push({
        source: node.id,
        target: resolved,
        weight: 1,
        flags: isBackbone ? 1 : 0,
        type: isBackbone ? 2 : 1,
      });
    }
  }

  const ids = new Uint32Array(nodes.length);
  const nodeTypes = new Uint16Array(nodes.length);
  const nodeFlags = new Uint32Array(nodes.length);
  const nodeClusters = new Uint32Array(nodes.length);
  const nodePathStrings = new Uint32Array(nodes.length);
  const nodeBasenameStrings = new Uint32Array(nodes.length);
  const nodeMtime = new Float64Array(nodes.length);
  const layoutX = new Float32Array(nodes.length);
  const layoutY = new Float32Array(nodes.length);

  const goldenAngle = Math.PI * (3 - Math.sqrt(5));
  const radiusScale = Math.max(100, Math.sqrt(nodes.length) * 10);
  for (const node of nodes) {
    ids[node.id] = node.id;
    nodeTypes[node.id] = node.type;
    nodeFlags[node.id] = 0;
    nodeClusters[node.id] = stringId(strings.clusters, node.cluster);
    nodePathStrings[node.id] = stringId(strings.paths, node.path);
    nodeBasenameStrings[node.id] = stringId(strings.basenames, node.base);
    nodeMtime[node.id] = node.mtime;
    const radius = radiusScale * Math.sqrt((node.id + 0.5) / Math.max(1, nodes.length));
    const angle = node.id * goldenAngle;
    layoutX[node.id] = Math.cos(angle) * radius;
    layoutY[node.id] = Math.sin(angle) * radius;
  }

  const edgeSources = new Uint32Array(edges.length);
  const edgeTargets = new Uint32Array(edges.length);
  const edgeWeights = new Float32Array(edges.length);
  const edgeFlags = new Uint32Array(edges.length);
  const edgeTypes = new Uint16Array(edges.length);
  for (let i = 0; i < edges.length; i += 1) {
    edgeSources[i] = edges[i].source;
    edgeTargets[i] = edges[i].target;
    edgeWeights[i] = edges[i].weight;
    edgeFlags[i] = edges[i].flags;
    edgeTypes[i] = edges[i].type;
  }

  const out = makeCsr(nodes.length, edges, "source", "target");
  const incomingEdges = edges.map((edge) => ({ source: edge.target, target: edge.source }));
  const incoming = makeCsr(nodes.length, incomingEdges, "source", "target");

  return {
    stats: {
      files: files.length,
      nodes: nodes.length,
      edges: edges.length,
      clusters: strings.clusters.values.length,
      unresolved: unresolved.length,
      duplicateBasenames: duplicateBasenames.size,
      backboneEdges: edges.filter((edge) => edge.flags & 1).length,
    },
    unresolved,
    duplicateBasenames: [...duplicateBasenames],
    strings: {
      paths: strings.paths.values,
      basenames: strings.basenames.values,
      clusters: strings.clusters.values,
    },
    arrays: {
      ids,
      nodeTypes,
      nodeFlags,
      nodeClusters,
      nodePathStrings,
      nodeBasenameStrings,
      nodeMtime,
      edgeSources,
      edgeTargets,
      edgeWeights,
      edgeFlags,
      edgeTypes,
      outOffsets: out.offsets,
      outTargets: out.targets,
      outEdgeIds: out.edgeIds,
      inOffsets: incoming.offsets,
      inSources: incoming.targets,
      inEdgeIds: incoming.edgeIds,
      layoutX,
      layoutY,
    },
  };
}

function writeStore(vaultRoot, outRoot, graph, options = {}) {
  ensureDir(outRoot);
  const currentDir = path.join(outRoot, "graph.current");
  const previousDir = path.join(outRoot, "graph.previous");
  const nextDir = path.join(outRoot, "graph.next");
  const lockPath = path.join(outRoot, "graph.lock");
  const manifestPath = path.join(outRoot, "graph.manifest.json");
  const journalPath = path.join(outRoot, "graph.journal.jsonl");
  for (const target of [currentDir, previousDir, nextDir, lockPath, manifestPath, journalPath]) {
    assertInside(outRoot, target);
  }

  fs.writeFileSync(lockPath, JSON.stringify({ pid: process.pid, startedAt: new Date().toISOString() }), "utf8");
  try {
    if (!options.keepNext) rmGeneratedDir(outRoot, nextDir);
    ensureDir(nextDir);

    const files = {
      nodesIds: "graph.nodes.ids.bin",
      nodesType: "graph.nodes.type.bin",
      nodesFlags: "graph.nodes.flags.bin",
      nodesCluster: "graph.nodes.cluster.bin",
      nodesPathString: "graph.nodes.path-string.bin",
      nodesBasenameString: "graph.nodes.basename-string.bin",
      nodesMtime: "graph.nodes.mtime.bin",
      edgesSource: "graph.edges.source.bin",
      edgesTarget: "graph.edges.target.bin",
      edgesWeight: "graph.edges.weight.bin",
      edgesFlags: "graph.edges.flags.bin",
      edgesType: "graph.edges.type.bin",
      outOffsets: "graph.out.offsets.bin",
      outTargets: "graph.out.targets.bin",
      outEdgeIds: "graph.out.edge-ids.bin",
      inOffsets: "graph.in.offsets.bin",
      inSources: "graph.in.sources.bin",
      inEdgeIds: "graph.in.edge-ids.bin",
      layoutX: "graph.layout.x.bin",
      layoutY: "graph.layout.y.bin",
      strings: "graph.strings.json",
      stats: "graph.stats.json",
    };

    writeTypedArray(path.join(nextDir, files.nodesIds), graph.arrays.ids);
    writeTypedArray(path.join(nextDir, files.nodesType), graph.arrays.nodeTypes);
    writeTypedArray(path.join(nextDir, files.nodesFlags), graph.arrays.nodeFlags);
    writeTypedArray(path.join(nextDir, files.nodesCluster), graph.arrays.nodeClusters);
    writeTypedArray(path.join(nextDir, files.nodesPathString), graph.arrays.nodePathStrings);
    writeTypedArray(path.join(nextDir, files.nodesBasenameString), graph.arrays.nodeBasenameStrings);
    writeTypedArray(path.join(nextDir, files.nodesMtime), graph.arrays.nodeMtime);
    writeTypedArray(path.join(nextDir, files.edgesSource), graph.arrays.edgeSources);
    writeTypedArray(path.join(nextDir, files.edgesTarget), graph.arrays.edgeTargets);
    writeTypedArray(path.join(nextDir, files.edgesWeight), graph.arrays.edgeWeights);
    writeTypedArray(path.join(nextDir, files.edgesFlags), graph.arrays.edgeFlags);
    writeTypedArray(path.join(nextDir, files.edgesType), graph.arrays.edgeTypes);
    writeTypedArray(path.join(nextDir, files.outOffsets), graph.arrays.outOffsets);
    writeTypedArray(path.join(nextDir, files.outTargets), graph.arrays.outTargets);
    writeTypedArray(path.join(nextDir, files.outEdgeIds), graph.arrays.outEdgeIds);
    writeTypedArray(path.join(nextDir, files.inOffsets), graph.arrays.inOffsets);
    writeTypedArray(path.join(nextDir, files.inSources), graph.arrays.inSources);
    writeTypedArray(path.join(nextDir, files.inEdgeIds), graph.arrays.inEdgeIds);
    writeTypedArray(path.join(nextDir, files.layoutX), graph.arrays.layoutX);
    writeTypedArray(path.join(nextDir, files.layoutY), graph.arrays.layoutY);
    writeJson(path.join(nextDir, files.strings), graph.strings);
    writeJson(path.join(nextDir, files.stats), graph.stats);

    const checksums = {};
    for (const fileName of Object.values(files)) {
      checksums[fileName] = sha256File(path.join(nextDir, fileName));
    }

    const manifest = {
      schemaVersion: SCHEMA_VERSION,
      storeVersion: STORE_VERSION,
      status: "ready",
      builtAt: new Date().toISOString(),
      activeDir: "graph.current",
      vault: {
        root: vaultRoot,
        name: path.basename(vaultRoot),
      },
      stats: graph.stats,
      arrays: {
        integerFormat: "little-endian",
        nodeCount: graph.stats.nodes,
        edgeCount: graph.stats.edges,
      },
      files,
      checksums,
      validation: validateGraph(graph),
    };
    writeJson(path.join(nextDir, "graph.manifest.json"), manifest);
    validateStore(nextDir, manifest);

    if (fs.existsSync(previousDir)) rmGeneratedDir(outRoot, previousDir);
    if (fs.existsSync(currentDir)) fs.renameSync(currentDir, previousDir);
    fs.renameSync(nextDir, currentDir);
    writeJson(manifestPath, { ...manifest, activeDir: "graph.current" });
    fs.appendFileSync(
      journalPath,
      `${JSON.stringify({ at: new Date().toISOString(), event: "build-complete", stats: graph.stats })}\n`,
      "utf8",
    );
    return manifest;
  } finally {
    fs.rmSync(lockPath, { force: true });
  }
}

function validateGraph(graph) {
  const errors = [];
  if (graph.stats.unresolved !== 0) errors.push(`unresolved:${graph.stats.unresolved}`);
  if (graph.stats.duplicateBasenames !== 0) errors.push(`duplicateBasenames:${graph.stats.duplicateBasenames}`);
  if (graph.arrays.edgeSources.length !== graph.arrays.edgeTargets.length) errors.push("edge-source-target-length-mismatch");
  if (graph.arrays.outOffsets.length !== graph.stats.nodes + 1) errors.push("out-offset-length-mismatch");
  if (graph.arrays.inOffsets.length !== graph.stats.nodes + 1) errors.push("in-offset-length-mismatch");
  if (graph.arrays.outOffsets[graph.arrays.outOffsets.length - 1] !== graph.stats.edges) errors.push("out-csr-edge-count-mismatch");
  if (graph.arrays.inOffsets[graph.arrays.inOffsets.length - 1] !== graph.stats.edges) errors.push("in-csr-edge-count-mismatch");
  return {
    ok: errors.length === 0,
    errors,
  };
}

function validateStore(dir, manifest) {
  if (!manifest.validation.ok) {
    throw new Error(`Graph validation failed: ${manifest.validation.errors.join(", ")}`);
  }
  for (const [label, fileName] of Object.entries(manifest.files)) {
    const full = path.join(dir, fileName);
    if (!fs.existsSync(full)) {
      throw new Error(`Missing graph store file ${label}: ${fileName}`);
    }
    const checksum = sha256File(full);
    if (checksum !== manifest.checksums[fileName]) {
      throw new Error(`Checksum mismatch for ${fileName}`);
    }
  }
  return true;
}

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

function loadGraphStore(outRoot) {
  const root = path.resolve(outRoot);
  const manifestPath = path.join(root, "graph.manifest.json");
  const currentDir = path.join(root, "graph.current");
  const previousDir = path.join(root, "graph.previous");

  const failures = [];
  try {
    const manifest = readJson(manifestPath);
    validateStore(currentDir, manifest);
    return {
      ok: true,
      activeDir: "graph.current",
      manifest,
      recoveredFromPrevious: false,
      failures,
    };
  } catch (error) {
    failures.push({ activeDir: "graph.current", error: String(error.message || error) });
  }

  try {
    const previousManifest = readJson(path.join(previousDir, "graph.manifest.json"));
    validateStore(previousDir, previousManifest);
    return {
      ok: true,
      activeDir: "graph.previous",
      manifest: previousManifest,
      recoveredFromPrevious: true,
      failures,
    };
  } catch (error) {
    failures.push({ activeDir: "graph.previous", error: String(error.message || error) });
  }

  return {
    ok: false,
    activeDir: null,
    manifest: null,
    recoveredFromPrevious: false,
    failures,
  };
}

function main() {
  const args = parseArgs(process.argv);
  const vaultRoot = path.resolve(args.vault);
  const outRoot = path.resolve(args.out);
  const graph = buildGraph(vaultRoot);
  const manifest = writeStore(vaultRoot, outRoot, graph, args);
  process.stdout.write(`${JSON.stringify({ ok: true, manifest: path.join(outRoot, "graph.manifest.json"), stats: manifest.stats }, null, 2)}\n`);
}

if (require.main === module) {
  try {
    main();
  } catch (error) {
    console.error(error.stack || error);
    process.exit(1);
  }
}

module.exports = {
  buildGraph,
  loadGraphStore,
  validateGraph,
  validateStore,
  writeStore,
};
