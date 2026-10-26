# AV-Tech

Projects and tech posts at https://tech.amvhome.net, built with Jekyll on GitHub Pages (repo `adrianv66/av-tech`).

## How it's laid out

| What | Where it lives | Address on the site |
|---|---|---|
| Front page (projects shelf + posts shelf) | `index.html` | `/` |
| A project | `_projects/<name>.md` | `/projects/<name>/` |
| A post | `_posts/YYYY-MM-DD-title.md` | `/posts/title/` |
| All posts, filterable by tag | `posts/index.html` | `/posts/` |
| All projects | `projects/index.html` | `/projects/` |
| Images | `images/` | `/images/...` |

## Adding a project

```powershell
.\tools\New-TechProject.ps1 "Invoke-ServerHealth" -Repo https://github.com/adrianv66/server-health -Summary "Morning health checks."
```

Options: `-Language` (default PowerShell), `-Status Active|Paused|Archived`, `-Started 2025-06-01`.
Spine colours per language are in `language_colors` in `_config.yml`; add a language there to give it its own colour.
A project's book gets thicker as more posts link to it.

## Adding a post

```powershell
.\tools\New-TechPost.ps1 "Reading Intune devices with Graph" -Tags powershell, graph -Summary "Paging through managedDevices."
```

Add `-Project invoke-serverhealth` to list it on that project's page, and `-Publish` to commit and push for you.

Code blocks use three backticks plus the language (`powershell`, `bash`, `json`, `yaml`, `python`...) and get
syntax highlighting and a Copy button.

## Before you publish

The repo and site are public. Check posts and code for client names, tenant IDs, internal hostnames, secrets and
anything from work you're not free to share. Use placeholders like `contoso.com` and `<tenant-id>`.

## First-time setup

1. Create a **public** repo `av-tech` on github.com/adrianv66 and push this folder to `main`.
2. Repo **Settings → Pages**: Deploy from a branch, `main`, `/ (root)`. Custom domain shows `tech.amvhome.net` (from `CNAME`).
3. GoDaddy DNS for amvhome.net: add `CNAME`, name `tech`, value `adrianv66.github.io`.
4. When the DNS check is green, tick **Enforce HTTPS**.

## Vendors shelf

One file per vendor in `_vendors/` (e.g. `_vendors/citrix.md`): `title`, `order` (position on the shelf), `tag`,
`summary`, `products`, optional `website` and `spine_color`. A vendor's page at `/vendors/<file name>/` lists every
post tagged with its `tag`, so tag posts accordingly:

```powershell
.\tools\New-TechPost.ps1 "Scaling AVD host pools" -Tags avd, powershell
```

Tags in use: citrix, horizon, workspace-one, avd, windows-365, intune, igel, defender, airlock, action1.
To add a vendor, copy one of the files and change it; to remove one, delete its file.
