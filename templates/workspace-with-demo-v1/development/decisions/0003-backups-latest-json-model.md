# ADR-0003: Yedekler Tek Dosya Modeli ile Yonetilir

**Durum:** Kabul edildi  
**Tarih:** 2026-04-14

## Baglam

Urun verisinin zamanlanmis veya manuel yedeklerinin nerede ve nasil tutulacagina karar verilmesi gerekti.

## Karar

Yedekler `backups/latest.json` olarak tek bir dosyada saklanir. Bu dosya Git tarafindan takip edilir. Gecmis yedekler demo sync sirasinda `demo_sync_denylist` ve sync script davranisi nedeniyle demo'ya kopyalanmaz.

## Gerekce

- **Basitlik:** Tek dosya modeli, yedek sayisinin birikmesini ve depoya sismesini onler.
- **Takip edilebilirlik:** `latest.json` commit gecmisinde gorunur; kim, ne zaman yedek aldi izlenebilir.
- **Demo koruması:** `backups/` yolu demo sync sirasinda denylist ve sync script kontrolleri nedeniyle demo'ya kopyalanmaz.

## Sinirlar ve Dikkat Edilecekler

- `latest.json` buyudukce (50 MB+) Git performansi dusar; bu noktada Git LFS gecisi onerilir.
- Coklu versiyonlama gerekiyorsa `backups/YYYY-MM-DD.json` formatiyla arsivleme v2'de eklenebilir.
- Backup dosyalari secrets barindiriyorsa `.gitignore`'a eklenmeli ve `forbidden_globs` kontrolunden gecmelidir.

## Sonuclar

- `backups/latest.json` manifest `required_files` listesinde tanimlidir; dosyanin varligi yerel `validate-template.ps1` ile dogrulanir.
- `backups/` altindaki icerik demo sync sirasinda denylist kontrolunden gecemez ve demo'ya aktarilmaz.
