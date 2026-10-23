#!/usr/bin/env python3
"""Carrossel panorâmico: uma única linha do tempo atravessa todos os slides.

Uso: python3 gerar.py [eventos.yaml] [pasta_de_saida]
Os textos e as figuras vêm do eventos.yaml, o mesmo que o site usa.

Cada slide contém o panorama inteiro (N x 1080 px) deslocado de -k*1080 px,
de modo que a linha, os marcadores e as hastes casam exatamente na emenda.
"""
import html
import os
import re
import sys

W, H = 1080, 1350
LINE_Y = 700
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "saida")
PREFIX = "slide_particulas_descobertas_p1_linhadotempo"

C = dict(noite="#040d29", indigo="#6168B9", lavanda="#A7B0EB", coral="#FD8354",
         pessego="#F9BCAA", creme="#E8E0D0", mudo="#A69E8E")
COR = {"exp": C["coral"], "teo": C["lavanda"], "astro": C["pessego"]}

def _ler(caminho):
    import yaml
    with open(caminho, encoding="utf-8") as f:
        return yaml.safe_load(f)


YML = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "../../content/recursos/linha-do-tempo-particulas/eventos.yaml")
if len(sys.argv) > 2:
    OUT = sys.argv[2]
DADOS = _ler(YML)

# (ano, tipo, título, texto)
EV = [(str(e["ano"]), e["tipo"], e["titulo"], e["texto"]) for e in DADOS["eventos"]]

N = 14
SLOT_UP, SLOT_DN = 96, 520          # posição local das hastes
UP_W, DN_W = 640, 496               # largura das caixas
UP_BOTTOM, DN_TOP = 630, 770        # limites das caixas em relação à linha

# Figuras: slide (índice 0..13) -> (dono "L"/"R"/"Lw", arquivo em figuras/, legenda)
# Derivado do YAML: no slide k (1..12) ficam os eventos 2k-1 (L) e 2k (R), e só um
# deles tem figura. O slide 13 tem só o último evento.
FIG = {}
for k in range(1, 14):
    idx = [2 * k - 1, 2 * k] if k < 13 else [len(EV) - 1]
    com = [i for i in idx if "figura" in DADOS["eventos"][i]]
    assert len(com) == 1, f"slide {k}: precisa de exatamente uma figura, tem {len(com)}"
    i = com[0]
    f = DADOS["eventos"][i]["figura"]
    dono = "R" if (k < 13 and i == 2 * k) else ("Lw" if f.get("carrossel") == "larga" else "L")
    FIG[k] = (dono, f["arquivo"], f["legenda"])

# Posições: lista (slide, x local, lado, largura) por evento, na ordem de EV.
pos = [(0, SLOT_DN, "dn", DN_W)]
for k in range(1, 13):
    dono = FIG[k][0]
    if dono == "L":   # L em cima e largo, figura embaixo de L, R embaixo à direita
        pos += [(k, SLOT_UP, "up", UP_W), (k, SLOT_DN, "dn", DN_W)]
    elif dono == "R":  # os dois cards em cima, figura embaixo de R
        pos += [(k, SLOT_UP, "up", SLOT_DN - SLOT_UP - 24), (k, SLOT_DN, "up", DN_W)]
    else:              # "Lw": os dois cards em cima, figura de L em largura total embaixo
        pos += [(k, SLOT_UP, "up", 600 - SLOT_UP - 24), (k, 600, "up", W - 64 - 600)]
pos.append((13, SLOT_UP, "up", UP_W))
assert len(pos) == len(EV)

LINE_START = 64
SOLID_END = 13 * W + 400
DASH_END = 13 * W + 940
Q_X = 13 * W + 975


def marker(x, tipo):
    y = LINE_Y
    if tipo == "exp":
        return (f'<circle cx="{x}" cy="{y}" r="13" fill="{C["coral"]}" '
                f'stroke="{C["noite"]}" stroke-width="4"/>')
    if tipo == "teo":
        return (f'<rect x="{x-11}" y="{y-11}" width="22" height="22" fill="{C["noite"]}" '
                f'stroke="{C["lavanda"]}" stroke-width="4" transform="rotate(45 {x} {y})"/>')
    return star(x, y, 19, C["pessego"])


def star(x, y, r, cor, sw=2):
    import math
    pts = []
    for i in range(10):
        rr = r if i % 2 == 0 else r * 0.45
        a = -math.pi / 2 + i * math.pi / 5
        pts.append(f"{x + rr*math.cos(a):.1f},{y + rr*math.sin(a):.1f}")
    return f'<polygon points="{" ".join(pts)}" fill="{cor}" stroke="{C["noite"]}" stroke-width="{sw}"/>'


