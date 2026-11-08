const fs = require('fs');
const p =
  'c:/Users/harsh/.cursor/projects/c-Users-harsh-StudioProjects-medi-app/attachments/6766e309-37b1-412d-8b2a-9ea25e58ef7e/invoice-7.pdf';
const b = fs.readFileSync(p);
const s = b.toString('latin1');
const parts = [];
let i = 0;
while ((i = s.indexOf('BT', i)) !== -1) {
  const j = s.indexOf('ET', i);
  if (j < 0) break;
  const chunk = s.slice(i, j);
  const texts = [...chunk.matchAll(/\(([^)]*)\)\s*Tj/g)].map((m) => m[1]);
  if (texts.length) parts.push(texts.join(' | '));
  i = j + 2;
}
console.log(parts.join('\n'));
const raw = [...s.matchAll(/\(([A-Za-z0-9 ₹Rs#:\-\/., ]{3,60})\)/g)].map(
  (m) => m[1],
);
console.log('---RAW---');
console.log([...new Set(raw)].join('\n'));
