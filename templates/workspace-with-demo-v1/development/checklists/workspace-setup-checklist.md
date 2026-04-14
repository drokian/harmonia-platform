# Workspace Kurulum Kontrol Listesi

Yeni bir workspace kurulumunda bu listeyi sirali sekilde tamamlayin.

## Fase 0 — Onkosullar

- [ ] Node.js yüklü (gerekli surum: bkz. package.json `engines.node`)
- [ ] Git yüklü (`git --version`)
- [ ] PowerShell 5.1+ veya pwsh 7+ mevcut
- [ ] GitHub hesabi ve erişim tokeni hazir

## Fase 1 — Repo Kurulumu

- [ ] Workspace root repo olusturuldu (private)
- [ ] Demo repo olusturuldu (public)
- [ ] Scaffold script calıstırıldı (bkz. `how-to-sync-demo.md`)
- [ ] `development/` klasoru lokal'de mevcut ancak remote'a gitmiyor (`.gitignore` kontrolu)

## Fase 2 — Submodule

- [ ] Demo submodule eklendi (`git submodule add <demo-repo-url> demo`)
- [ ] `.gitmodules` dogrulandi
- [ ] `git submodule update --init --recursive` calıstırıldı

## Fase 3 — CI/CD

- [ ] GitHub Actions workflow gecerli (`.github/workflows/` mevcut)
- [ ] `template-manifest.yml` dogrulandi
- [ ] `validate-template.ps1` ilk kez PASS dondurdu

## Fase 4 — Guvenlik

- [ ] `.env.example` olusturuldu; gercek degerler icermez
- [ ] `verify-no-secrets-in-demo.ps1` PASS dondurdu
- [ ] Branch koruma kurallari GitHub'da etkinlestirildi (`main`, `develop`)

## Fase 5 — Dokumantasyon

- [ ] `README.md` workspace bilgileri guncellendi
- [ ] `docs/installation/` bolumu tamamlandi
- [ ] Ekip uyeleri `development/guides/` icindeki rehberleri okudu
