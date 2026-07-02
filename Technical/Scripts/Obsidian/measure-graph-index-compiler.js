const { performance } = require("perf_hooks");
const compiler = require("./graph-index-compiler.js");

function parseArgs(argv) {
  const args = {
    files: 50000,
    changed: 100,
    added: 10,
    deleted: 10,
    corrupt: 5,
  };
  for (let i = 0; i < argv.length; i += 1) {
    const key = argv[i];
    const value = argv[i + 1];
    if (key === "--files") {
      args.files = Math.max(1, Math.floor(Number(value || args.files)));
      i += 1;
    } else if (key === "--changed") {
      args.changed = Math.max(0, Math.floor(Number(value || args.changed)));
      i += 1;
    } else if (key === "--added") {
      args.added = Math.max(0, Math.floor(Number(value || args.added)));
      i += 1;
    } else if (key === "--deleted") {
      args.deleted = Math.max(0, Math.floor(Number(value || args.deleted)));
      i += 1;
    } else if (key === "--corrupt") {
      args.corrupt = Math.max(0, Math.floor(Number(value || args.corrupt)));
      i += 1;
    }
  }
  return args;
}

function timed(fn) {
  const startedAt = performance.now();
  const value = fn();
  return {
    value,
    ms: Number((performance.now() - startedAt).toFixed(3)),
  };
}

function makeEntry(index) {
  const path = `Notes/${String(index).padStart(6, "0")}.md`;
  return {
    path,
    noteUuid: `note-${index}`,
    size: 1000 + (index % 100),
    mtimeMs: 1000000 + index,
    contentHash: `hash-${index}`,
    recordVersion: 14,
    parserVersion: 1,
    resolverVersion: 1,
    schemaVersion: 14,
    recordBuiltAtMs: Date.now(),
  };
}

function buildSyntheticManifests({ files, changed, added, deleted, corrupt }) {
  const previous = [];
  const next = [];
  const deletedStart = Math.max(0, files - deleted);
  const corruptStart = Math.max(0, deletedStart - corrupt);

  for (let i = 0; i < files; i += 1) {
    const entry = makeEntry(i);
    previous.push(entry);
    if (i >= deletedStart) continue;
    if (i < changed) {
      next.push({
        ...entry,
        size: entry.size + 1,
        mtimeMs: entry.mtimeMs + 1,
        quickKey: compiler.makeQuickKey({ path: entry.path, size: entry.size + 1, mtimeMs: entry.mtimeMs + 1 }),
      });
    } else if (i >= corruptStart) {
      next.push({ ...entry, shardStatus: "corrupt" });
    } else {
      next.push({ ...entry });
    }
  }

  for (let i = 0; i < added; i += 1) {
    next.push(makeEntry(files + i));
  }

  return { previous, next };
}

function runBenchmark(options = {}) {
  const args = { ...parseArgs([]), ...options };
  const buildTimed = timed(() => buildSyntheticManifests(args));
  const log = new compiler.IndexOperationLog({ runId: "bench-v14", mode: compiler.INDEX_MODE.BACKGROUND_NORMAL });
  const planTimed = timed(() =>
    compiler.buildChangedSetPlan({
      previousManifest: buildTimed.value.previous,
      nextManifest: buildTimed.value.next,
      operationLog: log,
      readTracker: new compiler.ReadAmplificationTracker({
        budgets: {
          markdownRead: args.changed + args.added + args.corrupt,
          resolverKeysRecomputed: args.deleted + args.corrupt,
        },
      }),
    }),
  );

  const operationLog = log.snapshot({ readAmplification: planTimed.value.readAmplification });
  return {
    ok:
      planTimed.value.readAmplification.ok &&
      planTimed.value.stats.filesPlanned === args.files + args.added &&
      operationLog.eventCounts.TRUST_CLASSIFIED === planTimed.value.decisions.length,
    contract: "IndexCompilerBenchmark/v14.0",
    input: args,
    timingsMs: {
      syntheticManifest: buildTimed.ms,
      changedSetPlan: planTimed.ms,
      total: Number((buildTimed.ms + planTimed.ms).toFixed(3)),
    },
    stateCounts: planTimed.value.stateCounts,
    actionCounts: planTimed.value.actionCounts,
    reasonCounts: planTimed.value.reasonCounts,
    readAmplification: planTimed.value.readAmplification,
    operationEvents: operationLog.events.length,
    stats: planTimed.value.stats,
  };
}

function main() {
  const report = runBenchmark(parseArgs(process.argv.slice(2)));
  process.stdout.write(`${JSON.stringify(report, null, 2)}\n`);
  if (!report.ok) process.exit(1);
}

if (require.main === module) {
  try {
    main();
  } catch (error) {
    process.stderr.write(`${error.stack || error.message}\n`);
    process.exit(1);
  }
}

module.exports = {
  buildSyntheticManifests,
  parseArgs,
  runBenchmark,
};
