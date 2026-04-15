# Asama 3 - Submodule Bagi

Bu asama, public demo reposunu private workspace altinda `demo/` submodule'u olarak baglar.

## Onkosul Kontrolu

Bu asamadan baslamalisin eger:
- Asama 1 ve Asama 2 tamamlandiysa.
- Workspace icindeki mevcut `demo/` placeholder klasoru duruyorsa.
- Public demo repo URL'in hazirsa.

## Adim-adim Komutlar

Ornek URL:
- `git@github.com:<org>/my-product-demo.git`

### Bash

```bash
cd my-product
rm -rf demo
git submodule add git@github.com:<org>/my-product-demo.git demo
git add .gitmodules demo
git commit -m "chore(workspace): link demo repository as submodule"
git push origin main
```

### PowerShell

```powershell
Set-Location my-product
if (Test-Path .\demo) {
	Remove-Item .\demo -Recurse -Force
}
git submodule add git@github.com:<org>/my-product-demo.git demo
git add .gitmodules demo
git commit -m "chore(workspace): link demo repository as submodule"
git push origin main
```

## Bu Asama Bittiginde

- [ ] Workspace icindeki `demo/` artik submodule olarak baglandi.
- [ ] `.gitmodules` dosyasi olustu.
- [ ] Workspace repo commit ve push islemi tamamlandi.
- [ ] `git submodule status` cikti veriyor.

## Sorun mu Yasiyorsun?

### `fatal: 'demo' already exists and is not a valid git repo`
- Placeholder `demo/` klasoru tam silinmemis olabilir.
- Klasoru temizleyip submodule add komutunu tekrar calistir.

### Submodule URL degistirme ihtiyaci
- `.gitmodules` dosyasini guncelleyip `git submodule sync --recursive` calistir.

### CI submodule cekmiyor
- CI tarafinda checkout adiminda submodule ayari aktif edilmeli (`submodules: recursive`).
