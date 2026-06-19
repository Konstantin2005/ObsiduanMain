const fs = require('fs');
const path = require('path');

const root = 'C:/obsidian/Main/Calendula-People-Graph-From-Branch/Графы-30-Прекрасные';

function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true });
}

function pad(n, len = 4) {
  return String(n).padStart(len, '0');
}

function choose(arr, seed, count, avoidIndex) {
  const out = new Set();
  let x = seed >>> 0;
  while (out.size < count && arr.length > 0) {
    x = (x * 1664525 + 1013904223) >>> 0;
    const idx = x % arr.length;
    if (idx !== avoidIndex) out.add(idx);
  }
  return [...out];
}

ensureDir(root);

const layouts = [
  { name: 'Core', size: 2000, links: 4, kind: 'ядро' },
  { name: 'Petal-01', size: 320, links: 3, kind: 'лепесток' },
  { name: 'Petal-02', size: 320, links: 3, kind: 'лепесток' },
  { name: 'Petal-03', size: 320, links: 3, kind: 'лепесток' },
  { name: 'Petal-04', size: 320, links: 3, kind: 'лепесток' },
  { name: 'Petal-05', size: 320, links: 3, kind: 'лепесток' },
  { name: 'Petal-06', size: 320, links: 3, kind: 'лепесток' },
];

for (let i = 7; i < 30; i++) {
  layouts.push({ name: `Sprout-${pad(i - 6, 2)}`, size: 80, links: 3, kind: 'спутник' });
}

const graphRoot = path.join(root, 'Graphs');
ensureDir(graphRoot);

const graphNames = layouts.map(l => l.name);

for (let g = 0; g < layouts.length; g++) {
  const layout = layouts[g];
  const dir = path.join(graphRoot, layout.name);
  ensureDir(dir);
  const names = Array.from({ length: layout.size }, (_, i) => `${layout.name}-${pad(i + 1, 4)}`);
  const prevGraph = graphNames[(g - 1 + graphNames.length) % graphNames.length];
  const nextGraph = graphNames[(g + 1) % graphNames.length];

  for (let i = 0; i < layout.size; i++) {
    const picks = choose(names, (g + 1) * 100000 + i + 7, layout.links, i);
    const internalLinks = picks.map(idx => `[[${names[idx]}]]`).join(' ');
    const ringPrev = i === 0 ? names[names.length - 1] : names[i - 1];
    const ringNext = i === names.length - 1 ? names[0] : names[i + 1];
    const bridgeA = graphNames[g === 0 ? graphNames.length - 1 : g - 1];
    const bridgeB = graphNames[(g + 1) % graphNames.length];
    fs.writeFileSync(path.join(dir, `${names[i]}.md`), [
      `# ${names[i]}`,
      '',
      `Тип: ${layout.kind}`,
      `Граф: ${layout.name}`,
      `Кольцо: [[${ringPrev}]] [[${ringNext}]]`,
      `Мосты: [[../${bridgeA}/README|${bridgeA}]] [[../${bridgeB}/README|${bridgeB}]]`,
      '',
      '## Внутренние связи',
      internalLinks,
      '',
    ].join('\r\n'), 'utf8');
  }

  fs.writeFileSync(path.join(dir, 'README.md'), [
    `# ${layout.name}`,
    '',
    `Тип: ${layout.kind}`,
    `Размер: ${layout.size}`,
    '',
    '- [[./' + names[0] + '|Вход]]',
  ].join('\r\n'), 'utf8');
}

fs.writeFileSync(path.join(graphRoot, 'README.md'), [
  '# Графы-30-Прекрасные',
  '',
  ...layouts.map(l => `- [[${l.name}/README|${l.name}]]`),
  '',
  'Это композиция из одного ядра, шести лепестков и набора спутников.',
].join('\r\n'), 'utf8');

