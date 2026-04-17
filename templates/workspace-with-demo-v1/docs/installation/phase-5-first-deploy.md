# Asama 5 - Ilk Deploy

Bu asama, demo submodule'unun bagli oldugu public repoda ilk yayinlamayi (GitHub Pages) tamamlar.

## Onkosul Kontrolu

Bu asamadan baslamalisin eger:
- Asama 4 dogrulama scriptleri exit code 0 ile tamamlandiysa.
- Demo repo public ve erisilebilir durumdaysa.
- Demo iceriginde yayinlanabilir statik dosyalar mevcutsa.

## Adim-adim Komutlar

### Bash

```bash
cd my-product/demo
git status
git add .
if ! git diff --cached --quiet; then git commit -m "chore(demo): first deploy baseline"; else echo "No changes to commit"; fi
git push origin main
```

### PowerShell

```powershell
Set-Location my-product/demo
git status
git add .
if (-not (git diff --cached --quiet; $LASTEXITCODE -eq 0)) {
	git commit -m "chore(demo): first deploy baseline"
} else {
	Write-Host "No changes to commit"
}
git push origin main
```

GitHub Pages ayari:
1. Demo reposunda `Settings > Pages` ekranina git.
2. Source olarak `Deploy from a branch` sec.
3. Branch `main`, folder `/ (root)` sec.
4. Save et ve ilk deployment tamamlanana kadar bekle.

Workspace tarafinda iz kaydi (opsiyonel):

### Bash

```bash
cd ..
git add demo
if ! git diff --cached --quiet; then git commit -m "chore(workspace): first demo deploy live"; else echo "No changes to commit"; fi
git push origin main
```

### PowerShell

```powershell
Set-Location ..
git add demo
if (-not (git diff --cached --quiet; $LASTEXITCODE -eq 0)) {
	git commit -m "chore(workspace): first demo deploy live"
} else {
	Write-Host "No changes to commit"
}
git push origin main
```

## Bu Asama Bittiginde

- [ ] Demo repo ilk deploy commit'ini aldi.
- [ ] GitHub Pages aktif ve URL uzerinden erisilebilir.
- [ ] Workspace repo, yeni submodule commit pointer'ini guncelledi.
- [ ] Temel smoke kontrolu yapildi (ana sayfa aciliyor, statik dosyalar yukleniyor).

## Sorun mu Yasiyorsun?

### Pages URL 404 donuyor
- Deploy daha tamamlanmamis olabilir, Actions loglarini kontrol et.
- Branch/folder seciminin `main` ve `/ (root)` oldugunu dogrula.

### Demo'da commit yok ama workspace pointer degisti
- Submodule icinde beklenmeyen degisiklik olabilir.
- `demo/` icinde `git status` ile farklari incele.

### CSS/asset dosyalari yuklenmiyor
- Relative path kullanimi yanlis olabilir.
- `index.html` icindeki linkleri root-relative degil, dosya-relative tut.
