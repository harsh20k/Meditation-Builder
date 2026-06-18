# Rituals Landing Page

Single-file marketing page for validating market demand before iOS launch.

## Local preview

Open `index.html` in a browser, or serve locally:

```bash
cd landing
python3 -m http.server 8080
# → http://localhost:8080
```

## Formspree setup

1. Create a free account at [formspree.io](https://formspree.io)
2. Create a new form and copy your form ID (looks like `xyzabcde`)
3. Replace `YOUR_FORM_ID` in two places in `index.html`:
   - The `<form action="...">` attribute
   - The `FORMSPREE_ENDPOINT` constant in the `<script>` block

Submissions capture:
- Email (required)
- Current practice setup (dropdown)
- What would make them switch (optional text)

View responses in the Formspree dashboard.

## Deploy

### Netlify Drop (fastest)

1. Go to [app.netlify.com/drop](https://app.netlify.com/drop)
2. Drag the `landing/` folder onto the page
3. Done — you get a `*.netlify.app` URL instantly

### GitHub Pages

**Option A — `/docs` folder**

```bash
cp -r landing docs
git add docs && git commit -m "Add landing page"
```

In repo Settings → Pages → Source: `main` branch, `/docs` folder.

**Option B — project site from `landing/` branch**

Push `landing/` contents to a `gh-pages` branch and enable Pages from that branch.

### Custom domain

Point your domain's DNS to Netlify/GitHub Pages, then add the domain in the host's dashboard.

## Customize

- **App icon**: Replace the CSS placeholder in `.app-icon` with `<img src="icon.png">` once you have a web-ready PNG
- **Privacy link**: Update the footer `href="#"` to your privacy policy URL
- **OG image**: Add `<meta property="og:image" content="...">` when you have a share image

## Files

```
landing/
  index.html   — self-contained page (HTML + CSS + JS)
  README.md    — this file
```
