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
  workflows/                → CI workflow'lari (WD-003 PR'inda eklenecek)
CLAUDE.md                   → Claude Code stub
scripts/                    → Operasyon scriptleri (WD-002 PR'inda eklenecek)
demo/                       → public demo (git submodule; scaffold sirasinda ayarlanir)
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

> **Insa Durumu:** Bu template kademeli olarak tamamlanmaktadir.
> - WD-001 (bu PR): manifest, iskelet, temel konfigurasyon ✓
> - WD-002: `scripts/` icerisindeki 4 PowerShell scripti
> - WD-003: `.github/workflows/` CI dosyalari
> - WD-004: Demo submodule yapisi
> - WD-005: Development + MkDocs docs

## Guvenlik Modeli

3 katmanli savunma:

1. **Git katmani:** `.gitignore` — `.env`, `secrets.*`, `*.key`, `credentials.*` hic izlenmez.
2. **Script katmani:** `scripts/sync-to-demo.ps1` — manifest `demo_sync_denylist`'i okur, eslesen dosyalari atlar; API key regex taramasi yapar.
3. **Manifest katmani:** `.github/template-manifest.yml` `forbidden_globs` — CI her PR'da tarar.

## Kullanim

> Scaffold scripti WD-005 PR'inda eklenecektir. Asagidaki komutlar tamamlandiginda gecerli olacaktir.

```powershell
# Harmonia repo kokunden:
pwsh -File ./templates/workspace-with-demo-v1/development/scripts/scaffold-workspace-with-demo.ps1 `
    -TargetPath "D:\work\my-workspace" `
    -Stack node-service `
    -InitGitRepos
```

Operasyon scriptleri (WD-002 PR'inda eklenecek):

```powershell
pwsh ./scripts/sync-to-demo.ps1 [-DryRun]
pwsh ./scripts/validate-template.ps1
pwsh ./scripts/verify-no-secrets-in-demo.ps1
pwsh ./scripts/bump-template-version.ps1 -Bump patch
```

## Template Surumu

`TEMPLATE_VERSION` dosyasinda bulunur. Versiyon guncelleme (WD-002 sonrasi):

```powershell
pwsh ./scripts/bump-template-version.ps1 -Bump patch
```
