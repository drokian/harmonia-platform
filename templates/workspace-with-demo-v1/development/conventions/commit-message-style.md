# Commit Mesaji Stili

Conventional Commits v1.0.0 kullanilir.

## Format

```
<tip>(<kapsam>): <konu>

<gövde — opsiyonel>

<alt bilgi — opsiyonel>
```

## Tipler

| Tip | Aciklama |
|-----|----------|
| `feat` | Yeni ozellik |
| `fix` | Bug duzeltme |
| `docs` | Yalniz dokumantasyon degisikligi |
| `style` | Kod stilini etkileyen degisiklik (icerik yok) |
| `refactor` | Ne hata fix ne ozellik; yeniden yapilandirma |
| `test` | Test ekleme veya duzeltme |
| `chore` | Build sureci, bagimlilik guncellemeleri vb. |

## Kapsam Ornekleri

`workspace`, `demo`, `scripts`, `docs`, `manifest`, `backups`, `stacks`

## Ornekler

```
feat(workspace): kullanici kimlik dogrulama modulu eklendi

fix(demo): anasayfa resim yolu duzeltildi

docs(scripts): sync-to-demo kullanim ornegi eklendi

chore(manifest): required_files listesi guncellendi
```

## Kurallari

- Konu kisa ve emir kipinde: "Ekle", "Duzenle", "Sil" değil "eklendi", "duzeltildi" tercih edilir
- Konu satiri 72 karakteri gecmemeli
- Govde neden degisiklik yapildigini aciklar, ne yapildigini degil (onu kod gosterir)
- Breaking change: `BREAKING CHANGE:` alt bilgisi ile isaretlenir
