# workspace-with-demo Template

> Harmonia Template — Current baseline: `v1.0.0`

Private workspace + public demo submodule yapısı için Harmonia template'i.

## Ne Yapar

Bu template, aynı ürünün iki ayrı repo olarak yönetildiği yapıları destekler:

- **Workspace (private):** Kaynak kod, secrets, CI pipeline, tam işlevsellik.
- **Demo (public):** Güvenli, filtrelenmiş, halka açık sürüm — Git submodule olarak workspace'e bağlanır.

## Tasarım Felsefesi

Harmonia, güvenlik-ilk bir yaklaşımla sunar:

- **Secrets hiçbir zaman public repo'ya giremez.**
- Filtreleme script seviyesinde (`.gitignore` + `sync-to-demo.ps1` + manifest) zorlanır.
- Template tamamlanmamışsa bile, bu savunma mekanizmaları ilk gündür aktiftir.
- AI ajan kuralları hem repo'ya hem template'e gömülüdür (CLAUDE.md, copilot-instructions.md).

## Yapısı

```
/                           → workspace root (private repo)
.github/
  copilot-instructions.md   → AI ajan kuralları (tek kaynak)
  template-manifest.yml     → required_dirs, required_files, forbidden_globs
  workflows/                → CI workflow'ları
CLAUDE.md                   → Claude Code stub
scripts/                    → Operasyon scriptleri
  sync-to-demo.ps1          → Manifest `demo_sync_denylist`'ini okur, güvenli kopyala
  validate-template.ps1     → Manifest forbidden_globs, required_dirs, required_files doğrulaması
  verify-no-secrets-in-demo.ps1 → Demo içinde secret/API key izi tarar
  bump-template-version.ps1 → Template baseline/version bilgisini günceller
demo/                       → public demo (git submodule)
  index.html                → Minimal başlangıç iskeleti
  styles.css
  README.md
docs/                       → MkDocs workspace dokumantasyonu
  installation/
    phase-0-prerequisites.md
    phase-1-private-workspace-repo.md
    phase-2-public-demo-repo.md
    phase-3-submodule-link.md
    phase-4-security-validation.md
    phase-5-first-deploy.md
backups/
  latest.json               → tracked
development/                → özel süreç notları, backlog, kararlar
  decisions/
  guides/
  README.md
```

## Güvenlik Modeli

3 katmanlı savunma:

1. **Git katmanı:** `.gitignore` — `.env`, `secrets.*`, `*.key`, `credentials.*` hiç izlenmez.
2. **Script katmanı:** `scripts/sync-to-demo.ps1` — manifest `demo_sync_denylist`'i okur, eşleşen dosyaları atlar; API key regex taraması yapar.
3. **Manifest katmanı:** `.github/template-manifest.yml` `forbidden_globs` — `scripts/validate-template.ps1` ile lokal doğrulanır.

## Kullanım

Aşama aşama kurulum rehberi için [Başlarken → workspace-with-demo](../getting-started/scaffold.md) sayfasını ziyaret edin.

Veya doğrudan installation fase rehberlerine bakın:

- [Fase 0: Gereksinimler](../installation/phase-0-prerequisites.md)
- [Fase 1: Private Workspace Repo](../installation/phase-1-private-workspace-repo.md)
- [Fase 2: Public Demo Repo](../installation/phase-2-public-demo-repo.md)
- [Fase 3: Submodule Bağlantısı](../installation/phase-3-submodule-link.md)
- [Fase 4: Güvenlik Doğrulaması](../installation/phase-4-security-validation.md)
- [Fase 5: İlk Deploy](../installation/phase-5-first-deploy.md)

## Geliştirilme Durumu

Template kademeli olarak tamamlanmaktadır:

- **WD-001** (✓ tamamlandı): Manifest, iskelet, temel konfigürasyon
- **WD-002** (✓ tamamlandı): `scripts/` içerisindeki PowerShell scriptleri
- **WD-003** (⏳ devam ediyor): `.github/workflows/` CI dosyaları — klasör mevcut, workflow'lar eklenecek
- **WD-004** (✓ tamamlandı): Demo submodule yapısı + stacks overlay'leri
- **WD-005** (✓ tamamlandı): Development + MkDocs dokümantasyonu

## İlgili Kaynaklar

- **Template Tasarım Planı** — `development/plans/workspace-with-demo-v1-plan.md`
- **Harmonia — Template Adlandırma Konvansiyonu** — `development/conventions/template-naming.md`
- **Manifest Şeması** — `templates/workspace-with-demo-v1/.github/template-manifest.yml`
