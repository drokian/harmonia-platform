# Asama 2 - Public Demo Repo

Bu asama, public demo reposunu hazirlar ve ilk baseline icerigi publish eder.

## Onkosul Kontrolu

Bu asamadan baslamalisin eger:
- Asama 1 tamamlandiysa.
- Public demo repo henuz olusturulmadiysa.
- Demo icerigini ayri bir public repoda tutmak istiyorsan.

## Adim-adim Komutlar

Ornek adlar:
- Demo repo: `my-product-demo`
- Harmonia yolu: `<harmonia_root>`

### Bash

```bash
git clone git@github.com:<org>/my-product-demo.git
cd my-product-demo
cp -r <harmonia_root>/templates/workspace-with-demo-v1/demo/* .
git add .
git commit -m "chore(demo): initial public demo baseline"
git push origin main
```

### PowerShell

```powershell
git clone git@github.com:<org>/my-product-demo.git
Set-Location my-product-demo
Copy-Item "<harmonia_root>/templates/workspace-with-demo-v1/demo/*" -Destination . -Recurse -Force
git add .
git commit -m "chore(demo): initial public demo baseline"
git push origin main
```

Opsiyonel temizlik:
- Ayrica klonladigin bu demo klasorunu silebilirsin.
- Sonraki asamada demo, workspace icinde submodule olarak yonetilecek.

## Bu Asama Bittiginde

- [ ] Public demo repo olustu ve erisilebilir.
- [ ] Minimal demo baseline (`index.html`, `styles.css`, `README.md`) pushlandi.
- [ ] Demo repo tek basina acildiginda statik icerik gorunuyor.

## Sorun mu Yasiyorsun?

### Public repo olustururken isim cakismasi
- Farkli bir isim sec (`my-product-demo-web` gibi).

### `remote: Permission denied`
- Public repo icin push yetkini kontrol et.

### `README.md` disinda dosya gitmedi
- Kopyalama komutunda wildcard veya path hatasi olabilir.
- `git status` ile beklenen dosyalari teyit et.
