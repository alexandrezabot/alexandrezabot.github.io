#!/usr/bin/env bash
# coleta_site.sh — Coleta todas as informações do site Hugo para referência do Claude
# Uso: ./coleta_site.sh [diretório-do-site]
# Se não informar o diretório, usa o diretório atual.

set -euo pipefail

SITE_DIR="${1:-.}"
OUTPUT="site_info.txt"

# Verifica se parece um site Hugo
if [[ ! -f "$SITE_DIR/hugo.toml" && ! -f "$SITE_DIR/hugo.yaml" && ! -f "$SITE_DIR/hugo.json" && ! -f "$SITE_DIR/config.toml" && ! -f "$SITE_DIR/config.yaml" && ! -f "$SITE_DIR/config.json" ]]; then
    echo "ERRO: Nenhum arquivo de configuração Hugo encontrado em '$SITE_DIR'"
    echo "Informe o caminho do site: ./coleta_site.sh /caminho/do/site"
    exit 1
fi

cd "$SITE_DIR"
OUTPUT_PATH="$(pwd)/$OUTPUT"

{
    echo "============================================================"
    echo "INFORMAÇÕES DO SITE — $(date '+%Y-%m-%d %H:%M:%S')"
    echo "============================================================"
    echo ""

    # --- Sistema ---
    echo ">>> SISTEMA"
    uname -a
    echo ""

    # --- Versões ---
    echo ">>> VERSÕES"
    echo -n "Hugo: "; hugo version 2>/dev/null || echo "NÃO INSTALADO"
    echo -n "Go: "; go version 2>/dev/null || echo "NÃO INSTALADO"
    echo -n "Git: "; git --version 2>/dev/null || echo "NÃO INSTALADO"
    echo ""

    # --- Git ---
    echo ">>> GIT"
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        echo "Branch atual: $(git branch --show-current)"
        echo "Remotes:"
        git remote -v
        echo ""
        echo "Último commit:"
        git log -1 --oneline 2>/dev/null || echo "(sem commits)"
        echo ""
        echo "Branches:"
        git branch -a 2>/dev/null
    else
        echo "Não é um repositório git."
    fi
    echo ""

    # --- Configuração Hugo ---
    echo ">>> CONFIGURAÇÃO HUGO"
    for cfg in hugo.toml hugo.yaml hugo.json config.toml config.yaml config.json; do
        if [[ -f "$cfg" ]]; then
            echo "--- $cfg ---"
            cat "$cfg"
            echo ""
        fi
    done

    # Configs em config/_default/ (setup multi-ambiente)
    if [[ -d "config/_default" ]]; then
        echo "--- config/_default/ ---"
        for f in config/_default/*; do
            echo "--- $f ---"
            cat "$f"
            echo ""
        done
    fi
    echo ""

    # --- Tema ---
    echo ">>> TEMA"
    if [[ -f "go.mod" ]]; then
        echo "--- go.mod ---"
        cat go.mod
        echo ""
    fi
    if [[ -f ".hugo_build.lock" ]]; then
        echo "--- .hugo_build.lock ---"
        cat .hugo_build.lock
        echo ""
    fi
    # Temas em themes/
    if [[ -d "themes" ]]; then
        echo "Temas instalados em themes/:"
        ls -1 themes/ 2>/dev/null || echo "(vazio)"
        # Config do tema se existir
        for t in themes/*/; do
            if [[ -f "${t}theme.toml" ]]; then
                echo "--- ${t}theme.toml ---"
                cat "${t}theme.toml"
                echo ""
            fi
        done
    fi
    # .gitmodules (tema como submódulo)
    if [[ -f ".gitmodules" ]]; then
        echo "--- .gitmodules ---"
        cat .gitmodules
        echo ""
    fi
    echo ""

    # --- Estrutura de diretórios ---
    echo ">>> ESTRUTURA DO SITE"
    # Usa tree se disponível, senão find
    if command -v tree &>/dev/null; then
        tree -L 3 -I 'public|resources|node_modules|.git' --dirsfirst
    else
        find . -maxdepth 3 \
            -not -path './.git/*' \
            -not -path './public/*' \
            -not -path './resources/*' \
            -not -path './node_modules/*' \
            | sort
    fi
    echo ""

    # --- Conteúdo ---
    echo ">>> CONTEÚDO (arquivos .md)"
    find content/ -name '*.md' 2>/dev/null | sort || echo "(sem conteúdo)"
    echo ""

    # --- Layouts customizados ---
    echo ">>> LAYOUTS CUSTOMIZADOS"
    if [[ -d "layouts" ]]; then
        find layouts/ -type f 2>/dev/null | sort || echo "(vazio)"
    else
        echo "(sem diretório layouts/)"
    fi
    echo ""

    # --- Assets / Static ---
    echo ">>> ASSETS"
    if [[ -d "assets" ]]; then
        find assets/ -type f 2>/dev/null | head -50 | sort
        TOTAL_ASSETS=$(find assets/ -type f 2>/dev/null | wc -l)
        [[ $TOTAL_ASSETS -gt 50 ]] && echo "... (+$((TOTAL_ASSETS - 50)) arquivos)"
    else
        echo "(sem diretório assets/)"
    fi
    echo ""

    echo ">>> STATIC"
    if [[ -d "static" ]]; then
        find static/ -type f 2>/dev/null | head -50 | sort
        TOTAL_STATIC=$(find static/ -type f 2>/dev/null | wc -l)
        [[ $TOTAL_STATIC -gt 50 ]] && echo "... (+$((TOTAL_STATIC - 50)) arquivos)"
    else
        echo "(sem diretório static/)"
    fi
    echo ""

    # --- GitHub Actions ---
    echo ">>> GITHUB ACTIONS"
    if [[ -d ".github/workflows" ]]; then
        for wf in .github/workflows/*.yml .github/workflows/*.yaml; do
            [[ -f "$wf" ]] || continue
            echo "--- $wf ---"
            cat "$wf"
            echo ""
        done
    else
        echo "(sem workflows configurados)"
    fi
    echo ""

    # --- CNAME (GitHub Pages custom domain) ---
    echo ">>> CNAME"
    for cname in CNAME static/CNAME; do
        if [[ -f "$cname" ]]; then
            echo "--- $cname ---"
            cat "$cname"
            echo ""
        fi
    done
    echo ""

    # --- Netlify / Vercel (caso use) ---
    for f in netlify.toml vercel.json; do
        if [[ -f "$f" ]]; then
            echo ">>> $(echo $f | tr '[:lower:]' '[:upper:]')"
            cat "$f"
            echo ""
        fi
    done

    # --- package.json (se usar npm/tailwind/etc) ---
    if [[ -f "package.json" ]]; then
        echo ">>> PACKAGE.JSON"
        cat package.json
        echo ""
    fi

    # --- Resumo do build ---
    echo ">>> TESTE DE BUILD"
    if command -v hugo &>/dev/null; then
        hugo --gc --printPathWarnings 2>&1 | tail -5
    else
        echo "Hugo não instalado, build não testado."
    fi
    echo ""

    echo "============================================================"
    echo "Arquivo gerado em: $OUTPUT_PATH"
    echo "============================================================"

} > "$OUTPUT_PATH"

echo "Pronto. Informações salvas em: $OUTPUT_PATH"
echo "Anexe esse arquivo ao Claude quando quiser fazer alterações no site."
