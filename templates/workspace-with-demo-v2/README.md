# workspace-with-demo-v2

**Private workspace + public demo submodule iskeleti, guvenlik-sikilastirilmis**

> Current baseline: `v2.0.0`

Bu template, urunun `private` bir workspace'te gelistirilmesi ve `public` bir demo repo'suna submodule olarak baglanmasi senaryosu icin bir script paketi sunar. Fiziksel urun dosyasi icermez; `scripts/install.ps1` calistirildiktan sonra kullanicinin ortaminda hedef klasor yapisi ve tum destek dosyalari olusturulur.

---

## Kullanim

```powershell
# Guided mod (interaktif, 6 asama)
pwsh scripts/install.ps1 --mode guided

# Auto mod (tek ekranda parametreler)
pwsh scripts/install.ps1 --mode auto

# Linux/macOS (PS7 kuruluysa)
bash scripts/install.sh
```

---

## Uretilen Workspace Yapisi

Script'ler calistirildiginda su yapi olusur:

```
my-workspace/
├── README.md
├── TEMPLATE_VERSION
├── TEMPLATE_CHANGELOG.md
├── TEMPLATE_IDENTITY.yml
├── .gitignore
├── .editorconfig
├── .secretscanignore
├── .github/
│   ├── template-manifest.yml
│   └── workflows/
│       ├── ci.yml
│       ├── release.yml
│       └── template-validation.yml
├── docs/
│   ├── index.md
│   ├── architecture/
│   └── installation/
├── development/
│   ├── backlogs/
│   ├── sprints/
│   ├── decisions/
│   ├── conventions/
│   ├── guides/
│   ├── checklists/
│   └── glossary/
├── scripts/
│   ├── Test-TemplateStructure.ps1
│   ├── Test-SecretsInDemo.ps1
│   ├── Sync-ToDemo.ps1
│   └── Update-TemplateVersion.ps1
├── backups/
└── demo/                              <-- git submodule (public repo)
```

---

## Script Paketi

| Script | Aciklama |
|---|---|
| `scripts/install.ps1` | TUI ana dongusu — guided ve auto mod |
| `scripts/install.sh` | PS7 varligi kontrol eder, `install.ps1`'e yonlendirir |
| `scripts/New-DirectoryStructure.ps1` | Hedef workspace klasor yapisini olusturur |
| `scripts/New-FileSet.ps1` | Dosyalari here-string ve `file-templates/`'ten uretir |
| `scripts/Set-GitRepositories.ps1` | Git init, remote, submodule baglama |
| `scripts/Test-TemplateStructure.ps1` | Manifest bazli yapı dogrulama (kaynak ve uretilen) |
| `scripts/Test-SecretsInDemo.ps1` | Demo'da secret taramasi, allowlist destekli |
| `scripts/Sync-ToDemo.ps1` | Dosya/build ciktisini demo'ya kopyalar, secret + forbidden filtreli |
| `scripts/Update-TemplateVersion.ps1` | TEMPLATE_VERSION, README ve CHANGELOG tutarli gunceller |

---

## Guvenlik Modeli

1. **Forbidden pattern filtreleme** — `Sync-ToDemo.ps1` sabit liste ile `.env`, secret, key dosyalarini kopyalamaz.
2. **Secret tarama** — `Test-SecretsInDemo.ps1` spesifik pattern'lerle (OpenAI, AWS, GitHub token vb.) demo'yu tarar.
3. **Allowlist** — `.secretscanignore` dosyasi bilinen false positive'leri listeler; bu dosyalar taramadan cikartilir.
4. **Manifest dogrulama** — `Test-TemplateStructure.ps1` hem Harmonia kaynagini (`-Role source`) hem uretilen workspace'i (`-Role generated`) dogrular.
5. **CI pipeline** — `template-validation.yml` PR'larda yapı ve versiyon politikasini zorunlu kilar.

---

## Onkosullar

- PowerShell 7+ (`pwsh --version`)
- Git 2.40+ (`git --version`)
- GitHub hesaplari: private organizasyon (workspace) + public hesap/org (demo)
- SSH veya PAT ile `git push` yetkisi

---

## Daha Fazla Bilgi

- **Kurulum rehberi:** `file-templates/docs/installation/` (PR-3 sonrasi tam icerik)
- **Mimari:** `file-templates/docs/architecture/` (PR-3 sonrasi tam icerik)
- **Harmonia katalog sayfasi:** `docs/templates/workspace-with-demo.md` (PR-5)
