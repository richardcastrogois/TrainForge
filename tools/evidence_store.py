"""Read documentary evidence from its original path, verified archive, or private local bodies."""
from __future__ import annotations

from functools import lru_cache
from collections import defaultdict, Counter
import hashlib
import json
from pathlib import Path, PurePosixPath
import zipfile

ROOT = Path(__file__).resolve().parents[1]
INDEXES = ('docs/conteudo/evidencias/indice.json', 'docs/historico/indice.json')


def _key(path, root):
    root = Path(root).resolve()
    target = Path(path)
    target = (root / target).resolve() if not target.is_absolute() else target.resolve()
    if not target.is_relative_to(root / 'docs'):
        raise ValueError('Evidence must stay inside project docs')
    return root, target, target.relative_to(root).as_posix()


def _safe_entry(value):
    p = PurePosixPath(value)
    if not value or '\\' in value or p.is_absolute() or '..' in p.parts or ':' in value:
        raise ValueError('Invalid evidence archive entry')
    return value


@lru_cache(maxsize=8)
def _records(root_text, stamps):
    root = Path(root_text)
    result = {}
    for relative, _ in stamps:
        index = root / relative
        data = json.loads(index.read_text(encoding='utf-8'))
        if data.get('schemaVersion') != 1:
            raise ValueError('Unsupported evidence index')
        archive = (index.parent / data['archive']).resolve()
        if not archive.is_relative_to(index.parent.resolve()) or archive.suffix != '.zip':
            raise ValueError('Archive outside evidence directory')
        for row in data['files']:
            key = _safe_entry(row['path'])
            if not key.startswith('docs/') or key in result:
                raise ValueError('Duplicate or invalid evidence identity')
            digest, size = row['sha256'], row['bytes']
            if not isinstance(digest, str) or len(digest) != 64 or any(c not in '0123456789abcdef' for c in digest):
                raise ValueError('Invalid evidence digest')
            if type(size) is not int or not 0 <= size <= 64 << 20:
                raise ValueError('Invalid evidence size')
            result[key] = (archive, row)
    return result


def records(root=ROOT):
    root = Path(root).resolve()
    stamps = tuple((p, (root / p).stat().st_mtime_ns) for p in INDEXES if (root / p).is_file())
    return _records(str(root), stamps)


def local_path(path, *, root=ROOT):
    """Resolve only an existing file; archives remain bytes and are never auto-extracted."""
    root, target, key = _key(path, root)
    if target.is_file():
        return target
    private = root / '.local/pesquisa-corpos'
    candidate = (private / key).resolve()
    if not candidate.is_relative_to(private.resolve()):
        raise ValueError('Private evidence escaped local storage')
    if candidate.is_file():
        return candidate
    raise FileNotFoundError(key)


def available(path, *, root=ROOT):
    root, target, key = _key(path, root)
    if key in records(root):
        return records(root)[key][0].is_file()
    try:
        local_path(target, root=root)
        return True
    except FileNotFoundError:
        return False


def read_bytes(path, *, root=ROOT, archived=False):
    root, target, key = _key(path, root)
    if target.is_file() and not (archived and key in records(root)):
        return target.read_bytes()
    item = records(root).get(key)
    if item is None:
        return local_path(target, root=root).read_bytes()
    archive, row = item
    with zipfile.ZipFile(archive) as bundle:
        info = bundle.getinfo(key)
        if info.file_size != row['bytes'] or len([i for i in bundle.infolist() if i.filename == key]) != 1:
            raise ValueError('Evidence archive size or identity mismatch')
        value = bundle.read(info)
    if hashlib.sha256(value).hexdigest() != row['sha256']:
        raise ValueError('Evidence digest mismatch')
    return value


def read_text(path, *, root=ROOT, archived=False):
    return read_bytes(path, root=root, archived=archived).decode('utf-8-sig')


def verify(root=ROOT):
    items = records(root)
    groups = defaultdict(list)
    for key, (archive, row) in items.items():
        groups[archive].append((key, row))
    for archive, rows in groups.items():
        with zipfile.ZipFile(archive) as bundle:
            names = Counter(i.filename for i in bundle.infolist())
            for key, row in rows:
                if names[key] != 1 or bundle.getinfo(key).file_size != row['bytes']:
                    raise ValueError('Evidence archive identity mismatch')
                value = bundle.read(key)
                if hashlib.sha256(value).hexdigest() != row['sha256']:
                    raise ValueError('Evidence digest mismatch')
    return len(items)


def extract(path, destination=None, *, root=ROOT):
    root, _, key = _key(path, root)
    private = (root / '.local').resolve()
    destination = Path(destination) if destination else private / 'consulta-evidencias'
    destination = (root / destination).resolve() if not destination.is_absolute() else destination.resolve()
    if not destination.is_relative_to(private):
        raise ValueError('Extract evidence only inside project .local')
    output = (destination / _safe_entry(key)).resolve()
    if not output.is_relative_to(destination):
        raise ValueError('Evidence extraction escaped destination')
    value = read_bytes(key, root=root, archived=True)
    output.parent.mkdir(parents=True, exist_ok=True)
    if not output.resolve().is_relative_to(private):
        raise ValueError('Evidence extraction escaped private storage')
    if output.exists():
        if output.read_bytes() != value:
            raise ValueError('Existing extracted file differs; no overwrite')
        return output
    with output.open('xb') as stream:
        stream.write(value)
    return output
