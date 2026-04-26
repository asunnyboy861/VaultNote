# Git Repositories

## Main App (iOS Application + Policy Pages)

| Item | Value |
|------|-------|
| **Repository Name** | VaultNote |
| **Git URL** | git@github.com:asunnyboy861/VaultNote.git |
| **Repo URL** | https://github.com/asunnyboy861/VaultNote |
| **Visibility** | Public |
| **Primary Language** | Swift |
| **GitHub Pages** | ✅ **ENABLED** (from /docs folder)

## Repository Structure

```
VaultNote/
├── VaultNote/                    # iOS App Source Code
│   ├── VaultNote.xcodeproj/      # Xcode Project
│   ├── VaultNote/                # Swift Source Files
│   │   ├── Views/
│   │   ├── Models/
│   │   ├── ViewModels/
│   │   ├── Data/
│   │   └── Auth/
│   └── ...
├── docs/                         # Policy Pages (GitHub Pages)
│   ├── index.html                # Landing Page
│   ├── support.html              # Support Page
│   └── privacy.html              # Privacy Policy
├── screenshots/                  # App Store Screenshots
│   ├── 00_lock_screen.png
│   └── 01_notes_list_empty.png
├── .github/workflows/
│   └── deploy.yml                # GitHub Pages deployment
├── us.md                         # English Development Guide
├── keytext.md                    # App Store Metadata
├── capabilities.md               # Capabilities Configuration
├── icon.md                       # App Icon Details
├── price.md                      # Pricing Configuration
├── PROJECT_SUMMARY.md            # Project Completion Summary
└── nowgit.md                     # This File
```

## Policy Page URLs

| Page | URL | Status |
|------|-----|--------|
| **Landing Page** | https://asunnyboy861.github.io/VaultNote/ | ✅ Active |
| **Support Page** | https://asunnyboy861.github.io/VaultNote/support.html | ✅ Active |
| **Privacy Policy** | https://asunnyboy861.github.io/VaultNote/privacy.html | ✅ Active |

**Note**: Terms of Use not required for one-time purchase apps.

## GitHub Pages Configuration

- **Source**: main branch, /docs folder
- **URL**: https://asunnyboy861.github.io/VaultNote/
- **HTTPS**: Enforced
- **Auto-deploy**: On push to main (via GitHub Actions)

## App Store Connect URLs

After submission:
- **App Store URL**: https://apps.apple.com/app/vaultnote/id[APP_ID]
- **App Store Connect**: https://appstoreconnect.apple.com/apps/[APP_ID]

## Created Date
2026-04-26
