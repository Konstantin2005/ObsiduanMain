const fs = require('fs');
const path = require('path');

const base = 'C:/obsidian/Main/Calendula-People-Graph-From-Branch/Calendula-20K/Calendula';
const outRoot = 'C:/obsidian/Main/Calendula-People-Graph-From-Branch/Calendula-20K/Круг';
const total = 10000;

function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true });
}

function collectNotes(dir) {
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

function relLink(file) {
  const rel = path.relative('C:/obsidian/Main/Calendula-People-Graph-From-Branch', file).replace(/\\/g, '/');
  const name = path.basename(file, '.md');
  return `[[${rel}|${name}]]`;
}

const notes = collectNotes(base);
if (!notes.length) throw new Error('No base notes found');
ensureDir(outRoot);

for (let i = 1; i <= total; i++) {
  const prev = i === 1 ? total : i - 1;
  const next = i === total ? 1 : i + 1;
  const picks = [];
  const seed = (i * 7919) % notes.length;
  for (let k = 0; k < 3; k++) {
    picks.push(notes[(seed + k * 1543 + i) % notes.length]);
  }
  const content = [
    `# Круг-${String(i).padStart(5, '0')}`,
    '',
    `Кольцо: [[Calendula-20K/Круг/Круг-${String(prev).padStart(5, '0')}|предыдущая]]`,
    `Кольцо: [[Calendula-20K/Круг/Круг-${String(next).padStart(5, '0')}|следующая]]`,
    '',
    '## Случайные ссылки',
    ...picks.map(relLink),
    '',
  ].join('\r\n');
  fs.writeFileSync(path.join(outRoot, `Круг-${String(i).padStart(5, '0')}.md`), content, 'utf8');
}

fs.writeFileSync(path.join('C:/obsidian/Main/Calendula-People-Graph-From-Branch/Calendula-20K', 'Круг.md'), [
  '# Круг',
  '',
  'Вход в 10k-слой, замкнутый на 20K-заметки.',
  '',
  '- [[Calendula-20K/Круг/Круг-00001|Начало круга]]',
].join('\r\n'), 'utf8');

