# Demo

Bu dizin, workspace-with-demo-v1 template'inden scaffold edilmis workspace'teki public demo repo'sunun baslangic iskeleti ve referansidir.

## Onemli

Gercek kullanim senaryosunda `demo/` bir **Git submodule** olarak eklenir:

```bash
git submodule add https://github.com/<org>/<repo>-demo demo
```

Bu dizindeki icerik, submodule kurulduktan sonra demo repo'sunun kendi deposuyla yonetilir.

## Guvenlik

Bu dizin **public** bir repoya isaret eder. Su kurallari daima gozet:

- `.env`, `secrets.*`, `*.key` ve benzeri dosyalar **asla** buraya kopyalanmaz.
- `scripts/verify-no-secrets-in-demo.ps1` ile duzenli tarama yapilir.
- Sync islemi yalnizca `scripts/sync-to-demo.ps1` uzerinden yapilir.
