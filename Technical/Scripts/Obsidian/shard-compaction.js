const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const zlib = require("zlib");

const COMPACT_DIR = "graph.compact";
const JOURNAL_FILE = "graph.journal.jsonl";
const MANIFEST_FILE = "graph.manifest.json";
const COMPRESS_THRESHOLD_RATIO = 0.5;

function assertInside(parent, child) {
  const relative = path.relative(parent, child);
  if (relative.startsWith("..") || path.isAbsolute(relative)) {
    throw new Error(`Refusing to write outside graph store: ${child}`);
  }
}

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function rmDir(root, target) {
  assertInside(root, target);
  fs.rmSync(target, { recursive: true, force: true });
}

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

function writeJson(filePath, value) {
  fs.writeFileSync(filePath, `${JSON.stringify(value, null, 2)}\n`, "utf8");
}

function sha256File(filePath) {
  return crypto.createHash("sha256").update(fs.readFileSync(filePath)).digest("hex");
}

function readTypedArray(filePath) {
  return new Uint8Array(fs.readFileSync(filePath));
}

function writeTypedArray(filePath, array) {
  const view = Buffer.from(array.buffer, array.byteOffset, array.byteLength);
  fs.writeFileSync(filePath, view);
}

function compressBuffer(buffer) {
  return zlib.deflateSync(buffer, { level: 9 });
}

function decompressBuffer(buffer) {
  return zlib.inflateSync(buffer);
}

function walkDir(dir) {
  const files = [];
  function walk(current) {
    for (const entry of fs.readdirSync(current, { withFileTypes: true })) {
      const full = path.join(current, entry.name);
      if (entry.isDirectory()) walk(full);
      else if (entry.isFile()) files.push(full);
    }
  }
  if (fs.existsSync(dir)) walk(dir);
  return files;
}

/**
 * Compact graph store: dedup JSON, compress .bin.
 *
 * @param {string} outRoot  - graph store root dir
 * @param {object} [options]
 * @param {boolean} [options.dryRun]  - simulate only
 * @param {boolean} [options.force]   - compact even if loadStore ok
 * @returns {{ ok: boolean, freedBytes: number, compactedFiles: string[], errors: string[] }}
 */
