const crypto = require("crypto");

const CONTRACTS = Object.freeze({
  EVIDENCE: "EvidenceRecord/v12.0",
  DECISION: "EvidenceDecision/v12.0",
  MENTION: "EvidenceMention/v12.0",
  GENERATED_EDGE: "EvidenceGeneratedEdge/v12.0",
});

const SIGNAL = Object.freeze({
  ALIAS_MATCH: "ALIAS_MATCH",
  WIKILINK: "WIKILINK",
  TAG_CONTEXT: "TAG_CONTEXT",
  DATE_CONTEXT: "DATE_CONTEXT",
  HEADING_CONTEXT: "HEADING_CONTEXT",
  NEARBY_KEYWORD: "NEARBY_KEYWORD",
  CO_MENTION: "CO_MENTION",
  RECENT_INTERACTION: "RECENT_INTERACTION",
  MANUAL_CORRECTION: "MANUAL_CORRECTION",
  SECTION_REJECTION: "SECTION_REJECTION",
});

const STRENGTH = Object.freeze({
  NEGATIVE: "negative",
  WEAK: "weak",
  MEDIUM: "medium",
  STRONG: "strong",
  DECISIVE: "decisive",
});

const DECISION = Object.freeze({
  ACCEPT: "ACCEPT",
  REJECT: "REJECT",
  DEFER: "DEFER",
  NEEDS_REVIEW: "NEEDS_REVIEW",
  USER_ACCEPTED: "USER_ACCEPTED",
  USER_REJECTED: "USER_REJECTED",
});

const NEGATIVE_REASONS = new Set([
  "inside-code",
  "inside-inline-code",
  "inside-url",
  "inside-markdown-link",
  "inside-wikilink",
  "ambiguous-alias",
  "short-alias",
  "common-word",
  "user-rejected",
]);

const HUMAN_ACCEPT_REASONS = new Set(["user-accepted", "manual-accepted"]);
const HUMAN_REJECT_REASONS = new Set(["user-rejected", "manual-rejected"]);

function newId(prefix) {
  if (typeof crypto.randomUUID === "function") return `${prefix}-${crypto.randomUUID()}`;
  return `${prefix}-${Date.now().toString(36)}-${Math.random().toString(36).slice(2)}`;
}

function requiredString(value, name) {
  if (!value || typeof value !== "string") {
    throw new Error(`${name} must be a non-empty string`);
  }
  return value;
}

function normalizeStrength(value) {
  const normalized = String(value || STRENGTH.MEDIUM).toLowerCase();
  if (Object.values(STRENGTH).includes(normalized)) return normalized;
  return STRENGTH.MEDIUM;
}

function sanitizeMetadata(metadata = {}) {
  const blocked = new Set(["rawText", "text", "content", "markdown", "body"]);
  const out = {};
  for (const [key, value] of Object.entries(metadata || {})) {
    if (blocked.has(key)) continue;
    if (value === undefined) continue;
    out[key] = value;
  }
  return Object.freeze(out);
}

function freezeArray(values) {
  return Object.freeze(Array.from(values || []));
}

function createEvidenceRecord({
  evidenceId = newId("evidence"),
  entityUuid,
  sourceUuid,
  targetUuid = null,
  type = "PERSON_SIGNAL",
  signal,
  strength = STRENGTH.MEDIUM,
  reason,
  timeBucket = null,
  policyVersion = 1,
  extractorVersion = 1,
  metadata = {},
} = {}) {
  const signalValue = requiredString(signal, "signal");
  if (!Object.values(SIGNAL).includes(signalValue)) {
    throw new Error(`Unknown evidence signal: ${signalValue}`);
  }

  return Object.freeze({
    contract: CONTRACTS.EVIDENCE,
    evidenceId: requiredString(evidenceId, "evidenceId"),
    entityUuid: requiredString(entityUuid, "entityUuid"),
    sourceUuid: requiredString(sourceUuid, "sourceUuid"),
    targetUuid: targetUuid || null,
    type: requiredString(type, "type"),
    signal: signalValue,
    strength: normalizeStrength(strength),
    reason: requiredString(reason, "reason"),
    timeBucket: timeBucket || null,
    policyVersion: Number(policyVersion || 1),
    extractorVersion: Number(extractorVersion || 1),
    metadata: sanitizeMetadata(metadata),
  });
}

function isHumanAccepted(evidence) {
  return evidence.signal === SIGNAL.MANUAL_CORRECTION && HUMAN_ACCEPT_REASONS.has(evidence.reason);
}

function isHumanRejected(evidence) {
  return evidence.signal === SIGNAL.MANUAL_CORRECTION && HUMAN_REJECT_REASONS.has(evidence.reason);
}

function isNegativeEvidence(evidence) {
  return evidence.strength === STRENGTH.NEGATIVE || NEGATIVE_REASONS.has(evidence.reason);
}

