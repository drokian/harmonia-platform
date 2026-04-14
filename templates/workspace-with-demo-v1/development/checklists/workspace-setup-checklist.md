# Workspace Kurulum Kontrol Listesi

Yeni bir workspace kurulumunda bu listeyi sirali sekilde tamamlayin.

## Faz 0 — Onkosullar

- [ ] Node.js yüklü (gerekli surum: secilen stack'in `stacks/*/workspace/package.json` dosyasindaki `engines.node` alanindan dogrulanir)
- [ ] Git yüklü (`git --version`)
- [ ] PowerShell 5.1+ veya pwsh 7+ mevcut
- [ ] GitHub hesabi ve erişim tokeni hazir

## Faz 1 — Repo Kurulumu

- [ ] Workspace root repo olusturuldu (private)
- [ ] Demo repo olusturuldu (public)
- [ ] Scaffold veya manuel kurulum adimlari tamamlandi
- [ ] `development/` klasoru lokal'de mevcut ancak remote'a gitmiyor (`.gitignore` kontrolu)

## Faz 2 — Submodule

- [ ] Demo submodule eklendi (`git submodule add <demo-repo-url> demo`)
- [ ] `.gitmodules` dogrulandi
- [ ] `git submodule update --init --recursive` calıstırıldı

## Faz 3 — CI/CD

- [ ] Gerekli workflow dosyalari ekliyse `.github/workflows/` yapisi dogrulandi
- [ ] `template-manifest.yml` dogrulandi
- [ ] `validate-template.ps1` ilk kez PASS dondurdu

## Faz 4 — Guvenlik

- [ ] `.env.example` olusturuldu; gercek degerler icermez
- [ ] `verify-no-secrets-in-demo.ps1` PASS dondurdu
- [ ] Branch koruma kurallari GitHub'da etkinlestirildi (`main`, `develop`)

## Faz 5 — Dokumantasyon

- [ ] `README.md` workspace bilgileri guncellendi
- [ ] `docs/installation/` bolumu tamamlandi
- [ ] Ekip uyeleri `development/guides/` icindeki rehberleri okudu
