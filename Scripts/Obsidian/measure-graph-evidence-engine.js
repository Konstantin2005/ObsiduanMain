const { performance } = require("perf_hooks");
const evidence = require("./graph-evidence-engine.js");

function parseArgs(argv) {
  const args = {
    iterations: 50000,
    rejectEvery: 10,
    edgeEvery: 3,
  };
  for (let i = 0; i < argv.length; i += 1) {
    const key = argv[i];
    const value = argv[i + 1];
    if (key === "--iterations") {
      args.iterations = Math.max(1, Math.floor(Number(value || args.iterations)));
      i += 1;
    } else if (key === "--reject-every") {
      args.rejectEvery = Math.max(0, Math.floor(Number(value || args.rejectEvery)));
      i += 1;
    } else if (key === "--edge-every") {
      args.edgeEvery = Math.max(1, Math.floor(Number(value || args.edgeEvery)));
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

function runBenchmark({ iterations = 50000, rejectEvery = 10, edgeEvery = 3 } = {}) {
  const recordsTimed = timed(() => {
    const records = [];
    for (let i = 0; i < iterations; i += 1) {
      const rejected = rejectEvery > 0 && i % rejectEvery === 0;
      records.push(
        evidence.createEvidenceRecord({
          evidenceId: `ev-${i}`,
          entityUuid: `person-${i % 4000}`,
          sourceUuid: `note-${i % 30000}`,
          targetUuid: `alias-${i % 5000}`,
          signal: rejected ? evidence.SIGNAL.SECTION_REJECTION : evidence.SIGNAL.ALIAS_MATCH,
          strength: rejected ? evidence.STRENGTH.NEGATIVE : evidence.STRENGTH.STRONG,
          reason: rejected ? "inside-code" : "exact-full-name-alias",
          timeBucket: "2026-06",
        }),
      );
    }
    return records;
  });

  const decisionsTimed = timed(() => {
    const decisions = [];
    const records = recordsTimed.value;
    for (let i = 0; i < records.length; i += 1) {
      decisions.push(
        evidence.aggregateEvidenceDecision({
          decisionId: `decision-${i}`,
          target: "note-person-edge",
          evidence: [records[i]],
        }),
      );
    }
    return decisions;
  });

  const edgesTimed = timed(() => {
    const edges = [];
    const mentions = [];
    const decisions = decisionsTimed.value;
    for (let i = 0; i < decisions.length; i += edgeEvery) {
      const decision = decisions[i];
      const mention = evidence.createEvidenceBackedMention({
        mentionId: `mention-${i}`,
        noteUuid: `note-${i % 30000}`,
        personUuid: `person-${i % 4000}`,
        aliasUuid: `alias-${i % 5000}`,
        offset: i,
        length: 5,
        decision,
      });
      mentions.push(mention);
      if (mention.accepted) {
        edges.push(
          evidence.createGeneratedPeopleEdge({
            edgeId: `edge-${i}`,
            sourceUuid: mention.noteUuid,
            targetUuid: mention.personUuid,
            mentionIds: [mention.mentionId],
            decision,
          }),
        );
      }
    }
    return { edges, mentions };
  });

  const accepted = decisionsTimed.value.filter((decision) => decision.decision === evidence.DECISION.ACCEPT).length;
  const rejected = decisionsTimed.value.filter((decision) => decision.decision === evidence.DECISION.REJECT).length;
  const totalMs = Number((recordsTimed.ms + decisionsTimed.ms + edgesTimed.ms).toFixed(3));

  return {
    ok: accepted > 0 && rejected > 0 && edgesTimed.value.edges.length > 0,
    contract: "EvidenceBenchmark/v12.0",
    iterations,
    rejectEvery,
    edgeEvery,
    timingsMs: {
      evidenceRecords: recordsTimed.ms,
      decisions: decisionsTimed.ms,
      mentionsAndEdges: edgesTimed.ms,
      total: totalMs,
    },
    throughputPerSec: {
      evidenceRecords: Math.round(iterations / Math.max(0.001, recordsTimed.ms / 1000)),
      decisions: Math.round(iterations / Math.max(0.001, decisionsTimed.ms / 1000)),
    },
    stats: {
      accepted,
      rejected,
      mentions: edgesTimed.value.mentions.length,
      generatedEdges: edgesTimed.value.edges.length,
    },
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
  parseArgs,
  runBenchmark,
};
