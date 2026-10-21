// Text-only OLE parsing; no Office process, macros, links or embedded assets executed.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { createRequire } = require('node:module');

async function main() {
  const root = __dirname;
  const folder = path.join(root, '2026-10-11', 'n15c-mindfulness-protocolos');
  const receipt = JSON.parse(fs.readFileSync(path.join(folder, 'c15-most2023-suplemento-doc.evidencia.json'), 'utf8'));
  const bodyPath = path.resolve(folder, receipt.bodyFile);
  if (!bodyPath.startsWith(root + path.sep)) throw new Error('Body outside evidence root');
  const body = fs.readFileSync(bodyPath);
  const digest = crypto.createHash('sha256').update(body).digest('hex');
  if (receipt.status !== 200 || receipt.error || body.length !== receipt.bytes || digest !== receipt.sha256 || body.length > 2097152) {
    throw new Error('Receipt, hash or size mismatch');
  }
  const requireReader = createRequire(path.join(root, '2026-10-11', 'raw', 'doc-reader', 'package.json'));
  const WordExtractor = requireReader('word-extractor');
  const version = requireReader('word-extractor/package.json').version;
  if (version !== '1.0.4') throw new Error('Unexpected parser version');
  const document = await new WordExtractor().extract(body);
  const parts = {body: document.getBody(), footnotes: document.getFootnotes(),
    endnotes: document.getEndnotes(), headers: document.getHeaders(),
    footers: document.getFooters(), annotations: document.getAnnotations(),
    textboxes: document.getTextboxes()};
  const serialized = JSON.stringify(parts, null, 2) + '\n';
  if (Buffer.byteLength(serialized, 'utf8') > 2097152) throw new Error('Extracted text exceeds limit');
  const outputPath = path.join(root, '2026-10-11', 'raw', 'c15-most2023-doc-text.json');
  fs.writeFileSync(outputPath, serialized, {encoding: 'utf8', flag: 'wx'});
  const audit = {niche: 'N15-C', date: '2026-10-11', sourceId: 'PR110',
    sourceReceipt: 'c15-most2023-suplemento-doc.evidencia.json', sourceSha256: digest,
    parser: 'word-extractor', parserVersion: version,
    parserRepository: 'https://github.com/morungos/node-word-extractor',
    installScriptsDisabled: true, officeOrMacrosExecuted: false,
    networkCallsDuringParsing: 0, sourceBytes: body.length, maxExtractedBytes: 2097152,
    extractedTextFile: '../raw/c15-most2023-doc-text.json',
    extractedTextSha256: crypto.createHash('sha256').update(serialized).digest('hex'),
    extractedTextBytes: Buffer.byteLength(serialized, 'utf8'),
    partCharacters: Object.fromEntries(Object.entries(parts).map(([key, text]) => [key, text.length])),
    layoutOrVisualInspectionPerformed: false, textExtractionIsCompleteVisualProof: false,
    researchClosureApproved: false, releaseApproved: false, appImplemented: false};
  fs.writeFileSync(path.join(folder, 'leitura-doc.json'), JSON.stringify(audit, null, 2) + '\n', {encoding: 'utf8', flag: 'wx'});
  process.stdout.write(JSON.stringify(audit) + '\n');
}

main().catch(error => {process.stderr.write(String(error) + '\n'); process.exitCode = 1;});
