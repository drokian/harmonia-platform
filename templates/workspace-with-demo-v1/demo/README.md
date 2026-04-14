# Demo

Bu dizin, workspace-with-demo-v1 template'inden scaffold edilmis workspace'teki public demo repo'sunun baslangic iskeleti ve referansidir.

## Onemli

Gercek kullanim senaryosunda `demo/` bir **Git submodule** olarak eklenir. Scaffold asamasinda su siralama izlenir:

1. Scaffold script bu dizin icerigini (README ve `.gitkeep` dosyalari) otomatik temizler.
2. Ardindan: `git submodule add https://github.com/<org>/<repo>-demo demo`

> **Not:** Bu dizindeki dosyalar (README, `.gitkeep`) yalnizca template kaynak agacinda yer tutucu olarak bulunur. `git submodule add` komutunun calisabilmesi icin hedef workspace'te `demo/` dizini bos olmalidir; scaffold script bunu garantiler.

Scaffold kullanmadan manuel kurulum yapiyorsaniz once bu dizini bosaltip ardindan submodule komutunu calistirin.

## Guvenlik

Bu dizin **public** bir repoya isaret eder. Su kurallari daima gozet:

- `.env`, `secrets.*`, `*.key` ve benzeri dosyalar **asla** buraya kopyalanmaz.
- `scripts/verify-no-secrets-in-demo.ps1` ile duzenli tarama yapilir.
- Sync islemi yalnizca `scripts/sync-to-demo.ps1` uzerinden yapilir.
