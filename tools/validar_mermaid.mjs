// Validação de sintaxe usada na manutenção/CI, dispensada para ler a documentação.
// Recebe uma pasta node_modules temporária com mermaid@11.12.0 e jsdom@26.1.0.
import { readFile, readdir } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

if (!process.argv[2]) throw new Error('Informe o node_modules isolado do validador. Não são dependências do app.');
const modules = resolve(process.argv[2]);
const requireTemporary = createRequire(join(modules, '../package.json'));
const { JSDOM } = requireTemporary('jsdom');
const dom = new JSDOM('<!doctype html><html><body></body></html>');
globalThis.window = dom.window;
globalThis.document = dom.window.document;
globalThis.DOMParser = dom.window.DOMParser;
const { default: mermaid } = await import(pathToFileURL(join(modules, 'mermaid/dist/mermaid.core.mjs')).href);
mermaid.initialize({ startOnLoad: false, securityLevel: 'strict' });
const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const folder = join(root, 'docs/arquitetura');
const files = [];
for (const base of [folder, join(folder, 'gerado')]) {
  for (const name of (await readdir(base)).sort()) if (name.endsWith('.md')) files.push(join(base, name));
}
let count = 0;
for (const file of files) {
  const text = await readFile(file, 'utf8');
  let index = 0;
  for (const match of text.matchAll(/```mermaid\r?\n([\s\S]*?)```/g)) {
    index += 1;
    try { await mermaid.parse(match[1]); }
    catch (error) { throw new Error(`${file}, diagrama ${index}: ${error.message}`); }
    count += 1;
  }
}
if (!count) throw new Error('Nenhum diagrama encontrado: a validação não foi executada.');
console.log(`OK: ${count} diagramas analisados pelo Mermaid 11.12.0.`);
dom.window.close();
