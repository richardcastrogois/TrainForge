"""Geração code-first preparada para V1-008; não cria um serviço Go fictício.

Pré-requisitos futuros: services/api/go.mod, cmd/api/main.go anotado e swag v1.16.6.
Não instala ferramentas, não chama endpoints e não inicia Swagger UI.
"""
import argparse
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SWAG_VERSION = "v1.16.6"
TARGETS = {"docs.go": "services/api/internal/swaggerdocs/docs.go",
           "swagger.json": "contracts/generated/swagger-v1.json",
           "swagger.yaml": "contracts/generated/swagger-v1.yaml"}


def generate(root, write=False):
    service = root / "services/api"
    if not (service / "go.mod").exists():
        if any((root / relative).exists() for relative in TARGETS.values()):
            raise ValueError("Derivados Swagger presentes sem serviço Go: não é possível validar sua origem")
        return "PENDENTE V1-008: backend Go ausente; nenhum Swagger gerado ou validado."
    if not (service / "cmd/api/main.go").exists():
        raise ValueError("Backend Go presente, mas cmd/api/main.go não existe para @title/@version e demais anotações")
    binary = shutil.which("swag")
    if not binary:
        raise ValueError(f"Swaggo {SWAG_VERSION} necessário. Instalação explícita: go install github.com/swaggo/swag/cmd/swag@{SWAG_VERSION}")
    version = subprocess.check_output([binary, "--version"], text=True).strip()
    if version.split()[-1] != SWAG_VERSION:
        raise ValueError(f"Versão de swag divergente: esperada {SWAG_VERSION}; encontrada {version}")
    with tempfile.TemporaryDirectory(prefix="trainforge-swagger-") as directory:
        output = Path(directory)
        subprocess.run([binary, "init", "--generalInfo", "cmd/api/main.go", "--dir", ".", "--parseInternal",
                        "--exclude", "internal/swaggerdocs", "--output", str(output), "--outputTypes", "go,json,yaml"],
                       cwd=service, check=True)
        stale = []
        for name, relative in TARGETS.items():
            content = (output / name).read_bytes().replace(b"\r\n", b"\n")
            path = root / relative
            if write:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(content)
            elif not path.exists() or path.read_bytes().replace(b"\r\n", b"\n") != content:
                stale.append(relative)
        if stale:
            raise ValueError("Swagger divergente dos comentários/tipos Go: " + ", ".join(stale) + ". Execute --write.")
    return "Swagger gerado/conferido pelos comentários e tipos Go; testar handlers e autorização continua necessário."


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if not args.write and not args.check:
        parser.error("Use --write ou --check")
    print(generate(ROOT, args.write))


if __name__ == "__main__":
    main()
