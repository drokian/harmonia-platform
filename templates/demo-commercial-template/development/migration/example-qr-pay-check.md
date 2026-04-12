# Example Migration: QR Pay Check

Bu ornek, tek bir kaynak repodan demo/commercial ayrismasi icin uygulanabilir bir senaryo sunar.

## 1. Varsayilan Kaynak Proje Yapisi

```text
qr-pay-check/
├── src/
│   ├── api/
│   │   ├── health.ts
│   │   ├── qr-validate.ts
│   │   ├── merchant-dashboard.ts
│   │   └── partner-pricing.ts
│   ├── core/
│   │   ├── qr-parser.ts
│   │   └── fraud-score.ts
│   ├── ui/
│   │   ├── landing.tsx
│   │   ├── demo-check.tsx
│   │   └── billing.tsx
│   └── config/
│       ├── env.ts
│       └── secrets.ts
├── docs/
│   ├── public-setup.md
│   ├── integration-private.md
│   └── support-runbook.md
├── tests/
│   ├── smoke/
│   └── enterprise/
└── package.json
```

## 2. Hedef Karar Matrisi

| Source | Target | Neden |
| --- | --- | --- |
| src/api/health.ts | demo + commercial | Ortak saglik endpoint'i |
| src/api/qr-validate.ts | demo + commercial | Demo ve urun akisi icin gerekli |
| src/api/merchant-dashboard.ts | commercial only | Musteri paneli, private ozellik |
| src/api/partner-pricing.ts | commercial only | Fiyatlama mantigi public olmamali |
| src/core/qr-parser.ts | demo + commercial | Ortak cekirdek |
| src/core/fraud-score.ts | commercial only | Ticari deger ureten model |
| src/ui/landing.tsx | demo + commercial | Her iki tarafta da giris ekrani |
| src/ui/demo-check.tsx | demo + commercial | Demo akisinda gerekli |
| src/ui/billing.tsx | commercial only | Odeme ve abonelik sadece commercial |
| src/config/env.ts | demo + commercial | Ortak env semasi |
| src/config/secrets.ts | remove | Secret degeri source control'da tutulmamali |
| docs/public-setup.md | demo + commercial | Kurulum adimi ortak baslangic olabilir |
| docs/integration-private.md | commercial only | Private entegrasyon dokumani |
| docs/support-runbook.md | development only | Ekip ici operasyon notu |
| tests/smoke/* | demo + commercial | Temel dogrulama testleri |
| tests/enterprise/* | commercial only | Kurumsal ozellik testleri |

## 3. Uygulama Adimlari

1. Yeni workspace olustur:

```powershell
powershell -ExecutionPolicy Bypass -File .\development\scripts\scaffold-demo-commercial.ps1 `
  -TargetPath "D:\work\qr-pay-check-workspace" `
  -Stack nextjs-app `
  -InitGitRepos
```

2. Kaynak projeden dosyalari hedefe tasi:
- `demo + commercial` secilenleri iki repoya da kopyala
- `commercial only` secilenleri sadece commercial repoya kopyala
- `development only` secilenleri `development/` altina tası

3. Secret temizligi yap:
- `secrets.ts` gibi dosyalari tasima
- gerekli degiskenleri `.env.example` dosyasi ile temsil et

4. Repo bazli README guncelle:
- demo README: public sinirlar, ozellik kisitlari
- commercial README: tam ozellik, entegrasyon ve teslim adimlari

5. Ayrik test calistir:
- demo repoda smoke testler
- commercial repoda smoke + enterprise testler

## 4. Beklenen Cikis

- Demo repo public'e acilmaya hazir
- Commercial repo private release'e hazir
- Development klasorunde migration karar kaydi tamamlanmis

## 5. Bu Ornegi Kendi Projene Uyarlama

1. Kaynak ağaç ismini ve dosya yollarini kendi projenle degistir.
2. Karar matrisi tablosunu birebir doldur.
3. Tasiyip dogruladigin satirlari `migrated` ve `verified` olarak isaretle.
4. Checklist dosyalariyla kapanis yap.