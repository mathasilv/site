#!/usr/bin/env bash
#
# new-post.sh — ferramenta rápida para criar e gerenciar posts no site.
#
# USO:
#   ./new-post.sh "Título do Post" [slug]        # criar post
#   ./new-post.sh --list                          # listar posts (JSON)
#   ./new-post.sh --sync                          # sincronizar posts.json com arquivos
#   ./new-post.sh --validate                       # validar integridade
#   ./new-post.sh --open slug                     # abrir post no editor
#
# O script mantém posts/posts.json sincronizado automaticamente.
# O slug deve conter apenas [a-z0-9-].

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
POSTS_DIR="$SCRIPT_DIR/posts"
TEMPLATE="$POSTS_DIR/_template.html"
POSTS_JSON="$POSTS_DIR/posts.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

today() {
  date +%Y-%m-%d
}

validate_slug() {
  local slug="$1"
  if [[ ! "$slug" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
    echo -e "${RED}ERRO: slug inválido: '$slug'${NC}"
    echo "  Slug deve conter apenas [a-z0-9-], começar com letra/número."
    exit 1
  fi
}

ensure_json() {
  if [ ! -f "$POSTS_JSON" ]; then
    echo "[]" > "$POSTS_JSON"
  fi
}

slug_from_title() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//' | cut -c1-40
}

# ---------------------------------------------------------------
# CRIAR POST
# ---------------------------------------------------------------
cmd_create() {
  local title="$1"
  local slug="${2:-}"
  local today_str
  today_str="$(today)"

  [ -z "$slug" ] && slug="$(slug_from_title "$title")"
  validate_slug "$slug"

  local html_file="$POSTS_DIR/$slug.html"
  if [ -f "$html_file" ]; then
    echo -e "${YELLOW}AVISO: $slug.html já existe — pulando criação do HTML.${NC}"
  else
    if [ ! -f "$TEMPLATE" ]; then
      echo -e "${RED}ERRO: template não encontrado: $TEMPLATE${NC}"
      exit 1
    fi
    # Copiar template e substituir placeholders
    sed \
      -e "s|TÍTULO DO POST|$title|g" \
      -e "s|DATA: 2025-12-26|DATA: $today_str|g" \
      -e "s|Seu texto aqui.|Escreva o conteúdo do post aqui.|g" \
      "$TEMPLATE" > "$html_file"
    echo -e "${GREEN}Criado: $html_file${NC}"
  fi

  # Verificar se já existe no JSON
  ensure_json
  if python3 -c "
import json, sys
posts = json.load(open('$POSTS_JSON'))
if any(p.get('id') == '$slug' for p in posts):
    sys.exit(1)
sys.exit(0)
" 2>/dev/null; then
    # Adicionar ao JSON usando python3
    python3 -c "
import json
posts = json.load(open('$POSTS_JSON'))
posts.append({
    'id': '$slug',
    'title': '$title',
    'date': '$today_str',
    'excerpt': 'Breve descrição do post.'
})
posts.sort(key=lambda p: p.get('date', ''), reverse=True)
json.dump(posts, open('$POSTS_JSON', 'w'), indent=2, ensure_ascii=False)
"
    echo -e "${GREEN}Adicionado ao posts.json: $slug${NC}"
  else
    echo -e "${YELLOW}Já existe no posts.json: $slug${NC}"
  fi

  echo ""
  echo -e "${CYAN}Próximos passos:${NC}"
  echo "  1. Edite o conteúdo:  $html_file"
  echo "  2. Atualize o excerpt em: $POSTS_JSON"
  echo "  3. Adicione fotos em: $SCRIPT_DIR/photos/"
  echo ""
  echo -e "${CYAN}Dica: abra direto com:${NC}"
  echo "  ./new-post.sh --open $slug"
}

# ---------------------------------------------------------------
# LISTAR POSTS
# ---------------------------------------------------------------
cmd_list() {
  ensure_json
  python3 -c "
import json
posts = json.load(open('$POSTS_JSON'))
posts.sort(key=lambda p: p.get('date', ''), reverse=True)
for i, p in enumerate(posts, 1):
    print(f\"  {i:2d}. [{p['date']}] {p['title']}\")
    print(f\"      slug: {p['id']}\")
    print(f\"      arquivo: posts/{p['id']}.html\")
    print()
"
}

# ---------------------------------------------------------------
# VALIDAR INTEGRIDADE
# ---------------------------------------------------------------
cmd_validate() {
  ensure_json
  local errors=0

  echo -e "${CYAN}Validando posts...${NC}"
  echo ""

  # 1. Verificar arquivos HTML mencionados no JSON
  python3 -c "
import json, os
posts = json.load(open('$POSTS_JSON'))
for p in posts:
    path = os.path.join('$POSTS_DIR', p['id'] + '.html')
    exists = os.path.isfile(path)
    status = 'OK' if exists else 'FALTANDO'
    print(f'  [{status}] {p[\"id\"]:30s}  {\"posts/\" + p[\"id\"] + \".html\"}')
    if not exists:
        exit(1)
"

  echo ""

  # 2. Verificar HTMLs que não estão no JSON
  echo -e "${CYAN}Verificando HTMLs órfãos...${NC}"
  local orphans=0
  for f in "$POSTS_DIR"/*.html; do
    local base
    base="$(basename "$f" .html)"
    [ "$base" = "_template" ] && continue
    if ! python3 -c "
import json, sys
posts = json.load(open('$POSTS_JSON'))
if not any(p['id'] == '$base' for p in posts):
    sys.exit(1)
" 2>/dev/null; then
      echo -e "  ${YELLOW}ÓRFÃO: posts/$base.html existe mas não está no posts.json${NC}"
      orphans=$((orphans + 1))
      errors=$((errors + 1))
    fi
  done

  echo ""

  # 3. Verificar referências a fotos
  echo -e "${CYAN}Verificando fotos referenciadas nos posts...${NC}"
  python3 -c "
import os, re
photos_dir = '$SCRIPT_DIR/photos'
for f in os.listdir('$POSTS_DIR'):
    if not f.endswith('.html') or f == '_template.html':
        continue
    content = open(os.path.join('$POSTS_DIR', f)).read()
    refs = re.findall(r'src=\"\.\./photos/([^\"]+)\"', content)
    for ref in refs:
        path = os.path.join(photos_dir, ref)
        status = 'OK' if os.path.isfile(path) else 'FALTANDO'
        print(f'  [{status}] {f} -> photos/{ref}')
" 2>/dev/null || true

  echo ""

  if [ $errors -eq 0 ]; then
    echo -e "${GREEN}Tudo OK!${NC}"
  else
    echo -e "${YELLOW}Encontrados $errors problema(s).${NC}"
  fi
}

# ---------------------------------------------------------------
# SINCRONIZAR posts.json
# ---------------------------------------------------------------
cmd_sync() {
  ensure_json
  python3 -c "
import json, os

posts_dir = '$POSTS_DIR'
json_path = '$POSTS_JSON'

posts = json.load(open(json_path)) if os.path.isfile(json_path) else []
existing_ids = {p['id'] for p in posts}

# Adicionar HTMLs que não estão no JSON
added = 0
for f in sorted(os.listdir(posts_dir)):
    if not f.endswith('.html') or f == '_template.html':
        continue
    slug = f[:-5]
    if slug not in existing_ids:
        posts.append({
            'id': slug,
            'title': slug.upper().replace('-', ' '),
            'date': '$(today)',
            'excerpt': 'Breve descrição do post.'
        })
        print(f'  + adicionado: {slug}')
        added += 1

posts.sort(key=lambda p: p.get('date', ''), reverse=True)
json.dump(posts, open(json_path, 'w'), indent=2, ensure_ascii=False)

if added == 0:
    print('  Nenhum post novo. Tudo sincronizado.')
else:
    print(f'  {added} post(s) adicionado(s).')
"

  echo ""
  cmd_validate
}

# ---------------------------------------------------------------
# ABRIR POST NO EDITOR
# ---------------------------------------------------------------
cmd_open() {
  local slug="$1"
  validate_slug "$slug"
  local html_file="$POSTS_DIR/$slug.html"

  if [ ! -f "$html_file" ]; then
    echo -e "${RED}ERRO: post não encontrado: $html_file${NC}"
    echo "  Execute primeiro: ./new-post.sh \"Título\" $slug"
    exit 1
  fi

  # Tentar abrir no editor do usuário
  local editor="${EDITOR:-${VISUAL:-nano}}"
  if command -v "$editor" &>/dev/null; then
    exec "$editor" "$html_file"
  else
    echo -e "${YELLOW}Editor não encontrado. Abra manualmente:${NC}"
    echo "  $html_file"
  fi
}

# ---------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------
usage() {
  cat <<EOF
new-post.sh — gerenciador de posts do site

USO:
  ./new-post.sh "Título" [slug]     Criar novo post (slug automático se omitido)
  ./new-post.sh --list              Listar todos os posts
  ./new-post.sh --sync              Sincronizar posts.json com arquivos HTML
  ./new-post.sh --validate          Validar integridade (JSON ↔ HTML ↔ fotos)
  ./new-post.sh --open slug         Abrir post no editor ($EDITOR)

EXEMPLOS:
  ./new-post.sh "Meu Novo Projeto"
  ./new-post.sh "NPA Ground Station v6" npags-v6
  ./new-post.sh --list
  ./new-post.sh --validate

ARQUIVOS:
  posts/posts.json    Manifesto (JSON) — atualizado automaticamente
  posts/<slug>.html   Conteúdo do post (HTML simples)
  posts/_template.html Template padrão para novos posts
EOF
}

case "${1:-}" in
  -h|--help|"")
    usage
    ;;
  --list)
    cmd_list
    ;;
  --sync)
    cmd_sync
    ;;
  --validate)
    cmd_validate
    ;;
  --open)
    [ -z "${2:-}" ] && { echo "Uso: $0 --open <slug>"; exit 1; }
    cmd_open "$2"
    ;;
  -*)
    echo -e "${RED}Opção desconhecida: $1${NC}"
    usage
    exit 1
    ;;
  *)
    [ -z "${2:-}" ] && slug="" || slug="$2"
    cmd_create "$1" "$slug"
    ;;
esac
