# development/

Bu klasor **yerel ve ozel** surec notlarini barindirir. Hedef workspace'te `.gitignore` tarafindan hariç tutulur; uzak repoya gitmez.

## Icerik

| Klasor | Aciklama |
|--------|----------|
| `backlogs/` | Template-ici is kayitlari (WD-xxx numaralari) |
| `sprints/` | Aktif sprint takibi ve arsiv |
| `decisions/` | Mimari karar kayitlari (ADR) |
| `conventions/` | Isimlendirme, klasor yapisi, commit stili, versiyonlama |
| `guides/` | Adim-adim islem rehberleri |
| `checklists/` | Surum oncesi ve kurulum kontrol listeleri |
| `glossary/` | Terimler sozlugu |
| `scripts/` | Yardimci gelistirici scriptleri (sadece lokal kulanim) |

## Onemli Not

Bu klasor **template kaynaginda** gitlenir (Harmonia repo'su bu kuraldan muaf).
Scaffold edilen hedef workspace'lerde `.gitignore` kurali devreye girer ve `development/` remote'a gitmez.

Bu davranis kasitlidir: calisma notlari, backlog ve kararlar workspace'in ozel dokumanlaridir.