function isStrongPositiveEvidence(evidence) {
  if (isNegativeEvidence(evidence)) return false;
  if (evidence.strength === STRENGTH.DECISIVE || evidence.strength === STRENGTH.STRONG) return true;
  return evidence.signal === SIGNAL.WIKILINK || evidence.signal === SIGNAL.RECENT_INTERACTION;
}

function aggregateEvidenceDecision({
  decisionId = newId("decision"),
  target = "note-person-edge",
  evidence = [],
  policyVersion = 1,
} = {}) {
  const records = Array.from(evidence || []);
  for (const record of records) {
    if (!record || record.contract !== CONTRACTS.EVIDENCE) {
      throw new Error("aggregateEvidenceDecision expects EvidenceRecord/v12.0 records");
    }
  }

  const humanAccepts = records.filter(isHumanAccepted);
  const humanRejects = records.filter(isHumanRejected);
  const negatives = records.filter(isNegativeEvidence);
  const positives = records.filter(isStrongPositiveEvidence);

  let decision = DECISION.DEFER;
  const reasons = [];

  if (humanRejects.length > 0) {
    decision = DECISION.USER_REJECTED;
    reasons.push("human-rejection");
  } else if (humanAccepts.length > 0) {
    decision = DECISION.USER_ACCEPTED;
    reasons.push("human-acceptance");
  } else if (negatives.length > 0) {
    decision = DECISION.REJECT;
    reasons.push("negative-evidence");
  } else if (positives.length > 0) {
    decision = DECISION.ACCEPT;
    reasons.push("strong-positive-evidence");
  } else if (records.length > 0) {
    decision = DECISION.NEEDS_REVIEW;
    reasons.push("weak-or-ambiguous-evidence");
  } else {
    reasons.push("no-evidence");
  }

  return Object.freeze({
    contract: CONTRACTS.DECISION,
    decisionId: requiredString(decisionId, "decisionId"),
    decision,
    target: requiredString(target, "target"),
    evidenceIds: freezeArray(records.map((record) => record.evidenceId)),
    acceptedEvidenceIds: freezeArray(positives.map((record) => record.evidenceId)),
    rejectedEvidenceIds: freezeArray(negatives.map((record) => record.evidenceId)),
    policyVersion: Number(policyVersion || 1),
    reasons: freezeArray(reasons),
    stats: Object.freeze({
      evidence: records.length,
      positive: positives.length,
      negative: negatives.length,
      humanAccepts: humanAccepts.length,
      humanRejects: humanRejects.length,
    }),
  });
}

function createEvidenceBackedMention({
  mentionId = newId("mention"),
  noteUuid,
  personUuid,
  aliasUuid,
  offset = 0,
  length = 0,
  decision,
} = {}) {
  if (!decision || decision.contract !== CONTRACTS.DECISION) {
    throw new Error("createEvidenceBackedMention expects EvidenceDecision/v12.0");
  }

  return Object.freeze({
    contract: CONTRACTS.MENTION,
    mentionId: requiredString(mentionId, "mentionId"),
    noteUuid: requiredString(noteUuid, "noteUuid"),
    personUuid: requiredString(personUuid, "personUuid"),
    aliasUuid: requiredString(aliasUuid, "aliasUuid"),
    offset: Math.max(0, Math.floor(Number(offset || 0))),
    length: Math.max(0, Math.floor(Number(length || 0))),
    decisionId: decision.decisionId,
    decision: decision.decision,
    evidenceIds: decision.evidenceIds,
    accepted: [DECISION.ACCEPT, DECISION.USER_ACCEPTED].includes(decision.decision),
  });
}

function createGeneratedPeopleEdge({
  edgeId = newId("edge"),
  sourceUuid,
  targetUuid,
  mentionIds = [],
  decision,
  edgeSource = "people-autolink",
} = {}) {
  if (!decision || decision.contract !== CONTRACTS.DECISION) {
    throw new Error("createGeneratedPeopleEdge expects EvidenceDecision/v12.0");
  }
  if (![DECISION.ACCEPT, DECISION.USER_ACCEPTED].includes(decision.decision)) {
    throw new Error(`Cannot create generated people edge from ${decision.decision}`);
  }

  return Object.freeze({
    contract: CONTRACTS.GENERATED_EDGE,
    edgeId: requiredString(edgeId, "edgeId"),
    sourceUuid: requiredString(sourceUuid, "sourceUuid"),
    targetUuid: requiredString(targetUuid, "targetUuid"),
    edgeSource,
    decisionId: decision.decisionId,
    decision: decision.decision,
    mentionIds: freezeArray(mentionIds),
    evidenceIds: decision.evidenceIds,
  });
}

module.exports = {
  CONTRACTS,
  SIGNAL,
  STRENGTH,
  DECISION,
  createEvidenceRecord,
  aggregateEvidenceDecision,
  createEvidenceBackedMention,
  createGeneratedPeopleEdge,
};
