// Plugin de desenvolvimento gerado a partir de ../c35-combinar-semana.scripter.js
function autoLayout(dir, props) {
  const f = figma.createFrame();
  f.layoutMode = dir;
  f.primaryAxisSizingMode = "AUTO";
  f.counterAxisSizingMode = "AUTO";
  f.fills = [];
  Object.assign(f, props || {});
  return f;
}
(async () => {
try {
const C = {
  bg: { r: 0xf6 / 255, g: 0xf6 / 255, b: 0xf1 / 255 },
  ink: { r: 0x18 / 255, g: 0x3e / 255, b: 0x32 / 255 },
  muted: { r: 0x4b / 255, g: 0x5e / 255, b: 0x57 / 255 },
  primary: { r: 0x24 / 255, g: 0x68 / 255, b: 0x59 / 255 },
  card: { r: 1, g: 1, b: 1 },
  line: { r: 0xd9 / 255, g: 0xe2 / 255, b: 0xdc / 255 },
};
await figma.loadFontAsync({ family: "Inter", style: "Regular" });
await figma.loadFontAsync({ family: "Inter", style: "Semi Bold" });
await figma.loadFontAsync({ family: "Inter", style: "Bold" });

const ref = await figma.getNodeByIdAsync("23:1080");
const screen = autoLayout("VERTICAL", { name: "26 · Combinar a semana (C35)", itemSpacing: 12 });
screen.primaryAxisSizingMode = "FIXED";
screen.counterAxisSizingMode = "FIXED";
screen.resize(390, 844);
screen.paddingLeft = screen.paddingRight = 24;
screen.paddingTop = 40;
screen.paddingBottom = 24;
screen.fills = [{ type: "SOLID", color: C.bg }];
screen.x = ref ? ref.x + ref.width + 80 : 4000;
screen.y = ref ? ref.y : 0;

function text(chars, size, style, color, width = 342) {
  const t = figma.createText();
  t.fontName = { family: "Inter", style };
  t.fontSize = size;
  t.characters = chars;
  t.fills = [{ type: "SOLID", color }];
  t.textAutoResize = "HEIGHT";
  t.resize(width, t.height);
  return t;
}
screen.appendChild(text("Passo 3 de 4 · Disponibilidade", 13, "Semi Bold", C.muted));
screen.appendChild(text("Como combinar sua semana", 24, "Bold", C.ink));
screen.appendChild(text("Opcional. Só orienta que tipo de sessão o app sugere; você pode mudar quando quiser.", 15, "Regular", C.muted));

const options = [
  ["Só força", "Força nos dias escolhidos, alternando os grupos musculares em dias seguidos.", false],
  ["Força + caminhada", "Força em 2 a 3 dias alternados e caminhada nos outros.", false],
  ["Força + corpo e mente", "Força em 2 a 3 dias e alongamento, respiração, equilíbrio ou relaxamento nos outros.", false],
  ["Completo", "Força, caminhada e um dia de equilíbrio ou corpo e mente.", false],
  ["Equilíbrio e mobilidade (sem peso)", "Só sessões sem levantar peso: equilíbrio, mobilidade, alongamento e peso do corpo. Para casa, praça ou pausa do cuidador.", true],
  ["Decidir depois", "", false],
];
const list = autoLayout("VERTICAL", { name: "Opções", itemSpacing: 6 });
screen.appendChild(list);
list.layoutSizingHorizontal = "FILL";
for (const [title, hint, selected] of options) {
  const row = autoLayout("HORIZONTAL", { name: `Opção · ${title}`, itemSpacing: 12 });
  row.paddingLeft = row.paddingRight = 16;
  row.paddingTop = row.paddingBottom = 10;
  row.cornerRadius = 16;
  row.fills = [{ type: "SOLID", color: C.card }];
  row.strokes = [{ type: "SOLID", color: selected ? C.primary : C.line }];
  row.strokeWeight = selected ? 2 : 1;
  list.appendChild(row);
  row.layoutSizingHorizontal = "FILL";
  const radio = figma.createEllipse();
  radio.name = selected ? "Rádio · marcado" : "Rádio";
  radio.resize(22, 22);
  radio.fills = selected ? [{ type: "SOLID", color: C.primary }] : [];
  radio.strokes = [{ type: "SOLID", color: C.primary }];
  radio.strokeWeight = 2;
  row.appendChild(radio);
  const col = autoLayout("VERTICAL", { name: "Texto", itemSpacing: 4 });
  row.appendChild(col);
  col.layoutSizingHorizontal = "FILL";
  col.appendChild(text(title, 16, "Semi Bold", C.ink, 270));
  if (hint) col.appendChild(text(hint, 13, "Regular", C.muted, 270));
}
const note = text("Sem casa, praça ou pausa do cuidador marcadas, a opção sem peso fica indisponível. Na praça, ela não remove os dias de aparelhos.", 12, "Regular", C.muted);
note.name = "Nota de regra";
screen.appendChild(note);
const cta = autoLayout("HORIZONTAL", { name: "Botão · Continuar" });
cta.paddingTop = cta.paddingBottom = 16;
cta.cornerRadius = 28;
cta.primaryAxisAlignItems = "CENTER";
cta.fills = [{ type: "SOLID", color: C.primary }];
screen.appendChild(cta);
cta.layoutSizingHorizontal = "FILL";
cta.appendChild(text("Continuar", 16, "Semi Bold", C.card, 100));
figma.viewport.scrollAndZoomIntoView([screen]);
figma.closePlugin('C35 criada: ' + screen.name);

} catch (e) { figma.closePlugin('Erro C35: ' + (e && e.message)); }
})();
