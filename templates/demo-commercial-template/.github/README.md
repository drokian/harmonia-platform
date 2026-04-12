# Shared GitHub Notes

Bu klasor, workspace seviyesinde tutulacak GitHub surec taslaklari icindir.

Gercek repo workflow dosyalari zamanla ilgili depoya tasinabilir.

Bu template'te asagidaki workflow dosyalari gelir:

- `workflows/ci.yml`
- `workflows/release.yml`
- `workflows/submodule-sync.yml`
- `workflows/template-validation.yml`

`workflows/release.yml`, `TEMPLATE_VERSION` ile senkron calisir, uygun tag'i olusturur ve GitHub'da draft release açar.

Template dogrulama listeleri `.github/template-manifest.yml` dosyasindan okunur.