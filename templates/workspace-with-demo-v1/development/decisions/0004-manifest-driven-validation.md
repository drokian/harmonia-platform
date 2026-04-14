# ADR-0004: Template Butunlugu Manifest Tarafindan Denetlenir

**Durum:** Kabul edildi  
**Tarih:** 2026-04-14

## Baglam

Template'in gerektirdigi klasor ve dosyalarin her zaman mevcut olup olmadigini dogrulamak icin bir yontem gerekti.

## Karar

`.github/template-manifest.yml` tek kaynak olarak tanimlanan `required_dirs`, `required_files`, `forbidden_globs` ve `demo_sync_denylist` listelerini barindirir. Mevcut dogrulama bu listeyi lokal `validate-template.ps1` scripti araciligiyla dosya sistemiyle karsilastirir.

## Gerekce

- **Tek kaynak:** Manifest'te tanimlanan kurallar su an lokal script (`validate-template.ps1`) tarafindan okunur; kural hardcoded olarak farkli bir yerde tekrar edilmez.
- **Erken geri bildirim:** PR'a girmeden once `pwsh ./scripts/validate-template.ps1` ile yerel dogrulama yapilabilir.
- **Denetlenebilirlik:** Manifest'te tanimlanmamis bir eklenti veya cikartma kolayca gordulur; review sirasinda fark edilmesi kolaydir.

## Alternatifler Degerlendirmesi

| Alternatif | Neden Reddedildi |
|------------|-----------------|
| Yalnizca CI kontrolu | Lokal gelistiriciye aninda geri bildirim saglanamaz |
| Kod ici (hardcoded) kontrol | Guncellemeler script degisikliği gerektirir; manifest daha esnek |
| Ayri schema dosyasi | YAML manifest yeterlice ifadelidir; ek format gereksiz karma yasatir |

## Sonuclar

- Manifest degisikliklerinde lokal dogrulama raporu hemen alinabilir; eksik dizin veya dosyalar hizli gorulur.
- `demo_sync_denylist` manifest'te tanimlanir; `sync-to-demo.ps1` runtime'da bu listeyi okur.
- `forbidden_globs` sadece template kontrolu icin; `demo_sync_denylist` sadece sync zamani icin.
