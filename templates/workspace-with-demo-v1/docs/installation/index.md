# Kurulum

Bu bolum workspace kurulum adimlarini icerir.

## Onkosullar

- Git
- PowerShell 7+ (`pwsh`)
- GitHub CLI (`gh`) — opsiyonel, PR olusturmak icin

## Adimlar

1. Bu template'den scaffold scripti ile yeni workspace olusturun.
2. `demo/` submodule'u ayarlayın: `git submodule add <demo-repo-url> demo`
3. `.env` dosyasini olusturun (`.env.example` sablonundan).
4. `pwsh ./scripts/validate-template.ps1` ile yapiyi dogrulayin.
