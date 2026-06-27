# Moksh — GCP / Firebase Hosting Deployment Guide

## Architecture

```
Your laptop / GitHub push
        │
        ▼
GitHub Actions CI/CD
        │
        ▼
Firebase Hosting (GCP CDN)
        │
        ▼
https://YOUR_PROJECT_ID.web.app   ← live URL
```

Firebase Hosting is backed by **Google Cloud CDN**, which means:
- Files are cached at edge nodes worldwide for low latency.
- Free SSL certificate (HTTPS) is provisioned automatically.
- Custom domain support (e.g. `www.moksh.app`).
- Free tier: 10 GB storage, 360 MB/day transfer.

---

## ✅ Steps you need to do (one-time setup)

### Step 1 — Create a Firebase project (5 min)

1. Go to **https://console.firebase.google.com**
2. Click **"Add project"** → name it `moksh` (or anything)
3. Disable Google Analytics if you don't need it → **Create project**
4. Once created, note your **Project ID** (shown under the project name, e.g. `moksh-a1b2c`)

---

### Step 2 — Install Firebase CLI

Open PowerShell and run:

```powershell
npm install -g firebase-tools
```

Verify:

```powershell
firebase --version
```

---

### Step 3 — Login & link the project

```powershell
# Login to your Google account
firebase login

# Go to the app folder
cd C:\Users\USER\.gemini\antigravity\brain\284823c7-1c4b-4bfe-9a0b-db7ec9a31304\exam-wellbeing-bot

# Replace the placeholder with your real project ID
# Edit .firebaserc and change "YOUR_FIREBASE_PROJECT_ID" → "moksh-a1b2c"
```

Then deploy manually for the first time:

```powershell
firebase deploy --only hosting
```

You will see a line like:

```
✔  Hosting URL: https://moksh-a1b2c.web.app
```

🎉 **Your app is live on GCP!**

---

### Step 4 — Set up CI/CD (auto-deploy on push to GitHub)

The `.github/workflows/deploy.yml` file is already created. You just need to add 2 GitHub Secrets:

1. **Generate a service account key**:
   - In the Firebase Console → Project Settings → Service Accounts
   - Click **"Generate new private key"** → download the JSON file

2. **Add GitHub Secrets** (in your repo → Settings → Secrets → Actions):

   | Secret name | Value |
   |---|---|
   | `FIREBASE_SERVICE_ACCOUNT` | Paste the entire contents of the downloaded JSON file |
   | `FIREBASE_PROJECT_ID` | Your project ID (e.g. `moksh-a1b2c`) |

3. Push to `main` — the GitHub Action will auto-deploy every time.

---

## File reference

| File | Purpose |
|---|---|
| `exam-wellbeing-bot/firebase.json` | Firebase hosting config (public dir, headers, rewrites) |
| `exam-wellbeing-bot/.firebaserc` | Maps the `default` alias to your project ID |
| `.github/workflows/deploy.yml` | CI/CD: deploys to Firebase on every push to `main` |

---

## Optional: Custom domain

1. Firebase Console → Hosting → **Add custom domain**
2. Enter your domain (e.g. `moksh.app`)
3. Add the provided DNS records to your domain registrar
4. Firebase provisions a free SSL cert automatically within minutes

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `firebase: command not found` | Run `npm install -g firebase-tools` |
| `Error: Failed to get Firebase project` | Check `.firebaserc` has the correct project ID |
| GitHub Action fails with `FIREBASE_SERVICE_ACCOUNT` error | Ensure the secret is added and contains the full JSON content |
| App shows old version after deploy | Hard-refresh browser (`Ctrl+Shift+R`) — CSS/JS are cached aggressively |
