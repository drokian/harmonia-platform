# Versiyonlama Stratejisi

## Semantic Versioning (Semver)

Format: `vMAJOR.MINOR.PATCH`

| Segment | Arttirilma kosulu |
|---------|------------------|
| `MAJOR` | Geriye donuk uyumsuz degisiklik |
| `MINOR` | Geriye donuk yeni ozellik eklendi |
| `PATCH` | Geriye donuk hata duzeltme |

## Template Versiyonu

`TEMPLATE_VERSION` dosyasi semver'i saklar (ornek: `v1.0.0`).

Bu dosya degistirildiginde senkron tutulmasi gerekenler:
- `TEMPLATE_CHANGELOG.md` — ilgili versiyon satiri
- `README.md` — `Current baseline: vX.Y.Z` satiri

Otomatik guncelleme icin script kullanin:

```powershell
# Patch bump
pwsh ./scripts/bump-template-version.ps1 -Bump patch

# Minor bump
pwsh ./scripts/bump-template-version.ps1 -Bump minor

# Manuel versiyon
pwsh ./scripts/bump-template-version.ps1 -Version v2.0.0
```

`-DryRun` bayragi ile ne olacagini once gordukten sonra gerceklestirin.

## Surum Akisi

1. `release/vX.Y.Z` branch'i ac
2. `bump-template-version.ps1` calistir
3. `TEMPLATE_CHANGELOG.md` icindeki `TODO` satirini gercek ozet ile degistir
4. PR ac → `main`'e merge
5. Tag at: `vX.Y.Z`
6. `main`'den `develop`'a back-merge

## Demo Versiyonu

Demo repo semver'i workspace ile senkronize olmak zorunda degildir; demo kendi `package.json` versiyonunu bagimsiz yonetir. Ancak buyuk surumlerde hizalama onerilir.
