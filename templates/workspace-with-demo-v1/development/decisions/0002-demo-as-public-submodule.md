# ADR-0002: Demo Kamuya Acik Submodule Olarak Tasarlanir

**Durum:** Kabul edildi  
**Tarih:** 2026-04-14

## Baglam

Urunun kamuya acik bir demo sunumu gerekmektedir. Bu demo'nun workspace ile nasil iliskilendirileceğine karar verilmesi gerekti.

## Karar

Demo, ayri bir **public** GitHub reposunda yasayan ve workspace'e **Git submodule** olarak baglanan bagimsiz bir repo olarak yonetilir.

```
workspace/ (private)
└── demo/  ← git submodule → github.com/org/my-product-demo (public)
```

## Gerekce

- **GitHub Pages uyumu:** Public repo, GitHub Pages ile dogrudan hosteleme saglar.
- **Bagimsiz commit gecmisi:** Demo repo kendi commit gecmisine sahiptir; workspace gecmisi karisiklik yaratmaz.
- **Gozlemlenebilirlik:** Public demo repo'nun commit logunu dogrudan gorulebilir; workspace ozel kalir.
- **Submodule ile kontrol:** Workspace hangi demo commit'inin aktif oldugunu bilir; istenmeden ileri gitme riski yoktur.

## Alternatifler Degerlendirmesi

| Alternatif | Neden Reddedildi |
|------------|-----------------|
| Demo workspace icinde alt klasor | Public gorunurluk saglanamaz |
| Demo ayri repo, submodule yok | Hangi versiyonun aktif oldugu belirsiz |
| Monorepo | Tum icerigi public yapmak zorunda kalinir |

## Sonuclar

- Scaffold asamasi 2 ve 3 bu adimi tanimlar (docs/installation/phase-2 ve phase-3).
- `sync-to-demo.ps1` workspace'ten demo'ya **denetimli** kopyalama yapar.
- Demo klasoru template kaynaginda statik placeholder olarak durur; scaffold sirasinda submodule'e donusturulur.
