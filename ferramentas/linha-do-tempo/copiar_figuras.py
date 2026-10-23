#!/usr/bin/env python3
"""Copia do acervo as figuras listadas no eventos.yaml.

Uso:
    python3 copiar_figuras.py EVENTOS.yaml [DESTINO] [--acervo PASTA]

    EVENTOS.yaml  o arquivo de dados da linha do tempo
    DESTINO       pasta onde as figuras vão ficar. Sem ele, usa figuras/ ao lado
                  do EVENTOS.yaml, que é o lugar certo para o site. Para o
                  carrossel, passe saida/figuras.
    --acervo      raiz do acervo (padrão /home/zabot/midia). Os caminhos
                  `figura.acervo` do YAML são relativos a ela.

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


ACERVO_PADRAO = "/home/zabot/midia"


def main(argv):
    args = argv[1:]
    acervo = ACERVO_PADRAO
    if "--acervo" in args:
        k = args.index("--acervo")
        acervo = args[k + 1]
        del args[k:k + 2]
    if not 1 <= len(args) <= 2 or args[0] in ("-h", "--help"):
        sys.exit(__doc__)
    yml = args[0]
    dest = args[1] if len(args) == 2 else os.path.join(os.path.dirname(os.path.abspath(yml)), "figuras")
    if not os.path.isdir(acervo):
        sys.exit(f"Acervo não encontrado: {acervo}")
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
