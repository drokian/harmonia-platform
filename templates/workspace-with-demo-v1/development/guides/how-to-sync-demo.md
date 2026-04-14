# Demo'ya Nasil Senkronizasyon Yapilir

`sync-to-demo.ps1` workspace'ten `demo/` submodule'une denetimli dosya kopyasi yapar.

## Onkosul Kontrolu

Bu rehberi kullanmadan once:
- `demo/` submodule'u klonlu ve guncel olmali (`git submodule update --init`)
- Workspace kokunde calisabilirsiniz; commit edilmemis degisiklikler sorun degil, ancak degisikliklerin karismamasi icin temiz bir working tree onerilir

## Temel Kullanim

```powershell
# Once kuru calisma ile ne kopyalanacagini gor
pwsh ./scripts/sync-to-demo.ps1 -Sources @("src/", "public/") -DryRun

# Gercek kopyalama
pwsh ./scripts/sync-to-demo.ps1 -Sources @("src/", "public/")
```

## Parametreler

| Parametre | Aciklama | Zorunlu |
|-----------|----------|---------|
| `-Sources` | Kopyalanacak kaynak yol listesi (dosya veya klasor) | Evet |
| `-DemoPath` | Demo klasoru yolu (varsayilan: `./demo`) | Hayir |
| `-ManifestPath` | Manifest yolu (varsayilan: `./.github/template-manifest.yml`) | Hayir |
| `-DryRun` | Kopyalama yapmadan log uretir | Hayir |

## Guvenlik Kontrolleri

Script otomatik olarak:
1. `demo_sync_denylist`'teki desenlere uyan dosyalari atlar (`.env*`, `backups/`, `development/` vb.)
2. Her dosyada secret taramasi yapar (API key, token vb.)
3. Kopyalanacak dosyanin template root altinda oldugunu dogrular

Secret bulunursa kopyalama **iptal edilir** ve hata rapor edilir.

## Sync Sonrasi

Script yalnizca dosya kopyalar; commit yapmaz. Sync sonrasi:

```bash
cd demo
git status
git add -A
git commit -m "sync: workspace'ten guncelleme"
git push origin main
```

## Sik Karsilasilan Sorunlar

**SKIP mesajlari cok fazla:** Denylist kontrolunu gecemeyen dosyalar. Normal davranis; kasitli olarak engellenenler.

**Secret tespit edildi hatasi:** Kopyalanmak istenen dosyada hassas veri var. Dosyayi `.env.example` seklinde temizleyip tekrar deneyin.

**demo/ dizini bulunamadi:** `git submodule update --init` calistirin.
