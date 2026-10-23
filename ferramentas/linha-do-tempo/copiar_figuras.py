#!/usr/bin/env python3
"""Copia do acervo as figuras listadas no eventos.yaml.

Uso:
    python3 copiar_figuras.py EVENTOS.yaml ACERVO DESTINO

    EVENTOS.yaml  o arquivo de dados da linha do tempo
    ACERVO        raiz do acervo de figuras (os caminhos `figura.acervo` são relativos a ela)
    DESTINO       pasta onde as figuras vão ficar, por exemplo
                  content/recursos/linha-do-tempo-particulas/figuras   (site)
                  saida/figuras                                         (carrossel)

Cada figura é gravada com o nome de `figura.arquivo`. PDF vira PNG (pdftocairo, do
poppler-utils). Se o conteúdo real do arquivo não bater com a extensão do destino, o
script avisa, porque o Hugo escolhe o decodificador pela extensão. Figuras já
atualizadas não são copiadas de novo, e todas ficam com permissão 644.
"""
import os
import shutil
import subprocess
import sys

try:
    import yaml
except ImportError:
    sys.exit("Falta o PyYAML: sudo apt install python3-yaml  (ou pip install pyyaml)")

MAGIA = {b"\xff\xd8\xff": "jpg", b"\x89PNG": "png", b"%PDF": "pdf",
         b"RIFF": "webp", b"GIF8": "gif"}


def formato(caminho):
    with open(caminho, "rb") as f:
        cab = f.read(12)
    for m, fmt in MAGIA.items():
        if cab.startswith(m):
            return fmt
    return "?"


def ext(nome):
    e = os.path.splitext(nome)[1].lower().lstrip(".")
    return "jpg" if e == "jpeg" else e


def main(argv):
    if len(argv) != 4:
        sys.exit(__doc__)
    yml, acervo, dest = argv[1:]
    with open(yml, encoding="utf-8") as f:
        dados = yaml.safe_load(f)
    os.makedirs(dest, exist_ok=True)
    faltam = 0
    for ev in dados["eventos"]:
        fig = ev.get("figura")
        if not fig:
            continue
        src = os.path.join(acervo, fig["acervo"])
        out = os.path.join(dest, fig["arquivo"])
        if not os.path.isfile(src):
            print(f"FALTA   {fig['acervo']}", file=sys.stderr)
            faltam += 1
            continue
        if os.path.exists(out) and os.path.getmtime(out) >= os.path.getmtime(src):
            print(f"ok      {fig['arquivo']}")
            continue
        real = formato(src)
        if real == "pdf":
            if ext(out) != "png":
                sys.exit(f"{fig['arquivo']}: PDF só pode virar .png")
            subprocess.run(["pdftocairo", "-png", "-singlefile", "-r", "200",
                            src, os.path.splitext(out)[0]], check=True)
            print(f"pdf→png {fig['arquivo']}")
        else:
            shutil.copyfile(src, out)
            if real != ext(out):
                print(f"AVISO   {fig['arquivo']}: o conteúdo é {real}, mas a extensão é "
                      f".{ext(out)}. Corrija `arquivo` no YAML para .{real}.", file=sys.stderr)
            print(f"copiado {fig['arquivo']}")
        os.chmod(out, 0o644)
    if faltam:
        sys.exit(f"{faltam} figura(s) não encontradas no acervo")


if __name__ == "__main__":
    main(sys.argv)
