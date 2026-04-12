# Project Migration Steps

Bu runbook, mevcut bir projeyi demo/commercial template yapisina gecirmek icin uygulanabilir adimlari verir.

QR Pay Check ozelinde doldurulmus plan:

- `development/migration/source-qr-pay-check-migration-plan.md`

## 0. Girdiler

- Kaynak proje yolu
- Hedef stack overlay (`node-service`, `python-service`, `nextjs-app`)
- Demo repoda kalacak ozellik kapsamı
- Commercial repoda kalacak ozellik kapsamı

## 1. Yeni Workspace'i Uret

1. Template klasorune gecin.
2. Scaffold script'ini calistirin.
3. Hedef workspace olusumunu dogrulayin.

Ornek:

```powershell
powershell -ExecutionPolicy Bypass -File .\development\scripts\scaffold-demo-commercial.ps1 `
  -TargetPath "D:\work\sample-product" `
  -Stack node-service `
  -InitGitRepos
```

## 2. Kaynak Projeyi Siniflandir

Kaynak projedeki her alan icin karar verin:

- `demo + commercial`
- `commercial only`
- `development only`
- `remove`

Uygulama oncesi `development/checklists/repo-split-checklist.md` tamamlanmis olmalidir.

## 3. Dosyalari Tasiyin

1. `demo + commercial` dosyalarini iki repoya da alin.
2. `commercial only` dosyalarini sadece commercial repoya alin.
3. Gecis notlari ve karar kayitlarini `development/` altina alin.
4. Demo icinde gizli bilgi ve lisansli icerik kalmadigini kontrol edin.

## 4. Repo Bazli Duzenleme

### Demo repo

- README'yi sadece public akisa gore guncelleyin
- Ornek veri disinda veri tutmayin
- Build/test komutlarini demo kapsamiyla sinirlayin

### Commercial repo

- Tam ozellik setini ve entegrasyonlari koruyun
- Gizli konfigurasyonlari guvenli kanaldan yonetin
- Operasyon dokumanini ticari akisla guncelleyin

## 5. Dogrulama ve Cikis

1. Demo repoyu temiz ortamda calistirin.
2. Commercial repoyu ayri ortamda calistirin.
3. Iki repoda da ilk commit'i alin.
4. Checklist dosyalarinda son durumu isaretleyin:
   - `development/checklists/demo-release-checklist.md`
   - `development/checklists/commercial-release-checklist.md`

## 6. Onerilen Ilk Commit Sirası

1. `chore: scaffold demo-commercial workspace`
2. `chore: import shared baseline from source project`
3. `chore: apply demo content filtering`
4. `chore: apply commercial-only modules`
5. `docs: finalize migration notes and release checklists`

## 7. Kaynak Proje Bazli Ornek

Gercek bir ornek akisi icin su dosyayi kullanin:

- `development/migration/example-qr-pay-check.md`

Bu ornek, tek repodaki varsayilan odeme projesinin demo ve commercial repolara ayrisma adimlarini file-level kararlarla gosterir.