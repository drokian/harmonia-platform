# Surum Oncesi Kontrol Listesi

Bir versiyon surumu yapmadan once bu listedeki her maddeyi tamamlayin.

## Kod Kalitesi

- [ ] Tum testler gecti (`npm test` veya ilgili komut)
- [ ] Lint hatalari temizlendi
- [ ] `pwsh ./scripts/validate-template.ps1` PASS dondurdu
- [ ] `pwsh ./scripts/verify-no-secrets-in-demo.ps1` PASS dondurdu (demo/ temiz)

## Dokumantasyon

- [ ] `TEMPLATE_CHANGELOG.md` guncel (TODO satiri yok)
- [ ] `TEMPLATE_VERSION` yeni surumu yansitıyor
- [ ] `README.md` baseline satiri TEMPLATE_VERSION ile uyusur
- [ ] Yeni ozellikler icin `docs/` guncellendi

## Demo Hazirlik

- [ ] `sync-to-demo.ps1 -DryRun` ile hangi dosyalarin gidecegi onaylandi
- [ ] Demo guncellendi ve test edildi
- [ ] Demo deployment dogrulanan URL'den erisibiliyor

## Git

- [ ] `develop` branch'i temiz ve guncel
- [ ] Release branch'i `release/vX.Y.Z` formatinda acildi
- [ ] Commit gecmisi anlasilir mesajlar icerir

## Son Kontrol

- [ ] PR acildi ve en az bir onay alindi
- [ ] CI workflow yesil
- [ ] `main`'e merge edildi ve `vX.Y.Z` etiketi atildi
