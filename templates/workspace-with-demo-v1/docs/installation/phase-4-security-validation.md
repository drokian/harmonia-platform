# Asama 4 - Guvenlik Dogrulamasi

Bu asama, template yapisinin tutarli oldugunu ve demo tarafina secret sizmadigini dogrular.

## Onkosul Kontrolu

Bu asamadan baslamalisin eger:
- Asama 3 tamamlandiysa.
- `scripts/` altindaki dogrulama scriptleri mevcutsa.
- Demo submodule baglandiktan sonra ilk guvenlik kontrolunu yapmak istiyorsan.

## Adim-adim Komutlar

### Bash

```bash
cd my-product
pwsh ./scripts/validate-template.ps1
pwsh ./scripts/verify-no-secrets-in-demo.ps1
```

### PowerShell

```powershell
Set-Location my-product
pwsh ./scripts/validate-template.ps1
pwsh ./scripts/verify-no-secrets-in-demo.ps1
```

Opsiyonel ek tarama:

### Bash

```bash
git grep -nE "(AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|sk-[A-Za-z0-9]{20,})" demo || true
```

### PowerShell

```powershell
git grep -nE "(AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|sk-[A-Za-z0-9]{20,})" demo
```

## Bu Asama Bittiginde

- [ ] `validate-template.ps1` exit code 0 ile tamamlandi.
- [ ] `verify-no-secrets-in-demo.ps1` exit code 0 ile tamamlandi.
- [ ] Demo klasorunde bilinen secret pattern'i bulunmadi.

## Sorun mu Yasiyorsun?

### `validate-template.ps1` required file hatasi veriyor
- Eksik dosyalari manifest listesiyle karsilastirip tamamla.

### Secret scan false-positive veriyor
- Once gercek secret olmadigini dogrula.
- Gerekirse pattern setini daraltarak scripti proje baglamina gore guncelle.

### `pwsh` komutu CI'da bulunamadi
- Runner imajinda PowerShell 7 olmadigini gosterir.
- CI job'ina PowerShell kurulum adimi eklenmeli.
