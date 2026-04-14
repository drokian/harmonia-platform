# Template Dogrulamasi Nasil Calistirilir

`validate-template.ps1` manifest ile dosya sistemini karsilastirir; eksik klasor/dosya veya yasak glob bulursa rapor eder.

## Temel Kullanim

```powershell
# Standart dogrulama
pwsh ./scripts/validate-template.ps1

# Sonucu degistirmesiz sadece gormek icin
pwsh ./scripts/validate-template.ps1 -DryRun
```

## Cikti Ornegi (PASS)

```
[validate] Root  : D:\my-product
[validate] Manifest: .github/template-manifest.yml
[validate] --- required_dirs kontrol ---
[validate] OK    .github
[validate] OK    scripts
...
[validate] --- required_files kontrol ---
[validate] OK    README.md
...
[validate] --- forbidden_globs kontrol ---
[validate] OK    Yasak glob eslesmesi yok
[validate] ---
[validate] OK    Tum kontroller gecti.
```

## Cikti Ornegi (FAIL)

```
[validate] FAIL  Dizin eksik: docs/architecture
[validate] FAIL  Dosya eksik: docs/installation/phase-0-prerequisites.md
[validate] FAIL  Yasak dosya bulundu (**/.env): .env
[validate] ---
[validate] FAIL  3 kontrol basarisiz.
```

## Ne Kontrol Edilir

| Kontrol | Aciklama |
|---------|----------|
| `required_dirs` | Liste'deki her klasorun varligini kontrol eder |
| `required_files` | Liste'deki her dosyanin varligini kontrol eder |
| `forbidden_globs` | Bu desen kalibina uyan dosya varsa FAIL uretir |

## CI ile Entegrasyon

Bu template'te su anda `.github/workflows/template-validation.yml` hazir gelmez. Bu nedenle template dogrulamasi icin temel yol yerelde `pwsh ./scripts/validate-template.ps1` veya `powershell -ExecutionPolicy Bypass -File .\scripts\validate-template.ps1` calistirmaktir.

## Sik Karsilasilan Sorunlar

**Eksik dizin hatasi manifest'e yeni dizin ekleyince:** Hem manifest `required_dirs` listesini hem de filesystem'i guncellemelisiniz. Biri eksik olursa validation fail olur.

**Forbidden glob islenmis bir dosyayi buluyor:** `.gitignore` veya `demo_sync_denylist` yeterli degil; o dosyayi template kaynagindan kaldirin.
