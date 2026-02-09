# 0xAudit Landing Page

## Deploy

### GitHub Pages
1. Push `website/` to repo
2. Settings → Pages → Source: main, folder: `/website`

### Vercel
```bash
cd website
npx vercel --prod
```

### Netlify
Drag & drop `website/` folder at app.netlify.com/drop

## Stack
- HTML + TailwindCSS (CDN) + vanilla JS
- Single file, no build step
