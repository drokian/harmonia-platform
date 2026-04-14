# Isimlendirme Konvansiyonlari

## Branch Isimlendirme

| Tip | Format | Ornek |
|-----|--------|-------|
| Ozellik | `feature/<kisa-aciklama>` | `feature/dark-mode` |
| Hata duzeltme | `fix/<konu>` | `fix/login-redirect` |
| Dokumantasyon | `docs/<alan>` | `docs/api-reference` |
| Bakim | `chore/<konu>` | `chore/dep-update` |
| Demo surumu | `release/<versiyon>` | `release/v1.2.0` |

## Dosya ve Klasor Isimlendirme

- Kucuk harf, kelimeler arasi tire: `my-feature.ts`, `api-client/`
- Sabit degerler buyuk harf: `TEMPLATE_VERSION`, `CHANGELOG.md`
- Gizli dosyalar nokta ile baslar: `.env.example`, `.gitignore`
- Konfigurasyon dosyalari onceki kurali izler; framework standardi onceliklidir

## Ortam Degiskenleri

- Buyuk harf, kelimeler arasi alt cizgi: `DATABASE_URL`, `API_KEY`, `AUTH_SECRET`
- Prefix ile amac belirtilir: `NEXT_PUBLIC_*` (public), `APP_*` (uygulama seviyesi)

## Versiyon Etiketleri

- Semver: `vX.Y.Z` (ornek: `v1.0.0`, `v2.1.3`)
- Pre-release: `v1.0.0-rc.1`, `v2.0.0-beta.2`
- Template versiyonu `TEMPLATE_VERSION` dosyasiyla senkron olmali
