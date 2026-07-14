# MATHASILV's LAB — Site

Site pessoal estilo retro/geocities. Posts, galeria e links.

## Estrutura

```
├── index.html          # Home (posts recentes, preview galeria, rádio)
├── projects.html       # Lista completa de posts
├── gallery.html        # Galeria de fotos
├── post.html           # Leitor de post individual (?id=<slug>)
├── assets/
│   ├── style.css       # Folha de estilo compartilhada
│   ├── site.js         # JS compartilhado (lightbox, footer dates)
│   └── nav.js          # Menu COMMAND (sidebar) compartilhado
├── posts/
│   ├── posts.json      # Manifesto de posts (atualizado por new-post.sh)
│   ├── _template.html  # Template para novos posts
│   └── <slug>.html     # Conteúdo de cada post
├── photos/
│   ├── photos.json     # Manifesto de fotos da galeria
│   └── *.jpg/png/gif   # Imagens
├── badges/             # Badges retrô do sidebar
├── new-post.sh         # CLI para criar/gerenciar posts
└── winamp.html         # Player Webamp (opcional)
```

## Criar um post rápido

```bash
./new-post.sh "Título do Post"
# Cria posts/<slug>.html e adiciona ao posts.json com a data de hoje

./new-post.sh "Título do Post" meu-slug
# Define o slug manualmente
```

Edite o HTML gerado e atualize o `excerpt` em `posts/posts.json`.

## Gerenciar posts

```bash
./new-post.sh --list        # Listar todos os posts
./new-post.sh --validate    # Verificar integridade (JSON ↔ HTML ↔ fotos)
./new-post.sh --sync        # Sincronizar JSON com arquivos HTML
./new-post.sh --open slug   # Abrir post no editor ($EDITOR)
```

## Adicionar fotos à galeria

1. Adicione a imagem em `photos/`
2. Edite `photos/photos.json`:
   ```json
   { "file": "minha-foto.jpg", "caption": "Descrição" }
   ```

## Deploy

O site é servido estaticamente (Vercel). Qualquer push para `main` atualiza o site.

## Bugs corrigidos

- `photos.json` referenciava arquivos inexistentes (`IMG_0002.jpg`, `IMG_0003.png`)
- `primeiro-post.html` existia mas não estava no `posts.json`
- XSS via path traversal em `post.html?id=../...` — agora valida slug com regex `^[a-z0-9][a-z0-9-]*$`
- Títulos/excerpts do `posts.json` eram inseridos sem sanitização no HTML
- CSS/JS duplicados em 4 páginas agora extraídos em `assets/`