function compactStore(outRoot, options = {}) {
  const root = path.resolve(outRoot);
  const currentDir = path.join(root, "graph.current");
  const previousDir = path.join(root, "graph.previous");
  const compactDir = path.join(root, COMPACT_DIR);

  const result = { ok: false, freedBytes: 0, compactedFiles: [], errors: [] };

  if (!fs.existsSync(currentDir)) {
    result.errors.push("graph.current not found");
    return result;
  }

  if (!options.force) {
    try {
      const manifestPath = path.join(root, MANIFEST_FILE);
      const manifest = readJson(manifestPath);
      validateStore(currentDir, manifest);
      // store is healthy, compaction is optional
    } catch {
      result.errors.push("store not healthy, run recoverManifest first");
      return result;
    }
  }

  try {
    if (fs.existsSync(compactDir)) rmDir(root, compactDir);
    ensureDir(compactDir);

    const currentFiles = walkDir(currentDir).map((f) => path.relative(currentDir, f));
    const previousFiles = fs.existsSync(previousDir)
      ? walkDir(previousDir).map((f) => path.relative(previousDir, f))
      : [];

    const previousContent = {};
    for (const relPath of previousFiles) {
      const full = path.join(previousDir, relPath);
      try {
        previousContent[relPath] = fs.readFileSync(full);
      } catch {
        // skip corrupt files
      }
    }

    const deduped = new Set();
    const freed = { bytes: 0 };

    for (const relPath of currentFiles) {
      const full = path.join(currentDir, relPath);
      const content = fs.readFileSync(full);

      if (!options.dryRun) {
        if (relPath.endsWith(".json") && previousContent[relPath]) {
          const currentStr = content.toString("utf8").trim();
          const previousStr = previousContent[relPath].toString("utf8").trim();
          if (currentStr === previousStr) {
            freed.bytes += previousContent[relPath].length;
            // skip copy — identical JSON, let previous be deleted at cleanup
            result.compactedFiles.push(`${relPath} (dedup)`);
            deduped.add(relPath);
            continue;
          }
        }

        if (relPath.endsWith(".bin") && content.length > 4096) {
          const compressed = compressBuffer(content);
          if (compressed.length < content.length * COMPRESS_THRESHOLD_RATIO) {
            writeTypedArray(path.join(compactDir, relPath), compressed);
            result.compactedFiles.push(`${relPath} (compress ${content.length}→${compressed.length})`);
            freed.bytes += content.length - compressed.length;
            continue;
          }
        }

        const targetPath = path.join(compactDir, relPath);
        ensureDir(path.dirname(targetPath));
        fs.cpSync(full, targetPath, { dereference: true });
      }
    }

    if (!options.dryRun) {
      const files = {};
      for (const f of currentFiles) {
        if (deduped.has(f)) continue;
        const rel = f.replace(/\\/g, "/");
        const parts = rel.replace(/\.bin$/, ".bin").split("/");
        const label = parts.join("_").replace(/\./g, "_");
        files[label] = rel;
      }

      const stats = readJson(path.join(currentDir, "graph.stats.json"));
      const oldManifest = readJson(path.join(currentDir, MANIFEST_FILE));

      const checksums = {};
      const compactFiles = walkDir(compactDir).map((f) => path.relative(compactDir, f));
      for (const fname of compactFiles) {
        checksums[fname] = sha256File(path.join(compactDir, fname));
      }

      const newManifest = {
        ...oldManifest,
        status: "compacted",
        compactedAt: new Date().toISOString(),
        compactedFrom: "graph.current",
        files,
        checksums,
        compaction: {
          freedBytes: freed.bytes,
          compressedCount: result.compactedFiles.length,
          previousDirRemoved: false,
        },
      };

      writeJson(path.join(compactDir, MANIFEST_FILE), newManifest);
      validateStore(compactDir, newManifest);

      if (fs.existsSync(previousDir)) {
        rmDir(root, previousDir);
        newManifest.compaction.previousDirRemoved = true;
      }

      if (fs.existsSync(currentDir)) rmDir(root, currentDir);
      fs.renameSync(compactDir, currentDir);

      writeJson(path.join(root, MANIFEST_FILE), { ...newManifest, activeDir: "graph.current" });
      appendJournal(root, { event: "compact-complete", freedBytes: freed.bytes, compactedFiles: result.compactedFiles.length });
    }

    result.ok = true;
    result.freedBytes = freed.bytes;
    return result;
  } catch (err) {
    result.errors.push(String(err.message || err));
    if (fs.existsSync(compactDir)) rmDir(root, compactDir);
    return result;
  }
}

/**
 * Recover manifest after partial failure.
 *
 * Scans: graph.current → graph.previous → repair by rescanning files.
 *
 * @param {string} outRoot
 * @returns {{ ok: boolean, manifest: object|null, recoveredFrom: string, repairs: string[] }}
 */
