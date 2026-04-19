# Harmonia Scripts - Kullanim Dokumantasyonu

Bu dokuman, `development/scripts` altindaki operasyon scriptlerinin amacini,
parametrelerini ve ornek kullanimlarini tek yerde toplar.

## Icindekiler

- [Gereksinimler](#gereksinimler)
- [Script Listesi](#script-listesi)
- [1) review-collector_v0.2.sh](#1-review-collector_v02sh)
- [2) reply-resolve_v0.2.sh](#2-reply-resolve_v02sh)
- [3) verify-review-threads_v0.2.sh](#3-verify-review-threads_v02sh)
- [4) cleanup_v0.2.sh](#4-cleanup_v02sh)
- [5) create-repo_v0.3.sh](#5-create-repo_v03sh)
- [Onerilen Operasyon Akisi](#onerilen-operasyon-akisi)
- [Gelecek Gelistirme Notu](#gelecek-gelistirme-notu)
- [Ayirma Zamani Hazirlik Notlari](#ayirma-zamani-hazirlik-notlari)

## Gereksinimler

- Bash 4+
- GitHub CLI (`gh`) ve aktif oturum (`gh auth status`)
- `jq`

Not: Windows ortaminda WSL/bash veya Git Bash kullanilmasi onerilir.

## Script Listesi

- `review-collector_v0.2.sh`
- `reply-resolve_v0.2.sh`
- `verify-review-threads_v0.2.sh`
- `cleanup_v0.2.sh`
- `create-repo_v0.3.sh`

## 1) review-collector_v0.2.sh

Amac:
- PR uzerindeki review comment, review event ve review thread verilerini toplar.
- Ciktilari `development/ai-review/<repo>/PR<numara>/` altina yazar.

Parametreler:

| Parametre | Zorunlu | Aciklama |
|---|---|---|
| `owner` | Evet | GitHub owner (org/user) |
| `repo` | Evet | Repository adi |
| `pr_number` | Evet | PR numarasi (sayisal) |

Kullanim:

```bash
bash scripts/review-collector_v0.2.sh <owner> <repo> <pr_number>
```

Urettigi temel dosyalar:
- `copilot-comments.json`
- `copilot-reviews.json`
- `review-threads.json`
- `copilot-review.md`

## 2) reply-resolve_v0.2.sh

Amac:
- Copilot yorumlarina toplu/filtreli cevap verir.
- Ilgili review thread'lerini resolve eder.

Parametreler:

| Parametre | Zorunlu | Aciklama |
|---|---|---|
| `owner` | Evet | GitHub owner (org/user) |
| `repo` | Evet | Repository adi |
| `pr_number` | Evet | PR numarasi (sayisal) |
| `--mode` | Evet | `all`, `filter-text`, `filter-regex`, `map` |
| `--reply-file` | Moda bagli | `all`/`filter-*` modlari icin reply metni dosyasi |
| `--filter` | Moda bagli | `filter-text` modunda aranan metin |
| `--regex` | Moda bagli | `filter-regex` modunda regex pattern |
| `--map-file` | Moda bagli | `map` modunda pattern->reply JSON dosyasi |

Kullanim (all mode):

```bash
bash scripts/reply-resolve_v0.2.sh <owner> <repo> <pr_number> \
  --mode all \
  --reply-file <reply.txt>
```

Kullanim (map mode):

```bash
bash scripts/reply-resolve_v0.2.sh <owner> <repo> <pr_number> \
  --mode map \
  --map-file <reply-map.json>
```

Notlar:
- Map modunda bir comment birden fazla pattern ile eslesirse script fail-fast calisir.
- Script, collector tarafindan uretilen JSON ciktilarini bekler.

## 3) verify-review-threads_v0.2.sh

Amac:
- PR review thread durumlarini dogrular.
- Acik thread kaldiysa non-zero exit code dondurur.

Parametreler:

| Parametre | Zorunlu | Aciklama |
|---|---|---|
| `owner` | Evet | GitHub owner (org/user) |
| `repo` | Evet | Repository adi |
| `pr_number` | Evet | PR numarasi (sayisal) |
| `--show-resolved` | Hayir | Resolve edilmis thread listesini de yazar |

Kullanim:

```bash
bash scripts/verify-review-threads_v0.2.sh <owner> <repo> <pr_number>
```

Opsiyonel:

```bash
bash scripts/verify-review-threads_v0.2.sh <owner> <repo> <pr_number> --show-resolved
```

Ciktilar:
- `review-thread-verification.json`
- `review-thread-verification.md`

## 4) cleanup_v0.2.sh

Amac:
- Belirli bir repo + PR icin `development/ai-review/<repo>/PR<numara>` klasorunu temizler.

Parametreler:

| Parametre | Zorunlu | Aciklama |
|---|---|---|
| `repo` | Evet | Repository adi |
| `pr_number` | Evet | PR numarasi (sayisal) |

Kullanim:

```bash
bash scripts/cleanup_v0.2.sh <repo> <pr_number>
```

## 5) create-repo_v0.3.sh

Amac:
- Yerel calisma dizinini GitHub repo yapisina baglayan bootstrap adimlarini uygular.
- Dry-run destekler.

Parametreler:

| Parametre | Zorunlu | Aciklama |
|---|---|---|
| `--dry-run` | Hayir | Yazma islemleri yerine planlanan adimlari loglar |
| `hesap` | Evet | GitHub user/org adi |
| `repo-adi` | Evet | Olusturulacak repo adi |
| `public|private` | Evet | Repo gorunurlugu |

Kullanim:

```bash
bash scripts/create-repo_v0.3.sh [--dry-run] <hesap> <repo-adi> <public|private>
```

## Onerilen Operasyon Akisi

1. `review-collector_v0.2.sh` ile veriyi topla.
2. Kod duzeltmelerini tamamla.
3. `reply-resolve_v0.2.sh` ile yorumlara yanit ver ve thread resolve et.
4. `verify-review-threads_v0.2.sh` ile thread durumunu dogrula.
5. Gerekirse `cleanup_v0.2.sh` ile PR cikti klasorunu temizle.

## Gelecek Gelistirme Notu

Ileride bu scriptler icin daha moduler bir yapiya gecilecektir:
- Her script icin ayri klasor yapisi
- Her script icin ayri paketleme/surumleme modeli
- Ortak kutuphane (logging, arg-parse, gh api wrapper, retry/backoff) ayrimi

Bu gecis sonrasi bu dokuman, yeni klasor/paket yapisina gore guncellenecektir.

## Ayirma Zamani Hazirlik Notlari

Scriptleri ayirma/paketleme asamasinda isleri kolaylastirmak icin asagidaki sirayla ilerlenmesi onerilir:

1. Ortak fonksiyonlari `lib/` altina tasiyin (log, arg parse, retry/backoff, gh wrappers).
2. Her script icin ayri klasor olusturun (`scripts/<script-adi>/`).
3. Her klasorde en az su dosyalari standardize edin:
  - `README.md`
  - `CHANGELOG.md`
  - `run.sh`
  - `tests/` (smoke test + happy path)
4. Script bazli semver uygulayin (`v0.x`, `v1.x`) ve surumleri dosya adindan ayirip metadata dosyasina tasiyin.
5. Gecis bitince bu merkezi README'yi sadece yonlendirme dokumani olarak sadeleştirin.
