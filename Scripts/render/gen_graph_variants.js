const fs = require('fs');
const path = require('path');

const root = 'C:/obsidian/Main/Calendula-People-Graph-From-Branch/Графы-Варианты';
const sourcePeople = 'C:/obsidian/Main/Calendula-People-Graph-From-Branch/Calendula/Люди';
const sourceDays = 'C:/obsidian/Main/Calendula-People-Graph-From-Branch/Calendula/Calendula';
const source20K = 'C:/obsidian/Main/Calendula-People-Graph-From-Branch/Calendula-20K/Круг';
const sourceMain20K = 'C:/obsidian/Main/Calendula-People-Graph-From-Branch/Calendula-20K/Calendula';

function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true });
}

function collectMarkdown(dir) {
  const files = [];
  const stack = [dir];
  while (stack.length) {
    const current = stack.pop();
    for (const entry of fs.readdirSync(current, { withFileTypes: true })) {
      const full = path.join(current, entry.name);
      if (entry.isDirectory()) stack.push(full);
      else if (entry.isFile() && entry.name.endsWith('.md')) files.push(full);
    }
  }
  return files;
}

function rel(from, to) {
  return path.relative(from, to).replace(/\\/g, '/');
}

function writeNote(file, lines) {
  ensureDir(path.dirname(file));
  fs.writeFileSync(file, lines.join('\r\n'), 'utf8');
}

const people = collectMarkdown(sourcePeople);
const days = collectMarkdown(sourceDays);
const circle20 = collectMarkdown(source20K);
const twentyK = collectMarkdown(sourceMain20K);

if (!people.length || !days.length || !circle20.length || !twentyK.length) {
  throw new Error('Missing source notes for graph variants');
}

ensureDir(root);

// 1. Tree
{
  const dir = path.join(root, 'Tree');
  ensureDir(dir);
  const nodes = 511;
  for (let i = 1; i <= nodes; i++) {
    const left = i * 2 <= nodes ? `Tree-${String(i * 2).padStart(4, '0')}` : null;
    const right = i * 2 + 1 <= nodes ? `Tree-${String(i * 2 + 1).padStart(4, '0')}` : null;
    const refs = [
      people[i % people.length],
      days[(i * 7) % days.length],
    ].map(f => `[[${rel(dir, f)}|${path.basename(f, '.md')}]]`);
    writeNote(path.join(dir, `Tree-${String(i).padStart(4, '0')}.md`), [
      `# Tree-${String(i).padStart(4, '0')}`,
      '',
      `Позиция: ${i}`,
      left ? `Левый: [[Tree-${String(i * 2).padStart(4, '0')}]]` : 'Левый: -',
      right ? `Правый: [[Tree-${String(i * 2 + 1).padStart(4, '0')}]]` : 'Правый: -',
      '',
      '## Ссылки',
      ...refs,
      '',
    ]);
  }
  writeNote(path.join(dir, 'README.md'), [
    '# Tree',
    '',
    '- [[Tree-0001]]',
  ]);
}

// 2. Binary tree
{
  const dir = path.join(root, 'Binary-Tree');
  ensureDir(dir);
  const nodes = 255;
  for (let i = 1; i <= nodes; i++) {
    const left = i * 2 <= nodes ? `Binary-${String(i * 2).padStart(4, '0')}` : null;
    const right = i * 2 + 1 <= nodes ? `Binary-${String(i * 2 + 1).padStart(4, '0')}` : null;
    const refs = [
      circle20[(i * 13) % circle20.length],
      twentyK[(i * 17) % twentyK.length],
    ].map(f => `[[${rel(dir, f)}|${path.basename(f, '.md')}]]`);
    writeNote(path.join(dir, `Binary-${String(i).padStart(4, '0')}.md`), [
      `# Binary-${String(i).padStart(4, '0')}`,
      '',
      `Левый: ${left ? `[[${left}]]` : '-'}`,
      `Правый: ${right ? `[[${right}]]` : '-'}`,
      '',
      '## Ссылки',
      ...refs,
      '',
    ]);
  }
  writeNote(path.join(dir, 'README.md'), ['# Binary Tree', '', '- [[Binary-0001]]']);
}

// 3. Topological graph
{
  const dir = path.join(root, 'Topo');
  ensureDir(dir);
  const nodes = 300;
  for (let i = 1; i <= nodes; i++) {
    const deps = [];
    if (i > 1) deps.push(i - 1);
    if (i > 2 && i % 3 === 0) deps.push(i - 2);
    if (i > 5 && i % 7 === 0) deps.push(i - 5);
    const refs = [
      people[(i * 19) % people.length],
      days[(i * 23) % days.length],
      circle20[(i * 29) % circle20.length],
    ].map(f => `[[${rel(dir, f)}|${path.basename(f, '.md')}]]`);
    writeNote(path.join(dir, `Topo-${String(i).padStart(4, '0')}.md`), [
      `# Topo-${String(i).padStart(4, '0')}`,
      '',
      `Depends: ${deps.length ? deps.map(d => `[[Topo-${String(d).padStart(4, '0')}]]`).join(', ') : '-'}`,
      '',
      '## Ссылки',
      ...refs,
      '',
    ]);
  }
  writeNote(path.join(dir, 'README.md'), ['# Topo Graph', '', '- [[Topo-0001]]']);
}

// 4. Complex graph
{
  const dir = path.join(root, 'Complex');
  ensureDir(dir);
  const nodes = 600;
  for (let i = 1; i <= nodes; i++) {
    const chain = [
      `[[Complex-${String(((i % nodes) + 1)).padStart(4, '0')}]]`,
      `[[Complex-${String(((i + 11) % nodes) + 1).padStart(4, '0')}]]`,
      `[[Complex-${String(((i * 7) % nodes) + 1).padStart(4, '0')}]]`,
    ];
    const refs = [
      people[(i * 31) % people.length],
      days[(i * 37) % days.length],
      twentyK[(i * 41) % twentyK.length],
      circle20[(i * 43) % circle20.length],
    ].map(f => `[[${rel(dir, f)}|${path.basename(f, '.md')}]]`);
    writeNote(path.join(dir, `Complex-${String(i).padStart(4, '0')}.md`), [
      `# Complex-${String(i).padStart(4, '0')}`,
      '',
      `Hub: ${chain.join(' ')}`,
      '',
      '## Ссылки',
      ...refs,
      '',
    ]);
  }
  writeNote(path.join(dir, 'README.md'), ['# Complex Graph', '', '- [[Complex-0001]]']);
}

writeNote(path.join(root, 'README.md'), [
  '# Графы-Варианты',
  '',
  '- [[Tree/README|Tree]]',
  '- [[Binary-Tree/README|Binary Tree]]',
  '- [[Topo/README|Topo]]',
  '- [[Complex/README|Complex]]',
]);

