# Kang documentation

Astro + Starlight, with a custom Kang Black & Blue theme and a light-mode counterpart. Source pages live in `src/content/docs`; colors live in `src/styles/kang.css`.

## Local development

Use Node.js 22.23.4 or later (Node 24 LTS recommended).

```sh
cd docs
npm ci
npm run dev
```

Open http://localhost:4321/kang/.

```sh
npm run check
npm run build
npm run preview
```

The production build includes Pagefind search. Search is best checked with `npm run preview`.

## GitHub Pages

The workflow in `../.github/workflows/docs.yaml` builds pull requests and deploys main or a manual main-branch run. Before the first deployment, set repository **Settings → Pages → Build and deployment → Source → GitHub Actions**.

The configured URL is `https://zaidanm16.github.io/kang/`. For a custom domain, update both `site` and `base` in `astro.config.mjs`, and update internal content links to match. No deployment occurs until the workflow is pushed and run.

Only static output in `dist` is uploaded. Do not put secrets in documentation or public assets.
