"""Atualiza somente o AST Dart de lib/, sem rede, chaves, semântica ou clustering."""
from __future__ import annotations
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'graphify-out'


def worker(write):
    from graphify.detect import detect_incremental, save_manifest
    from graphify.extract import extract
    from graphify.build import build_merge
    source = ROOT / 'lib'
    result = detect_incremental(source, manifest_path=str(OUT / 'manifest.json'), kind='ast')
    changed = [Path(p) for rows in result.get('new_files', {}).values() for p in rows]
    if any(p.suffix != '.dart' or not p.resolve().is_relative_to(source.resolve()) for p in changed):
        raise RuntimeError('Unexpected corpus; only lib Dart AST is allowed')
    deleted = result.get('deleted_files', [])
    old = json.loads((OUT / 'graph.json').read_text(encoding='utf-8'))
    receipt = {'scope': 'lib Dart AST only, no semantic extraction or clustering',
               'dartFiles': len(list(source.rglob('*.dart'))), 'changedFiles': len(changed),
               'deletedFiles': len(deleted), 'nodes': len(old['nodes']), 'edges': len(old['edges']),
               'llmTokens': 0, 'networkCalls': 0}
    if not write:
        print(json.dumps(receipt))
        return 1 if changed or deleted else 0
    moment = datetime.now(timezone.utc)
    backup = ROOT / '.local' / ('graphify-backup-' + moment.strftime('%Y%m%dT%H%M%S%fZ'))
    backup.mkdir(parents=True)
    for name in ('graph.json', 'graph.html', 'manifest.json', 'GRAPH_REPORT.md', 'update.json'):
        if (OUT / name).is_file():
            shutil.copy2(OUT / name, backup / name)
    if changed or deleted:
        fresh = extract(changed, root=source, cache_root=source, parallel=False) if changed else {'nodes': [], 'edges': []}
        graph = build_merge([fresh], graph_path=OUT / 'graph.json', prune_sources=deleted or None,
                            root=source, directed=False)
        merged = {'nodes': [{'id': n, **d} for n, d in graph.nodes(data=True)],
                  'edges': [{**{k: v for k, v in d.items() if k not in ('_src', '_tgt', 'source', 'target')},
                             'source': d.get('_src', a), 'target': d.get('_tgt', b)} for a, b, d in graph.edges(data=True)],
                  'hyperedges': list(graph.graph.get('hyperedges', [])), 'input_tokens': 0, 'output_tokens': 0}
        (OUT / 'graph.json').write_text(json.dumps(merged, ensure_ascii=False, indent=2), encoding='utf-8')
        save_manifest(result['files'], manifest_path=str(OUT / 'manifest.json'), kind='ast', root=source,
                      scan_corpus={p for rows in result['files'].values() for p in rows})
        receipt.update(nodes=len(merged['nodes']), edges=len(merged['edges']))
    receipt.update(verifiedAtUtc=moment.isoformat(), backup=backup.relative_to(ROOT).as_posix())
    (OUT / 'update.json').write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf-8')
    report = ('# Mapa atual do TrainForge\n\n'
              f"Verificado em {moment.date().isoformat()} UTC: **{receipt['dartFiles']} arquivos Dart, "
              f"{receipt['nodes']} nós e {receipt['edges']} arestas**.\n\n"
              'Extração AST incremental de `lib/`, sem rede, sem LLM e sem clustering novo. '
              'A limpeza documental não altera o código Dart, por isso pode produzir zero arquivos alterados.\n\n'
              '[Grafo interativo](graph.html) · [JSON](graph.json) · [Recibo](update.json) · '
              '[Uso e limites](../docs/graphify.md)\n\n'
              'Este grafo mostra relações estáticas do Flutter. Go, SQL, fontes e documentos são explicados '
              'na [arquitetura](../docs/arquitetura/README.md) e no [histórico](../docs/historico/README.md). '
              'Arestas não demonstram navegação executada, segurança, persistência ou aceite humano.\n')
    (OUT / 'GRAPH_REPORT.md').write_text(report, encoding='utf-8')
    subprocess.run([sys.executable, '-m', 'graphify', 'export', 'html'], cwd=ROOT, check=True)
    print(json.dumps(receipt))
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true', help='Atualizar derivados com backup privado')
    parser.add_argument('--worker', action='store_true', help=argparse.SUPPRESS)
    args = parser.parse_args()
    if args.worker:
        return worker(args.write)
    selector = OUT / '.graphify_python'
    if not selector.is_file():
        raise RuntimeError('Graphify interpreter is not registered; no installation is performed')
    interpreter = Path(selector.read_text(encoding='utf-8').strip())
    if not interpreter.is_file():
        raise RuntimeError('Registered Graphify interpreter is unavailable; configure it on this machine')
    return subprocess.run([str(interpreter), str(Path(__file__).resolve()), '--worker',
                           *(['--write'] if args.write else [])], cwd=ROOT).returncode


if __name__ == '__main__':
    raise SystemExit(main())