def panorama():
    svg = [f'<svg class="pano-svg" width="{N*W}" height="{H}" viewBox="0 0 {N*W} {H}">']
    svg.append(f'<line x1="{LINE_START}" y1="{LINE_Y}" x2="{SOLID_END}" y2="{LINE_Y}" '
               f'stroke="{C["indigo"]}" stroke-width="8" stroke-linecap="round"/>')
    svg.append(f'<line x1="{SOLID_END+24}" y1="{LINE_Y}" x2="{DASH_END}" y2="{LINE_Y}" '
               f'stroke="{C["indigo"]}" stroke-width="8" stroke-dasharray="20 16" '
               f'stroke-linecap="round"/>')
    cards = []
    for (k, xl, side, wd), (ano, tipo, tit, txt) in zip(pos, EV):
        x = k * W + xl
        cor = COR[tipo]
        if side == "up":
            style = f"left:{x-1.5}px;bottom:{H-UP_BOTTOM}px;width:{wd}px;border-color:{cor}"
        else:
            style = f"left:{x-1.5}px;top:{DN_TOP}px;width:{wd}px;border-color:{cor}"
        cards.append(
            f'<div class="card {side}" style="{style}">'
            f'<div class="ano" style="color:{cor}">{ano}</div>'
            f'<div class="tit">{html.escape(tit)}</div>'
            f'<div class="txt">{html.escape(txt)}</div></div>')
    # figuras: sempre abaixo da linha, penduradas no marcador do evento dono
    for k, (dono, cam, leg) in FIG.items():
        i = (2 * k - 1 if dono in ("L", "Lw") else 2 * k) if k < 13 else len(EV) - 1
        x = k * W + pos[i][1]
        cor = COR[EV[i][1]]
        wd = {"L": SLOT_DN - SLOT_UP - 24, "R": DN_W, "Lw": W - 64 - SLOT_UP}[dono]
        hmax = 320 if k == 13 else 440
        nome = cam
        cards.append(
            f'<div class="fig" style="left:{x-1.5}px;top:{DN_TOP}px;width:{wd}px;border-color:{cor}">'
            f'<div class="moldura" style="--h:{hmax}px">'
            f'<img src="figuras/{nome}" alt="" onerror="this.parentNode.classList.add(\'falta\')">'
            f'<span class="nome">figuras/{html.escape(nome)}</span></div>'
            f'<div class="cred">{html.escape(leg)}</div></div>')
    # marcadores por cima da linha (as hastes são o ::after de cada card, para casar com a borda)
    for (k, xl, _, _), (_, tipo, _, _) in zip(pos, EV):
        svg.append(marker(k * W + xl, tipo))
    # final: interrogação do "o que falta"
    xq = 13 * W + SLOT_DN
    svg.append(f'<circle cx="{xq}" cy="{LINE_Y}" r="11" fill="{C["noite"]}" '
               f'stroke="{C["indigo"]}" stroke-width="4"/>')
    svg.append(f'<text x="{Q_X}" y="{LINE_Y+24}" font-family="Cormorant Garamond, Georgia, serif" '
               f'font-style="italic" font-weight="600" font-size="72" fill="{C["lavanda"]}">?</text>')
    svg.append("</svg>")
    cards.append(
        f'<div class="card dn" style="left:{xq-1.5}px;top:{DN_TOP}px;width:{W*14 - xq - 64}px;'
        f'border-color:{C["indigo"]};border-left-style:dashed">'
        f'<div class="ano" style="color:{C["indigo"]}">{html.escape(DADOS["fim"]["rotulo"])}</div>'
        f'<div class="tit">{html.escape(DADOS["fim"]["titulo"])}</div>'
        f'<div class="txt">{html.escape(DADOS["fim"]["texto"])}</div></div>')
    return "\n".join(svg) + "\n" + "\n".join(cards)


CAPA = f"""
<div class="capa">
  <div class="label">{html.escape(DADOS['rotulo'])}</div>
  <h1>{html.escape(DADOS['titulo'])}</h1>
  <div class="sep"></div>
  <div class="sub">{html.escape(DADOS['subtitulo'])}</div>
</div>
<div class="legenda">
  <div><svg width="40" height="40"><circle cx="20" cy="20" r="13" fill="{C['coral']}"/></svg>descoberta experimental</div>
  <div><svg width="40" height="40"><rect x="9" y="9" width="22" height="22" fill="{C['noite']}" stroke="{C['lavanda']}" stroke-width="4" transform="rotate(45 20 20)"/></svg>previsão teórica</div>
  <div><svg width="40" height="40">{star(20, 20, 19, C['pessego'], 0)}</svg>Astrofísica</div>
</div>
"""

