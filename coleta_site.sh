#!/bin/bash
# coleta_site.sh — captura estado completo do site
# Uso: ./coleta_site.sh  →  gera site_info.txt

OUT="site_info.txt"

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

{
echo "============================================================"
echo "INFORMAÇÕES DO SITE — $(date '+%Y-%m-%d %H:%M:%S')"
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

echo ">>> CONFIGURAÇÃO HUGO"
dump_file "hugo.toml"

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

echo "============================================================"
echo "DUMP DOS ARQUIVOS"
echo "============================================================"
echo

echo "### TEMPLATES DO TEMA (inclui _default, partials, shortcodes, az) ###"
echo
find themes/profzabot-custom/layouts -name "*.html" 2>/dev/null | sort | dump_tree

echo "### CSS DO TEMA ###"
echo
find themes/profzabot-custom/static -name "*.css" 2>/dev/null | sort | dump_tree

echo "### LAYOUTS PROJETO (overrides) ###"
echo
find layouts -name "*.html" 2>/dev/null | sort | dump_tree

echo "### CONTEÚDO .md ###"
echo
find content -name "*.md" 2>/dev/null | sort | dump_tree

echo "### SCRIPT DE DEPLOY ###"
echo
dump_file "atualiza"

echo ">>> TESTE DE BUILD"
hugo --minify 2>&1 | tail -10
echo

echo "============================================================"
echo "Arquivo gerado em: $(pwd)/$OUT"
echo "============================================================"

} > "$OUT"

echo "OK: $OUT gerado ($(wc -l < $OUT) linhas, $(du -h $OUT | cut -f1))."
