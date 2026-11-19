"""Create an explicitly non-distributable catalog for clean-checkout native CI builds."""
from __future__ import annotations
import gzip
import os
from pathlib import Path
import tempfile

from food_catalog import ROOT, CatalogWriter, canonical, make_food, parse_value, sha_file, sign_manifest


def main():
    if os.environ.get('CI') != 'true' or os.environ.get('TF_CATALOG_NATIVE_FIXTURE') != '1':
        raise RuntimeError('Only an explicitly requested CI fixture is accepted')
    if (ROOT / '.local/api.env').exists():
        raise RuntimeError('Local development data present; fixture generation refused')
    output = ROOT / 'assets/food_catalog'
    output.mkdir(parents=True, exist_ok=True)
    # The private signing key exists only inside a temporary CI directory.
    with tempfile.TemporaryDirectory(prefix='trainforge-native-catalog-ci-') as temporary:
        work = Path(temporary)
        source = {'name': 'Synthetic CI fixture', 'publisher': 'TrainForge tests',
                  'url': 'https://example.invalid/ci-fixture', 'licenseLabel': 'CC0 1.0',
                  'licenseUrl': 'https://creativecommons.org/publicdomain/zero/1.0/',
                  'attribution': 'Synthetic test fixture; not a real food.', 'version': '1',
                  'conditions': ['CI only. Never distribute as the production catalog.']}
        raw = work / 'catalog.sqlite'
        writer = CatalogWriter(raw, {'TF-CI-FIXTURE': source})
        writer.add(make_food('TF-CI-FIXTURE', '1', 'Synthetic CI food', 'en', '1',
                   {'quantity': '100', 'unit': 'g'}, [
                       {'sourceColumnKey':'ci:protein','nameOriginal':'Protein','unit':'g',
                        'basisQuantity':'100','basisUnit':'g','scalingAllowed':True, **parse_value('1')}]))
        payload = writer.finish()
        compressed = output / 'catalog.sqlite.gz'
        with raw.open('rb') as src, compressed.open('wb') as dst:
            with gzip.GzipFile(filename='', fileobj=dst, mode='wb', mtime=0, compresslevel=1) as encoded:
                for block in iter(lambda: src.read(1 << 20), b''): encoded.write(block)
        payload.update({'file':'catalog.sqlite.gz','bytes':compressed.stat().st_size,'sha256':sha_file(compressed),
                        'databaseFile':'catalog.sqlite','databaseBytes':raw.stat().st_size,'databaseSha256':sha_file(raw),
                        'complete':False,'fixture':True,'missingSources':['production catalog'], 'exports':[]})
        sign_manifest(payload, work / 'signing', output)
    print(canonical({'scope':'native-ci-fixture-only','distributable':False}))


if __name__ == '__main__': main()
