# ADR-0001: Workspace Ana Repo Olarak Tasarlanir

**Durum:** Kabul edildi  
**Tarih:** 2026-04-14

## Baglam

Urun gelistirilirken iki repo gereksinimi ortaya cikti: biri ozel ve tam icerigi barindiran, biri kamuya acik ve demo amacli. Bu ikisinin nasil iliskilendirileceğine karar verilmesi gerekti.

## Karar

Ana uretim calismalari **private** bir repo'da (workspace) yapilir. Bu repo; kaynak kodu, sirlar, operasyon notlari, yedekler ve her turlu ozel bilgiyi barindirir.

## Gerekce

- Tek kaynak noktasi: tum gelistirme, test ve release islemleri bu repo uzerinden yurutulur.
- Sirlar repo disina cikmaz; workspace her zaman yetkili baslangic noktasidir.
- Demo repo yalnizca workspace'in secilmis alt kumesini yayinlar; kopyalama sync-to-demo.ps1 tarafindan denetlenir.

## Alternatifler Degerlendirmesi

| Alternatif | Neden Reddedildi |
|------------|-----------------|
| Iki kardes repo (demo + commercial ayri) | Workspace-demo iliskisi parent-child; kardes degil |
| Demo repo birincil, workspace fork | Demo public oldugundan hassas bilgi riski tasir |

## Sonuclar

- `templates/workspace-with-demo-v1/` yapisi workspace'i kok olarak varsayar.
- Demo her zaman submodule olarak workspace altina baglanir (ADR-0002).
- `.gitignore` ve manifest forbidden_globs birlikte workspace korumasini saglar.
