const fs = require('fs');
const path = require('path');

const root = 'C:/obsidian/Main/Calendula-People-Graph-From-Branch/Calendula';
const circleDirs = ['1_круг', '2_круг', '3_круг', '4_круг', '5_круг'];
const dayRoot = path.join(root, 'Calendula');
const startDay = new Date('2040-01-01T00:00:00Z');
const months = ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'];
const totalPerCircle = 1600;
const dayCount = 2000;

function pad(n, len = 4) {
  return String(n).padStart(len, '0');
}

function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true });
}

function dayName(d) {
  const dd = String(d.getUTCDate()).padStart(2, '0');
  const mm = String(d.getUTCMonth() + 1).padStart(2, '0');
  const yy = String(d.getUTCFullYear()).slice(-2);
  return `${dd}-${mm}-${yy}`;
}

function monthName(d) {
  return months[d.getUTCMonth()];
}

ensureDir(dayRoot);

for (let c = 0; c < circleDirs.length; c++) {
  const circle = circleDirs[c];
  const dir = path.join(root, 'Люди', circle);
  ensureDir(dir);
  const other = circleDirs[(c + 1) % circleDirs.length];

  for (let i = 1; i <= totalPerCircle; i++) {
    const name = `Доп${c + 1}_${pad(i, 4)}`;
    const dayIndex = (c * totalPerCircle + i - 1) % dayCount;
    const d = new Date(startDay.getTime() + dayIndex * 24 * 60 * 60 * 1000);
    const dayFile = path.join(dayRoot, String(d.getUTCFullYear()), monthName(d), `${dayName(d)}.md`);
    ensureDir(path.dirname(dayFile));

    const content = [
      `# ${name}`,
      '',
      `Круг: ${circle}`,
      `День: [[Calendula/${d.getUTCFullYear()}/${monthName(d)}/${dayName(d)}|${dayName(d)}]]`,
      `Связь: [[Люди/${other}/${`Доп${((c + 1) % circleDirs.length) + 1}_${pad(i, 4)}`}|соседний круг]]`,
      '',
    ].join('\r\n');

    fs.writeFileSync(path.join(dir, `${name}.md`), content, 'utf8');

    const dayContent = [
      `[[Люди/${circle}/${name}|${name}]]`,
      `[[Люди/${other}/${`Доп${((c + 1) % circleDirs.length) + 1}_${pad(i, 4)}`}|${name}-${other}]]`,
      '',
    ].join('\r\n');

    if (!fs.existsSync(dayFile)) {
      fs.writeFileSync(dayFile, dayContent, 'utf8');
    }
  }
}

for (let i = 0; i < dayCount; i++) {
  const d = new Date(startDay.getTime() + i * 24 * 60 * 60 * 1000);
  const dayFile = path.join(dayRoot, String(d.getUTCFullYear()), monthName(d), `${dayName(d)}.md`);
  if (!fs.existsSync(dayFile)) {
    ensureDir(path.dirname(dayFile));
    const circle = circleDirs[i % circleDirs.length];
    const name = `Доп${(i % circleDirs.length) + 1}_${pad((i % totalPerCircle) + 1, 4)}`;
    fs.writeFileSync(dayFile, `[[Люди/${circle}/${name}|${name}]]\r\n`, 'utf8');
  }
}

fs.writeFileSync(path.join(root, 'Люди.md'), [
  '# Люди',
  '',
  'Раздел людей.',
  '',
  '## Связи',
  '- [[Графы]]',
  '- [[Calendula/Соц Капитал|Calendula: Соц Капитал]]',
  '- [[Calendula-20K/Соц Капитал|Calendula-20K: Соц Капитал]]',
  '- [[Calendula-30K/Люди|Calendula-30K: Люди]]',
  '- [[Calendula-People-Graph/Calendula/Люди|People graph: Люди]]',
  '- [[Calendula-People-Graph-From-Branch/Calendula/Люди|Branch graph: Люди]]',
].join('\r\n'), 'utf8');

