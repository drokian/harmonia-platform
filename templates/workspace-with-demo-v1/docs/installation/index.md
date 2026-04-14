# Kurulum

Bu bolum workspace kurulum adimlarini icerir.

## Onkosullar

- Git
- PowerShell 7+ (`pwsh`)
- GitHub CLI (`gh`) — opsiyonel, PR olusturmak icin

## Adimlar

1. Harmonia scaffold scripti ile yeni workspace olusturun (script WD-005 PR'inda eklenecektir).
2. Scaffold, `demo/` placeholder dosyalarini otomatik temizler; ardindan demo submodule'u ekleyin:
   ```bash
   git submodule add https://github.com/<org>/<repo>-demo demo
   ```
3. Projenin ihtiyac duydugu degiskenlerle `.env` dosyasini olusturun.
4. Template yapisini dogrulayin (script WD-002 PR'inda eklenecektir):
   ```powershell
   pwsh ./scripts/validate-template.ps1
   ```

> **Not:** `scripts/validate-template.ps1` ve diger operasyon scriptleri WD-002 PR'inda,
> CI workflow dosyalari ise WD-003 PR'inda tamamlanacaktir.
