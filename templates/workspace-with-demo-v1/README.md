# workspace-with-demo-v1

> Harmonia Template — Current baseline: `v1.0.0`

Private workspace + public demo submodule yapisi icin Harmonia template'i.

## Ne Yapar

Bu template, ayni urunun iki ayri repo olarak yonetildigi yapilari destekler:

- **Workspace (private):** Kaynak kod, secrets, CI pipeline, tam islevsellik.
- **Demo (public):** Guvenli, filtrelenmis, halka acik surum — Git submodule olarak workspace'e baglanir.

## Yapisi

```
/                           → workspace root (private repo)
.github/
  copilot-instructions.md   → AI ajan kurallari (tek kaynak)
  template-manifest.yml     → required_dirs, required_files, forbidden_globs, demo_sync_denylist
  workflows/
    template-validation.yml → manifest dogrulama
    ci.yml                  → lint / build
    release.yml             → tag + changelog zorunlulugu
    submodule-sync.yml      → demo submodule guncelleme
CLAUDE.md                   → Claude Code stub
scripts/
  sync-to-demo.ps1          → workspace → demo guvenli kopyalama
  validate-template.ps1     → manifest - filesystem karsilastirmasi
  verify-no-secrets-in-demo.ps1 → demo/ icin secret taramasi
  bump-template-version.ps1 → TEMPLATE_VERSION + README + CHANGELOG
demo/                       → public demo (git submodule)
docs/                       → MkDocs workspace dokumantasyonu
backups/
  latest.json               → tracked
  (diger backup'lar gitignore'da)
stacks/
  node-service/
  python-service/
  nextjs-app/
development/                → .gitignored — ozel surec notlari, backlog, kararlar
```

## Guvenlik Modeli

3 katmanli savunma:

1. **Git katmani:** `.gitignore` — `.env`, `secrets.*`, `*.key`, `credentials.*` hic izlenmez.
2. **Script katmani:** `scripts/sync-to-demo.ps1` — manifest `demo_sync_denylist`'i okur, eslesen dosyalari atlar; API key regex taramasi yapar.
3. **Manifest katmani:** `.github/template-manifest.yml` `forbidden_globs` — CI her PR'da tarar.

## Kullanim

Yeni bir workspace olusturmak icin Harmonia scaffold scriptini kullanin:

```powershell
pwsh -File ./templates/workspace-with-demo-v1/development/scripts/scaffold-workspace-with-demo.ps1 `
    -TargetPath "D:\work\my-workspace" `
    -Stack node-service `
    -InitGitRepos
```

Scriptler:

```powershell
pwsh ./scripts/sync-to-demo.ps1 [-DryRun]
pwsh ./scripts/validate-template.ps1
pwsh ./scripts/verify-no-secrets-in-demo.ps1
pwsh ./scripts/bump-template-version.ps1 -Bump patch
```

## Template Surumu

`TEMPLATE_VERSION` dosyasinda bulunur. Versiyon guncelleme:

```powershell
pwsh ./scripts/bump-template-version.ps1 -Bump patch
```
