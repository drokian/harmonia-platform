# Surum Nasil Yapilir

Bu rehber `TEMPLATE_VERSION` bump'i ve release branch'i akisini tanimlar.

## Onkosullar

- `develop` branch'i guncel ve kararlı
- Tum WD-xxx kalemleri tamamlanmis
- `TEMPLATE_CHANGELOG.md` guncel

## Adimlar

### 1. Release branch'i ac

```bash
git checkout develop
git pull origin develop
git checkout -b release/vX.Y.Z
```

### 2. Versiyon bump yap

```powershell
# Kuru calismayla once gor
pwsh ./scripts/bump-template-version.ps1 -Bump minor -DryRun

# Gercekles
pwsh ./scripts/bump-template-version.ps1 -Bump minor
```

### 3. Changelog TODO satirini duzenle

`TEMPLATE_CHANGELOG.md` icindeki `- TODO: bu surumde...` satirini gercek bir ozet ile degistir:

```markdown
## v1.1.0 - 2026-05-01

### Eklendi

- Kurulum rehberi guncellendi (docs/installation/index.md)
- Development katmani: ADR'lar, konvansiyonlar, rehberler
```

### 4. Dogrulama yap

```powershell
pwsh ./scripts/validate-template.ps1
pwsh ./scripts/verify-no-secrets-in-demo.ps1
```

### 5. Commit ve push

```bash
git add -A
git commit -m "release(template): v1.1.0"
git push origin release/vX.Y.Z
```

### 6. PR + merge

- `main`'e PR ac
- Review sonrasi merge
- **Merge sonrasi tag at:** `vX.Y.Z`

### 7. Back-merge

```bash
git checkout develop
git merge main
git push origin develop
```

## Sik Karsilasilan Sorunlar

**`TEMPLATE_VERSION` ve README baseline uyusmuyor:** `bump-template-version.ps1` her ikisini de birlikte gunceller; elle duzenleme yerine script kullanin.

**Changelog TODO kaldi:** Release oncesi manuel kontrolde veya review sirasinda bu durum yakalanir; TODO satirini gercek ozet ile degistirin.
