#!/bin/bash
# coleta_site.sh — captura estado completo do site
# Uso: ./coleta_site.sh  →  gera site_info.txt
# Diagnóstico primeiro, dump dos arquivos depois. Índice com números de linha no topo.

OUT="site_info.txt"
SITE="https://www.profzabot.com.br"
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

dump_file() {
    if [ -f "$1" ]; then
        echo "--- $1 ---"
        cat "$1"
        echo
    fi
}

dump_tree() {
    while IFS= read -r f; do
        dump_file "$f"
    done
}

# status HTTP e destino de redirecionamento de uma URL
status_url() {
    curl -s -o /dev/null --max-time 15 \
         -w "%{http_code}  %{url_effective}  ->  %{redirect_url}\n" "$1"
}

sec() {
    echo ">>> $1"
}

{
# ============================================================
# PARTE 1 — DIAGNÓSTICO
# ============================================================

sec "GIT"
git fetch -q origin 2>/dev/null
echo "Branch atual: $(git branch --show-current)"
echo
echo "Alterações não commitadas:"
git status --short
echo
echo "Commits locais ainda não enviados (origin/main..HEAD):"
git log --oneline origin/main..HEAD 2>/dev/null
echo
echo "Últimos 5 commits (data local):"
git log -5 --date=format:'%Y-%m-%d %H:%M' --format='%h  %ad  %s'
echo
echo "Último deploy em gh-pages:"
git log -1 --date=format:'%Y-%m-%d %H:%M' --format='%h  %ad  %s' origin/gh-pages 2>/dev/null
echo
echo "Remotes:"
git remote -v
echo
echo "Branches:"
git branch -a
echo
echo "Submódulos:"
git submodule status 2>/dev/null || echo "(nenhum)"
echo

sec "PUBLICAÇÃO (o que o Hugo deixa de fora)"
echo "Agora: $(date '+%Y-%m-%d %H:%M %Z')  |  UTC: $(date -u '+%Y-%m-%d %H:%M')"
echo
echo "Posts com data futura (hugo list future):"
hugo list future 2>&1
echo
echo "Rascunhos (hugo list drafts):"
hugo list drafts 2>&1
echo
echo "Expirados (hugo list expired):"
hugo list expired 2>&1
echo

sec "TESTE DE BUILD"
rm -rf public
hugo --minify 2>&1 | tail -10
echo

sec "BUILD LOCAL: SEO"
echo "URLs no sitemap:            $(grep -o '<loc>' public/sitemap.xml 2>/dev/null | wc -l)"
echo "Páginas com noindex:        $(grep -rlE 'name="?robots"? content="?noindex' public --include='*.html' 2>/dev/null | wc -l)"
echo "Conceitos com noindex:      $(grep -rl 'noindex' public/az/conceito --include='*.html' 2>/dev/null | wc -l)"
echo "Links ?tag= restantes:      $(grep -rl '?tag=' public --include='*.html' 2>/dev/null | wc -l)"
echo "Links internos sem barra:   $(grep -rhoE 'href="/(ensino|livros|az|laboratorio|sobre|contato)"' public --include='*.html' 2>/dev/null | wc -l)"
echo "HTML cru omitido (goldmark): $(grep -rl 'raw HTML omitted' public --include='*.html' 2>/dev/null | wc -l)"
grep -rl 'raw HTML omitted' public --include='*.html' 2>/dev/null | sed 's/^/    /'
echo

sec "SITE NO AR: STATUS HTTP"
ULTIMA=$(ls content/az/[0-9]*.md 2>/dev/null | sort -V | tail -1)
ULTIMA=$(basename "$ULTIMA" .md)
echo "Última edição do boletim no repositório: $ULTIMA"
for u in \
    "$SITE/" \
    "$SITE/az" \
    "$SITE/az/" \
    "$SITE/az/$ULTIMA/" \
    "$SITE/ensino" \
    "$SITE/laboratorio/" \
    "$SITE/laboratorio/fermi/sim/" \
    "$SITE/laboratorio/fermi/sim/index.html" \
    "$SITE/recursos/" \
    "$SITE/recursos/fermi/sim/" \
    "$SITE/fermi/" \
    "$SITE/audios/" \
    "$SITE/pagina-que-nao-existe/" \
    "https://profzabot.com.br/" \
    "http://www.profzabot.com.br/" \
    "https://alexandrezabot.github.io/" ; do
    status_url "$u"
done
echo

sec "SITE NO AR: META ROBOTS E CANONICAL"
for p in / /az/ /laboratorio/ /laboratorio/fermi/sim/ /recursos/ /recursos/fermi/sim/ /fermi/ /audios/; do
    html=$(curl -s --max-time 15 "$SITE$p")
    echo "$p"
    echo "  robots:    $(echo "$html" | grep -oE '<meta name="?robots"?[^>]*>' | head -1)"
    echo "  canonical: $(echo "$html" | grep -oE '<link rel="?canonical"?[^>]*>' | head -1)"
done
echo
echo "robots.txt no ar:"
curl -s --max-time 15 "$SITE/robots.txt"
echo
echo "URLs no sitemap no ar: $(curl -s --max-time 15 "$SITE/sitemap.xml" | grep -o '<loc>' | wc -l)"
echo

# ============================================================
# PARTE 2 — CONFIGURAÇÃO
# ============================================================

sec "SISTEMA E VERSÕES"
uname -a
echo "Hugo: $(hugo version)"
echo "Go: $(go version 2>/dev/null || echo 'não instalado')"
echo "Git: $(git --version)"
echo

sec "CONFIGURAÇÃO HUGO"
dump_file "hugo.toml"

sec "DEPLOY (GitHub Actions, CNAME, robots, gitignore, scripts)"
dump_file ".github/workflows/deploy.yml"
dump_file "static/CNAME"
dump_file "static/robots.txt"
dump_file ".gitignore"
dump_file "atualiza"
dump_file "novo_recurso"

sec "ESTRUTURA DO SITE"
find . \
    -not -path './.git*' \
    -not -path './public*' \
    -not -path './resources*' \
    -not -path './node_modules*' \
    | sort
echo

sec "STATIC (arquivos)"
find static -type f 2>/dev/null | sort
echo

sec "ARCHETYPES"
find archetypes -name "*.md" 2>/dev/null | sort | dump_tree

sec "SIMULAÇÕES ESTÁTICAS (primeiras 20 linhas de cada)"
for f in $(find static/laboratorio -path "*/sim/index.html" 2>/dev/null | sort); do
    echo "--- $f ---"
    head -20 "$f"
    echo
done

# ============================================================
# PARTE 3 — DUMP DOS ARQUIVOS
# ============================================================

sec "CSS DO PROJETO"
find static/css -name "*.css" 2>/dev/null | sort | dump_tree

sec "TEMPLATES DO TEMA (inclui _default, partials, shortcodes, az)"
find themes/profzabot-custom/layouts \( -name "*.html" -o -name "*.xml" \) 2>/dev/null | sort | dump_tree

sec "CSS DO TEMA"
find themes/profzabot-custom/static -name "*.css" 2>/dev/null | sort | dump_tree

sec "LAYOUTS DO PROJETO (overrides, inclui sitemap.xml)"
find layouts \( -name "*.html" -o -name "*.xml" \) 2>/dev/null | sort | dump_tree

sec "CONTEÚDO .md"
find content -name "*.md" 2>/dev/null | sort -V | dump_tree

} > "$TMP"

# ---------- cabeçalho + índice com números de linha do arquivo final ----------
mapfile -t SECOES < <(grep -n '^>>> ' "$TMP")
H=$(( 3 + 1 + 1 + ${#SECOES[@]} + 1 ))   # 3 linhas de título, branco, "ÍNDICE", entradas, branco

{
echo "============================================================"
echo "INFORMAÇÕES DO SITE — $(command date '+%Y-%m-%d %H:%M:%S')"
echo "============================================================"
echo
echo "ÍNDICE (linha no arquivo · seção)"
for s in "${SECOES[@]}"; do
    n=${s%%:*}
    t=${s#*:>>> }
    printf "  %6d  %s\n" $(( n + H )) "$t"
done
echo
cat "$TMP"
echo "============================================================"
echo "Arquivo gerado em: $(pwd)/$OUT"
echo "============================================================"
} > "$OUT"

echo "OK: $OUT gerado ($(wc -l < "$OUT") linhas, $(du -h "$OUT" | cut -f1))."
