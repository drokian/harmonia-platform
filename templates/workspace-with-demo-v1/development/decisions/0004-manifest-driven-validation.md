# ADR-0004: Template Butunlugu Manifest Tarafindan Denetlenir

**Durum:** Kabul edildi  
**Tarih:** 2026-04-14

## Baglam

Template'in gerektirdigi klasor ve dosyalarin her zaman mevcut olup olmadigini dogrulamak icin bir yontem gerekti.

## Karar

`.github/template-manifest.yml` tek kaynak olarak tanimlanan `required_dirs`, `required_files`, `forbidden_globs` ve `demo_sync_denylist` listelerini barindirir. `template-validation.yml` CI workflow'u her PR'da bu listeyi dosya sistemiyle karsilastirir.

## Gerekce

- **Tek kaynak:** Manifest'te tanimlanan kurallar hem CI hem de lokal script (`validate-template.ps1`) tarafindan okunur; kural iki yerde yazilmaz.
- **Erken geri bildirim:** PR'a girmeden once `pwsh ./scripts/validate-template.ps1` ile yerel dogrulama yapilabilir.
- **Denetlenebilirlik:** Manifest'te tanimlanmamis bir eklenti veya cikartma kolayca gordulur; review sirasinda fark edilmesi kolaydir.

## Alternatifler Degerlendirmesi

| Alternatif | Neden Reddedildi |
|------------|-----------------|
| Yalnizca CI kontrolu | Lokal gelistiriciye aninda geri bildirim saglanamaz |
| Kod ici (hardcoded) kontrol | Guncellemeler script degisikliği gerektirir; manifest daha esnek |
| Ayri schema dosyasi | YAML manifest yeterlice ifadelidir; ek format gereksiz karma yasatir |

## Sonuclar

- Manifest degisikliklerinde (dizin ekleme/cikarma) CI fail olur; PR bloklenir.
- `demo_sync_denylist` manifest'te tanimlanir; `sync-to-demo.ps1` runtime'da bu listeyi okur.
- `forbidden_globs` sadece template kontrolu icin; `demo_sync_denylist` sadece sync zamani icin.
