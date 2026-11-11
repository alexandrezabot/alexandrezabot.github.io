#!/bin/bash
# coleta_site.sh — captura estado completo do site
# Uso: ./coleta_site.sh  →  gera site_info.txt

OUT="site_info.txt"
SITE="https://www.profzabot.com.br"

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

{
echo "============================================================"
echo "INFORMAÇÕES DO SITE — $(command date '+%Y-%m-%d %H:%M:%S')"
echo "============================================================"
echo

echo ">>> SISTEMA"
uname -a
echo

echo ">>> VERSÕES"
echo "Hugo: $(hugo version)"
echo "Go: $(go version 2>/dev/null || echo 'não instalado')"
echo "Git: $(git --version)"
echo

echo ">>> GIT"
echo "Branch atual: $(git branch --show-current)"
echo
echo "Remotes:"
git remote -v
echo
echo "Último commit:"
git log -1 --oneline
echo
echo "Branches:"
git branch -a
echo
echo "Submódulos:"
git submodule status 2>/dev/null || echo "(nenhum)"
echo
echo "Alterações não commitadas:"
git status --short
echo

echo ">>> CONFIGURAÇÃO HUGO"
dump_file "hugo.toml"

echo ">>> CSS DO PROJETO"
find static/css -name "*.css" 2>/dev/null | sort | dump_tree

echo ">>> ESTRUTURA DO SITE"
find . \
    -not -path './.git*' \
    -not -path './public*' \
    -not -path './resources*' \
    -not -path './node_modules*' \
    | sort
echo

echo ">>> STATIC (arquivos)"
find static -type f 2>/dev/null | sort
echo

echo ">>> GITHUB ACTIONS"
dump_file ".github/workflows/deploy.yml"

echo ">>> CNAME"
dump_file "static/CNAME"

echo ">>> ROBOTS.TXT"
dump_file "static/robots.txt"

echo ">>> GITIGNORE"
dump_file ".gitignore"

echo ">>> ARCHETYPES"
find archetypes -name "*.md" 2>/dev/null | sort | dump_tree

echo ">>> SIMULAÇÕES ESTÁTICAS (primeiras 20 linhas de cada)"
for f in $(find static/recursos -path "*/sim/index.html" 2>/dev/null | sort); do
    echo "--- $f ---"
    head -20 "$f"
    echo
done

echo "============================================================"
echo "DUMP DOS ARQUIVOS"
echo "============================================================"
echo

echo "### TEMPLATES DO TEMA (inclui _default, partials, shortcodes, az) ###"
echo
find themes/profzabot-custom/layouts \( -name "*.html" -o -name "*.xml" \) 2>/dev/null | sort | dump_tree

echo "### CSS DO TEMA ###"
echo
find themes/profzabot-custom/static -name "*.css" 2>/dev/null | sort | dump_tree

echo "### LAYOUTS PROJETO (overrides, inclui sitemap.xml) ###"
echo
find layouts \( -name "*.html" -o -name "*.xml" \) 2>/dev/null | sort | dump_tree

echo "### CONTEÚDO .md ###"
echo
find content -name "*.md" 2>/dev/null | sort | dump_tree

echo "### SCRIPTS (deploy e novo recurso) ###"
echo
dump_file "atualiza"
dump_file "novo_recurso"

echo ">>> TESTE DE BUILD"
rm -rf public
hugo --minify 2>&1 | tail -10
echo

echo ">>> BUILD LOCAL: SEO"
echo "URLs no sitemap:            $(grep -o '<loc>' public/sitemap.xml 2>/dev/null | wc -l)"
echo "Páginas com noindex:        $(grep -rlE 'name="?robots"? content="?noindex' public --include='*.html' 2>/dev/null | wc -l)"
echo "Conceitos com noindex:      $(grep -rl 'noindex' public/az/conceito --include='*.html' 2>/dev/null | wc -l)"
echo "Links ?tag= restantes:      $(grep -rl '?tag=' public --include='*.html' 2>/dev/null | wc -l)"
echo "Links internos sem barra:   $(grep -rhoE 'href="/(ensino|livros|az|recursos|sobre|contato)"' public --include='*.html' 2>/dev/null | wc -l)"
echo

echo ">>> SITE NO AR: STATUS HTTP"
for u in \
    "$SITE/" \
    "$SITE/az" \
    "$SITE/az/" \
    "$SITE/ensino" \
    "$SITE/recursos/" \
    "$SITE/recursos/fermi/sim/" \
    "$SITE/recursos/fermi/sim/index.html" \
    "$SITE/fermi/" \
    "$SITE/audios/" \
    "$SITE/pagina-que-nao-existe/" \
    "https://profzabot.com.br/" \
    "http://www.profzabot.com.br/" \
    "https://alexandrezabot.github.io/" ; do
    status_url "$u"
done
echo

echo ">>> SITE NO AR: META ROBOTS E CANONICAL"
for p in / /az/ /recursos/ /recursos/fermi/sim/ /fermi/ /audios/; do
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

echo "============================================================"
echo "Arquivo gerado em: $(pwd)/$OUT"
echo "============================================================"

} > "$OUT"

echo "OK: $OUT gerado ($(wc -l < $OUT) linhas, $(du -h $OUT | cut -f1))."
