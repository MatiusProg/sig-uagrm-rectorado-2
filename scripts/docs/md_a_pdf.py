"""Convierte documentos Markdown de docs/ a PDF con el navegador (Chrome o Edge).

Uso (desde la raíz del repo):
    python scripts/docs/md_a_pdf.py docs/guia-campo.md docs/Guia-Campo-RECT2.pdf
Requiere: pip install markdown
"""
import os, pathlib, subprocess, sys, tempfile
import markdown

CSS = """
@page { size: A4; margin: 16mm 15mm; }
body { font-family: "Segoe UI", Arial, sans-serif; font-size: 10.5pt; line-height: 1.45; color: #15232b; }
h1 { font-size: 21pt; margin: 0 0 6pt; border-bottom: 3px solid #0f6b5c; padding-bottom: 4pt; }
h2 { font-size: 14pt; color: #0f6b5c; margin: 16pt 0 6pt; break-after: avoid; }
h3 { font-size: 11.5pt; margin: 12pt 0 4pt; break-after: avoid; }
blockquote { margin: 0 0 10pt; padding: 6pt 10pt; background: #fff2b3; border-radius: 6pt; }
blockquote p { margin: 2pt 0; }
table { border-collapse: collapse; width: 100%; margin: 6pt 0 10pt; font-size: 9.5pt; break-inside: auto; }
tr { break-inside: avoid; }
th, td { border: 1px solid #c9d3d1; padding: 4pt 6pt; text-align: left; vertical-align: top; }
th { background: #e6eeec; }
code { font-family: Consolas, monospace; font-size: 9pt; background: #e6eeec; padding: 0 3pt; border-radius: 3pt; }
img { vertical-align: top; border: 1px solid #c9d3d1; border-radius: 6pt; margin: 4pt 8pt 4pt 0; }
p.pair { break-inside: avoid; }
ul, ol { padding-left: 18pt; }
li { margin: 2pt 0; }
a { color: #0f6b5c; text-decoration: none; }
"""

def navegador():
    for p in (r"C:\Program Files\Google\Chrome\Application\chrome.exe",
              r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"):
        if os.path.exists(p):
            return p
    sys.exit("No se encontró Chrome ni Edge")

def main(origen, destino):
    origen, destino = pathlib.Path(origen).resolve(), pathlib.Path(destino).resolve()
    cuerpo = markdown.markdown(origen.read_text(encoding="utf-8"), extensions=["tables", "attr_list"])
    titulo = origen.stem
    html = (f'<!doctype html><html lang="es"><head><meta charset="utf-8"><title>{titulo}</title>'
            f'<base href="{origen.parent.as_uri()}/"><style>{CSS}</style></head><body>{cuerpo}</body></html>')
    with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False, encoding="utf-8") as f:
        f.write(html)
    subprocess.run([navegador(), "--headless=new", "--disable-gpu", "--no-pdf-header-footer",
                    f"--print-to-pdf={destino}", pathlib.Path(f.name).as_uri()],
                   check=True, capture_output=True)
    os.unlink(f.name)
    print("PDF:", destino)

if __name__ == "__main__":
    main(*sys.argv[1:3])
