"""Consultar provas documentais offline, sem recriar milhares de arquivos em docs."""
import argparse
import json
from evidence_store import ROOT, records, read_text, extract, verify


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('listar', 'mostrar', 'extrair', 'verificar'))
    parser.add_argument('path', nargs='?', help='Caminho original completo: docs/conteudo/evidencias/...')
    parser.add_argument('--filtro', default='')
    args = parser.parse_args()
    if args.action == 'listar':
        for key, (_, row) in sorted(records().items()):
            if args.filtro.casefold() in key.casefold():
                print(json.dumps(row, ensure_ascii=False))
    elif args.action == 'verificar':
        print(json.dumps({'verifiedFiles': verify(), 'networkCalls': 0, 'filesExtracted': 0}))
    else:
        if not args.path:
            parser.error('Informe o caminho original do arquivo')
        if args.action == 'mostrar':
            print(read_text(args.path, archived=True))
        else:
            print(extract(args.path).relative_to(ROOT).as_posix())


if __name__ == '__main__':
    main()