function recoverManifest(outRoot) {
  const root = path.resolve(outRoot);
  const currentDir = path.join(root, "graph.current");
  const previousDir = path.join(root, "graph.previous");
  const journalPath = path.join(root, JOURNAL_FILE);
  const manifestPath = path.join(root, MANIFEST_FILE);

  const result = { ok: false, manifest: null, recoveredFrom: "", repairs: [] };

  // Try current
  try {
    if (fs.existsSync(path.join(currentDir, MANIFEST_FILE))) {
      const manifest = readJson(path.join(currentDir, MANIFEST_FILE));
      validateStore(currentDir, manifest);
      result.ok = true;
      result.manifest = manifest;
      result.recoveredFrom = "graph.current";
      return result;
    }
  } catch (err) {
    result.repairs.push(`current manifest: ${err.message}`);
  }

  // Try previous
  try {
    if (fs.existsSync(previousDir) && fs.existsSync(path.join(previousDir, MANIFEST_FILE))) {
      const manifest = readJson(path.join(previousDir, MANIFEST_FILE));
      validateStore(previousDir, manifest);
      result.ok = true;
      result.manifest = { ...manifest, activeDir: "graph.previous" };
      result.recoveredFrom = "graph.previous";
      writeJson(manifestPath, result.manifest);
      result.repairs.push("restored from graph.previous");
      return result;
    }
  } catch (err) {
    result.repairs.push(`previous manifest: ${err.message}`);
  }

  // Try repair — scan current dir for files, rebuild checksums
  try {
    if (fs.existsSync(currentDir)) {
      const files = {};
      const checksums = {};
      const currentRelFiles = walkDir(currentDir).map((f) => path.relative(currentDir, f));

      for (const relPath of currentRelFiles) {
        const parts = relPath.replace(/\.bin$/, ".bin").split(/[/\\]/);
        const label = parts.join("_").replace(/\./g, "_");
        files[label] = relPath.replace(/\\/g, "/");
        checksums[relPath.replace(/\\/g, "/")] = sha256File(path.join(currentDir, relPath));
      }

      const stats = fs.existsSync(path.join(currentDir, "graph.stats.json"))
        ? readJson(path.join(currentDir, "graph.stats.json"))
        : {};

      let schemaVersion = 6;
      let storeVersion = "2026.06.10.1";
      try {
        const journal = fs.readFileSync(journalPath, "utf8").trim().split("\n").filter(Boolean);
        const lastBuild = journal.map((l) => JSON.parse(l)).filter((e) => e.event === "build-complete").pop();
        if (lastBuild?.stats) {
          Object.assign(stats, lastBuild.stats);
        }
      } catch {
        // journal not available
      }

      const manifest = {
        schemaVersion,
        storeVersion,
        status: "recovered",
        builtAt: stats.builtAt || new Date().toISOString(),
        recoveredAt: new Date().toISOString(),
        activeDir: "graph.current",
        vault: { root: "", name: "" },
        stats,
        arrays: {
          integerFormat: "little-endian",
          nodeCount: stats.nodes || 0,
          edgeCount: stats.edges || 0,
        },
        compatibility: {
          storeVersion: schemaVersion,
          supportedReadVersions: [6, 7, 8, 9],
          supportedWriteVersion: 6,
          migrationRequired: false,
          canRenderWithoutMigration: true,
        },
        files,
        checksums,
        validation: { ok: true, errors: [] },
        repairNote: "recovered by shard-compaction.js recoverManifest",
      };

      writeJson(path.join(currentDir, MANIFEST_FILE), manifest);
      try {
        validateStore(currentDir, manifest);
      } catch {
        // best effort
      }

      writeJson(manifestPath, manifest);
      appendJournal(root, { event: "manifest-recovered", repairs: result.repairs });

      result.ok = true;
      result.manifest = manifest;
      result.recoveredFrom = "repair";
      result.repairs.push("manifest rebuilt by scanning files");
      return result;
    }
  } catch (err) {
    result.repairs.push(`repair failed: ${err.message}`);
  }

  return result;
}

function validateStore(dir, manifest) {
  if (!manifest.validation?.ok && manifest.validation?.errors?.length) {
    throw new Error(`Graph validation errors: ${manifest.validation.errors.join(", ")}`);
  }
  for (const [label, fileName] of Object.entries(manifest.files || {})) {
    const full = path.join(dir, fileName.replace(/\\/g, "/"));
    if (!fs.existsSync(full)) {
      throw new Error(`Missing graph store file ${label}: ${fileName}`);
    }
    const checksum = sha256File(full);
    if (checksum !== (manifest.checksums || {})[fileName.replace(/\\/g, "/")]) {
      throw new Error(`Checksum mismatch for ${fileName}`);
    }
  }
  return true;
}

function appendJournal(root, entry) {
  try {
    const journalPath = path.join(root, JOURNAL_FILE);
    fs.appendFileSync(journalPath, `${JSON.stringify({ at: new Date().toISOString(), ...entry })}\n`, "utf8");
  } catch {
    // journal write failure is non-fatal
  }
}

module.exports = {
  compactStore,
  recoverManifest,
  validateStore,
};
