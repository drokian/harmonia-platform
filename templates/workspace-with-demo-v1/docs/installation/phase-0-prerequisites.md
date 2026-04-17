# Asama 0 - Onkosullar

Bu asama, kurulumdan once ortamin hazir oldugunu dogrular.

## Onkosul Kontrolu

Bu asamadan baslamalisin eger:
- Yeni bir makinede kurulum yapiyorsan.
- PowerShell/Git/GitHub erisimi durumundan emin degilsen.
- Son kurulum denemesinde araca bagli hata aldiysan.

## Adim-adim Komutlar

### Bash

```bash
pwsh --version
git --version
gh --version
ssh -T git@github.com
```

### PowerShell

```powershell
pwsh --version
git --version
gh --version
ssh -T git@github.com
```

Beklenen sonuc:
- `pwsh` surumu 7+ olmasi onerilir.
- `git` surumu 2.40+ olmasi onerilir.
- `gh` komutu opsiyoneldir, ama PR akisinda hiz kazandirir.
- SSH testi sonunda basarili kimlik dogrulama mesaji gorulmeli.

## Bu Asama Bittiginde

- [ ] PowerShell kurulu ve calisiyor (tercihen 7+).
- [ ] Git kurulu ve calisiyor (tercihen 2.40+).
- [ ] GitHub erisimi (SSH veya PAT) dogrulandi.
- [ ] Workspace private, demo public repo stratejisi net.

## Sorun mu Yasiyorsun?

### `pwsh: command not found`
- PowerShell 7 kurulu degil veya PATH'e ekli degil.
- Windows'ta PowerShell 7 yukleyip yeni terminal ac.

### `Permission denied (publickey)`
- SSH anahtari GitHub hesabina eklenmemis.
- Alternatif olarak HTTPS + PAT kullan.

### `gh: command not found`
- `gh` zorunlu degil. Kurulumu manuel `git` komutlariyla da tamamlayabilirsin.
