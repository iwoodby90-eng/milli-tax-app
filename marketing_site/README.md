# Milli Marketing Site — milli.tax

Three static pages: **`index.html`** (landing), **`privacy.html`**, **`terms.html`**.
Written in plain HTML/CSS — no build step, no framework — so it deploys anywhere.

## Deploy to Vercel (recommended, ~2 minutes)

```bash
cd /app/marketing_site
npx vercel --prod
```

Follow the prompts (link project → deploy). Vercel will read `vercel.json`
for security headers + friendly URLs (`/privacy`, `/terms`).

Once deployed, point your `milli.tax` domain at Vercel:

- **A record**: `76.76.21.21`
- **AAAA record**: `2606:4700:3033::6815:1515`
- Or add a CNAME on `www` pointing to `cname.vercel-dns.com`

## Deploy to Netlify (alternative)

```bash
cd /app/marketing_site
npx netlify deploy --prod --dir=.
```

## Deploy to Cloudflare Pages

Push this folder to a GitHub repo, then in the Cloudflare dashboard:

- Framework preset: **None**
- Build command: *(leave blank)*
- Build output directory: `.`

## Preview locally

```bash
cd /app/marketing_site
python3 -m http.server 8000
# open http://localhost:8000
```

## What's inside

| File | Purpose |
|---|---|
| `index.html` | Landing page — hero, features, pricing tiers, links to legal |
| `privacy.html` | Full-length privacy policy required by Apple App Review |
| `terms.html` | Full-length terms of service (Michigan governing law) |
| `style.css` | Shared stylesheet — Big City Futuristic aesthetic, charcoal checker, neon cyan |
| `vercel.json` | Vercel deploy config with security headers + `/privacy` / `/terms` rewrites |

## Post-deploy checklist

Before submitting the iOS build, verify:

1. `https://milli.tax/privacy` returns HTTP 200 and renders the full policy
2. `https://milli.tax/terms` returns HTTP 200
3. Update the URLs in `/app/APP_STORE_METADATA.md` to point to the live domain
4. Update the iOS `Settings → Legal` links (in the React app) to the live URLs

Apple rejects builds without a live, functional Privacy Policy URL — this
site exists specifically to unblock that requirement.
