"""Generate only the seven M1 catalog/health operations from existing Go annotations."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
from gerar_swagger import validate_build_info

ROOT=Path(__file__).resolve().parents[1]
TARGETS={'swagger.json':'contracts/generated/catalog-m1.swagger.json','swagger.yaml':'contracts/generated/catalog-m1.swagger.yaml'}
PATHS={'/api/v1/catalog/filters','/api/v1/catalog/programs','/api/v1/catalog/programs/{id}',
       '/api/v1/catalog/movements','/api/v1/catalog/movements/{id}','/api/v1/health/live','/api/v1/health/ready'}


def validate_contract(reference,document):
    if set(document.get('paths',{}))!=PATHS or document.get('securityDefinitions') or document.get('security'):
        raise ValueError('M1 must expose only public catalog/health operations')
    for path in PATHS:
        if set(document['paths'][path])!={'get'} or document['paths'][path]!=reference['paths'].get(path):
            raise ValueError('Public operation differs from current API contract')
    for name,definition in document.get('definitions',{}).items():
        if not name.startswith(('catalog.','httpapi.')) or definition!=reference.get('definitions',{}).get(name):
            raise ValueError('M1 public schema differs or contains another domain')


def generate(root,write=False):
    binary=shutil.which('swag')
    if not binary:raise ValueError('Use the already pinned Swaggo v1.16.6; no automatic installation')
    validate_build_info(subprocess.check_output(['go','version','-m',binary],text=True))
    with tempfile.TemporaryDirectory(prefix='trainforge-catalog-swagger-') as directory:
        subprocess.run([binary,'init','--generalInfo','cmd/catalog/main.go','--dir','.',
            '--parseInternal','--exclude','internal/swaggerdocs,internal/auth,internal/nutrition,internal/privacy,internal/trainingconfig,cmd/api',
            '--packageName','catalogdocs','--output',directory,'--outputTypes','json,yaml'],cwd=root/'services/api',check=True)
        reference=json.loads((root/'contracts/generated/swagger-v1.json').read_text(encoding='utf-8'))
        document=json.loads((Path(directory)/'swagger.json').read_text(encoding='utf-8'))
        validate_contract(reference,document)
        for name,target in TARGETS.items():
            content=(Path(directory)/name).read_bytes().replace(b'\r\n',b'\n');path=root/target
            if write:path.write_bytes(content)
            elif not path.exists() or path.read_bytes().replace(b'\r\n',b'\n')!=content:raise ValueError('M1 Swagger drift; regenerate from Go annotations')
    return 'Catalog M1: five existing public routes plus health; current API schemas preserved.'


def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--write',action='store_true');parser.add_argument('--check',action='store_true');args=parser.parse_args()
    if not args.write and not args.check:parser.error('Use --write or --check')
    print(generate(ROOT,args.write))


if __name__=='__main__':main()
