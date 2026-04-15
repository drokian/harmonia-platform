# Asama 1 - Private Workspace Repo

Bu asama, ana private workspace reposunun olusturulmasini ve template iceriginin eklenmesini kapsar.

## Onkosul Kontrolu

Bu asamadan baslamalisin eger:
- Asama 0 tamamlandiysa.
- Private workspace repo henuz olusturulmadiysa.
- Elinde bos veya yeni olusturulmus bir workspace klasoru varsa.

## Adim-adim Komutlar

Asagidaki komutlarda ornek adlar kullanilir:
- Workspace repo: `my-product`
- Harmonia yolu: `<harmonia_root>`

### Bash

```bash
git clone git@github.com:<org>/my-product.git
cd my-product
cp -r <harmonia_root>/templates/workspace-with-demo-v1/* .
cp <harmonia_root>/templates/workspace-with-demo-v1/.gitignore .
cp <harmonia_root>/templates/workspace-with-demo-v1/.editorconfig .
git add .
git commit -m "chore(template): scaffold workspace-with-demo-v1 baseline"
git push origin main
```

### PowerShell

```powershell
git clone git@github.com:<org>/my-product.git
Set-Location my-product
Copy-Item "<harmonia_root>/templates/workspace-with-demo-v1/*" -Destination . -Recurse -Force
Copy-Item "<harmonia_root>/templates/workspace-with-demo-v1/.gitignore" -Destination . -Force
Copy-Item "<harmonia_root>/templates/workspace-with-demo-v1/.editorconfig" -Destination . -Force
git add .
git commit -m "chore(template): scaffold workspace-with-demo-v1 baseline"
git push origin main
```

## Bu Asama Bittiginde

- [ ] Private workspace repo yerelde klonlandi.
- [ ] Template dosyalari workspace kokune kopyalandi.
- [ ] Ilk scaffold commit'i olustu ve remote'a pushlandi.
- [ ] `docs/`, `development/`, `scripts/`, `demo/` klasorleri gorunur durumda.

## Sorun mu Yasiyorsun?

### `fatal: repository not found`
- Repo adi veya org yanlis olabilir.
- Repo private ise erisim yetkini kontrol et.

### Kopyalama sonrasi gizli dosyalar eksik
- `.gitignore` ve `.editorconfig` ayri kopyalandigindan emin ol.

### `nothing to commit`
- Dosyalar dogru dizine kopyalanmamis olabilir.
- `git status` ile degisiklikleri kontrol et.
