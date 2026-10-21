"""Releitura offline de exercicios proprios do cuidador; nao monta sessao."""
import argparse
import importlib.util
import json
from pathlib import Path

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
ROUND = ROOT / "2026-10-07/n15c-conteudo"
SPEC = importlib.util.spec_from_file_location("manual_receipts", ROOT / "analisar-n15c-manuais.py")
RECEIPTS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(RECEIPTS)
SOURCES = {
    "PR67": ("2026-10-07/n15c-conteudo/c15-guia-ms-2008.evidencia.json", 64, [2, 11, 12, 13, 14]),
    "PR52": ("2026-10-04/n15c-retomada/c15-ufrn-tese-original-pdf.evidencia.json", 181, [117, 128, 143, 144, 146, 147]),
    "PR63": ("2026-10-06/n15c-fechamento/c15-va-workbook-modulo1.evidencia.json", 54, [21, 22, 23]),
}


def analyse(render=False):
    entries = []
    for source, (reference, page_count, pages) in SOURCES.items():
        path = ROOT / reference
        entry = RECEIPTS.check_receipt(path)
        if not entry["usable"]:
            raise ValueError("Source body is not usable")
        record = json.loads(path.read_text(encoding="utf-8"))
        body = (path.parent / record["bodyFile"]).resolve()
        reader = PdfReader(body)
        if len(reader.pages) != page_count:
            raise ValueError("Unexpected source version/page count")
        entry.update(sourceId=source, pdfPages=page_count, readPdfPagesOneBased=pages)
        for number in pages:
            value = " ".join((reader.pages[number-1].extract_text() or "").split())
            if not value:
                raise ValueError("Empty relevant text page")
            print(f"{source} PDF page{number}: {value}")
        if render:
            import pypdfium2 as pdfium
            doc = pdfium.PdfDocument(body)
            try:
                for number in pages:
                    page = doc[number-1]
                    bitmap = page.render(scale=1.5)
                    try:
                        bitmap.to_pil().save(ROUND.parent / "raw" / f"{source}-p{number}.png")
                    finally:
                        bitmap.close()
                        page.close()
            finally:
                doc.close()
        entries.append(entry)
    output = {
        "date": "2026-10-07", "scope": ["N15-C"], "networkPerformed": False,
        "sources": entries, "newCollectorCalls": 1, "reusedBodies": 2,
        "renderedPagesThisRun": sum(len(row[2]) for row in SOURCES.values()) if render else 0,
        "visualInspectionConfirmedByScript": False,
        "researchClosureApproved": False, "releaseApproved": False, "appImplemented": False,
    }
    (ROUND / "inventario.json").write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"verifiedBodies": len(entries), "newCollectorCalls": 1, "reusedBodies": 2}))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--render", action="store_true")
    analyse(parser.parse_args().render)