REFS = ('\n<div class="refs">\n  <div class="sep"></div>\n'
        + "".join("  <div>" + re.sub(r"\*(.+?)\*", r"<i>\1</i>", html.escape(r)) + "</div>\n"
                  for r in DADOS["referencias"])
        + "</div>\n")

HEAD = f"""<!DOCTYPE html>
<html lang="pt-BR"><head><meta charset="utf-8">
<title>{{titulo}}</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,600;1,500;1,600&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
<style>
*{{margin:0;padding:0;box-sizing:border-box}}
html,body{{width:{W}px;height:{H}px;background:{C['noite']};overflow:hidden}}
.canvas{{position:relative;width:{W}px;height:{H}px;overflow:hidden;background:{C['noite']}}}
.topo{{position:absolute;left:0;top:0;width:100%;height:4px;background:{C['indigo']};z-index:5}}
.pano{{position:absolute;top:0;width:{N*W}px;height:{H}px}}
.pano-svg{{position:absolute;left:0;top:0}}
.card{{position:absolute;border-left:3px solid;padding-left:26px}}
.card.up{{padding-bottom:4px}}
.ano{{font:600 36px/1 Inter,sans-serif;letter-spacing:1px;margin-bottom:10px}}
.tit{{font:italic 500 54px/1.05 'Cormorant Garamond',Georgia,serif;color:{C['creme']};margin-bottom:14px}}
.txt{{font:400 30px/1.4 Inter,sans-serif;color:{C['creme']};opacity:.92}}
.fig{{position:absolute;border-left:3px solid;padding-left:26px}}
.moldura{{position:relative;width:100%;display:flex;align-items:flex-start}}
.moldura img{{max-width:100%;max-height:var(--h);object-fit:contain;display:block}}
.moldura .nome{{display:none}}
.moldura.falta{{height:var(--h);border:3px dashed {C['indigo']};align-items:center;justify-content:center}}
.moldura.falta img{{display:none}}
.moldura.falta .nome{{display:block;font:400 24px/1.3 Inter,sans-serif;color:{C['mudo']};padding:20px;word-break:break-all}}
.cred{{font:400 22px/1.35 Inter,sans-serif;color:{C['coral']};margin-top:12px}}
.card::after,.fig::after{{content:"";position:absolute;left:-3px;border-left:3px solid;border-left-color:inherit;border-left-style:inherit}}
.card.up::after{{top:100%;height:{LINE_Y-UP_BOTTOM-10}px}}
.card.dn::after,.fig::after{{bottom:100%;height:{DN_TOP-LINE_Y-10}px}}
.capa{{position:absolute;left:64px;top:90px;width:952px}}
.label{{font:500 30px/1 Inter,sans-serif;letter-spacing:3px;text-transform:uppercase;color:{C['indigo']};margin-bottom:34px}}
h1{{font:italic 500 76px/1.05 'Cormorant Garamond',Georgia,serif;color:{C['creme']}}}
.sep{{width:50px;height:2px;background:{C['indigo']};margin:34px 0}}
.sub{{font:600 44px/1.2 'Cormorant Garamond',Georgia,serif;color:{C['pessego']}}}
.legenda{{position:absolute;left:64px;top:800px;font:400 27px/1 Inter,sans-serif;color:{C['creme']}}}
.legenda div{{display:flex;align-items:center;gap:16px;margin-bottom:22px}}
.refs{{position:absolute;left:64px;bottom:64px;width:952px;font:400 24px/1.45 Inter,sans-serif;color:{C['coral']}}}
.refs .sep{{margin:0 0 18px}}
</style></head><body><div class="canvas"><div class="topo"></div>
"""


def main():
    os.makedirs(OUT, exist_ok=True)
    pano = panorama()
    for k in range(N):
        extra = CAPA if k == 0 else (REFS if k == N - 1 else "")
        doc = (HEAD.replace("{titulo}", f"Linha do tempo das partículas {k+1:02d}/{N}")
               + f'<div class="pano" style="left:{-k*W}px">\n{pano}\n</div>\n{extra}'
               + "</div></body></html>\n")
        with open(os.path.join(OUT, f"{PREFIX}_{k+1:02d}.html"), "w", encoding="utf-8") as f:
            f.write(doc)
    print("ok", N, "slides")


if __name__ == "__main__":
    main()
