const fs = require('fs');
const path = require('path');

const root = 'C:/obsidian/Main/Calendula-People-Graph-From-Branch/Графы-10x1K';
const graphs = 10;
const nodesPerGraph = 1000;

function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true });
}

function pad(n, len = 4) {
  return String(n).padStart(len, '0');
}

function rand(seed) {
  let x = seed >>> 0;
  return () => {
    x = (x * 1664525 + 1013904223) >>> 0;
    return x / 4294967296;
  };
}

ensureDir(root);

for (let g = 1; g <= graphs; g++) {
  const dir = path.join(root, `Graph-${pad(g, 2)}`);
  ensureDir(dir);
  const names = Array.from({ length: nodesPerGraph }, (_, i) => `Node-${pad(i + 1, 4)}`);

  for (let i = 0; i < nodesPerGraph; i++) {
    const rng = rand(g * 100000 + i + 1);
    const picks = new Set();
    while (picks.size < 3) {
      const idx = Math.floor(rng() * nodesPerGraph);
      if (idx !== i) picks.add(idx);
    }
    const links = [...picks].map(idx => `[[${names[idx]}]]`).join(' ');
    const prev = i === 0 ? names[nodesPerGraph - 1] : names[i - 1];
    const next = i === nodesPerGraph - 1 ? names[0] : names[i + 1];

    fs.writeFileSync(path.join(dir, `${names[i]}.md`), [
      `# ${names[i]}`,
      '',
      `Граф: Graph-${pad(g, 2)}`,
      `Кольцо: [[${prev}]] [[${next}]]`,
      '',
      '## Ссылки',
      links,
      '',
    ].join('\r\n'), 'utf8');
  }

  fs.writeFileSync(path.join(dir, 'README.md'), [
    `# Graph-${pad(g, 2)}`,
    '',
    '- [[Node-0001]]',
  ].join('\r\n'), 'utf8');
}

fs.writeFileSync(path.join(root, 'README.md'), [
  '# Графы 10x1K',
  '',
  ...Array.from({ length: graphs }, (_, i) => `- [[Graph-${pad(i + 1, 2)}/README|Graph-${pad(i + 1, 2)}]]`),
  '',
].join('\r\n'), 'utf8');

