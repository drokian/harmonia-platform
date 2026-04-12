# Source Migration Plan: d:/source/drokian/QR-pay-check

Bu plan, su kaynak proje uzerinden hazirlanmistir:

- `d:/source/drokian/QR-pay-check`

## 1. Kapsam Ozeti

Kaynak repo bir monorepo yapisinda:

- .NET API (`apps/api`)
- React + Vite web uygulamalari (`apps/customer-web`, `apps/restaurant-web`)
- Ortak paketler (`packages/*`)
- Docker altyapisi (`infrastructure/docker`)
- Dokumantasyon (`docs`, `development`)

Bu yapida demo/public ile commercial/private ayrimi icin en guvenli strateji:

- Demo repo: customer-facing gosterim akisi + minimum backend
- Commercial repo: tam API, tenant/branch/menu yonetimi, operasyonel altyapi

## 2. Siniflandirma Matrisi (Gercek Kaynak Yoluyla)

| Source Path | Target | Reason |
| --- | --- | --- |
| .github/copilot-instructions.md | development only | Ekip ici arac kurali |
| CLAUDE.md | development only | Dahili agent notu |
| .prettierrc | demo + commercial | Kod stili ortagi |
| package.json | commercial only | Monorepo orkestrasyonu ticari repoda daha kritik |
| package-lock.json | commercial only | Tek kaynak kilit dosya, demo sade tutulmali |
| turbo.json | commercial only | Monorepo pipeline dosyasi |
| tsconfig.base.json | demo + commercial | TS taban projelerde ortak temel |
| apps/api/src/QRPayCheck.API/Program.cs | commercial only | Tam API girisi |
| apps/api/src/QRPayCheck.API/Endpoints/AuthEndpoints.cs | commercial only | Kimlik ve yetki ticari alan |
| apps/api/src/QRPayCheck.API/Endpoints/TenantEndpoints.cs | commercial only | Tenant yonetimi private olmali |
| apps/api/src/QRPayCheck.API/Endpoints/BranchEndpoints.cs | commercial only | Isletme yonetimi private olmali |
| apps/api/src/QRPayCheck.API/Endpoints/CategoryEndpoints.cs | demo + commercial | Menu browse icin gerekli parca |
| apps/api/src/QRPayCheck.API/Endpoints/MenuEndpoints.cs | demo + commercial | Demo menu gosterimi icin gerekli |
| apps/api/src/QRPayCheck.API/Endpoints/MenuItemEndpoints.cs | demo + commercial | Demo menu item listeleme |
| apps/api/src/QRPayCheck.API/Endpoints/FileEndpoints.cs | commercial only | Dosya yukleme operasyonel risk |
| apps/api/src/QRPayCheck.API/appsettings.json | demo + commercial | Secret'siz base ayarlar paylasilabilir |
| apps/api/src/QRPayCheck.API/appsettings.Development.json | commercial only | Gelistirme detaylari private kalmali |
| apps/api/src/QRPayCheck.Application/** | commercial only | Is kurallari ve command/query katmani |
| apps/api/src/QRPayCheck.Domain/** | commercial only | Domain modeli ticari deger |
| apps/api/src/QRPayCheck.Infrastructure/** | commercial only | DB, migration ve altyapi private olmali |
| apps/api/tests/QRPayCheck.UnitTests/** | commercial only | Domain + app katmani testleri |
| apps/api/tests/QRPayCheck.IntegrationTests/** | commercial only | Altyapi bagimli testler |
| apps/customer-web/** | demo + commercial | Musteri akisinin demo versiyonu gerekir |
| apps/restaurant-web/** | commercial only | Isletme paneli private ozellik |
| packages/api-client/** | demo + commercial | Public endpoint tuketimi icin gerekli |
| packages/shared-types/** | demo + commercial | Ortak tipler |
| packages/ui/** | demo + commercial | UI bilesenleri paylasimli |
| docs/architecture/overview.md | demo + commercial | Yuksek seviye mimari paylasilabilir |
| docs/architecture/tech-stack.md | demo + commercial | Genel teknoloji bilgisi |
| docs/development-guide.md | development only | Gelistirici runbook dahili |
| docs/architecture/auth-flow.md | commercial only | Auth detaylari private kalmali |
| docs/architecture/database-design.md | commercial only | DB tasarimi private kalmali |
| docs/architecture/api-design.md | commercial only | API detaylari private kalmali |
| docs/features/menu-management.md | commercial only | Yonetim odakli ozellik |
| docs/features/table-management.md | commercial only | Operasyonel ozellik |
| docs/features/payment-flow.md | commercial only | Odeme akisi private olmalı |
| docs/features/qr-ordering.md | demo + commercial | Demo hikayesi icin uygun |
| development/** | development only | Zaten dahili klasor |
| infrastructure/docker/** | commercial only | Altyapi ve operasyon private |
| apps/**/.vite/** | remove | Build cache |
| apps/api/src/QRPayCheck.API/logs/** | remove | Runtime log artifaktlari |

## 3. Hedef Workspace Uretimi

Mevcut stack overlay'lerde .NET + Vite kombinasyonu olmadigi icin su sekilde baslayin:

1. Temel workspace'i script ile olustur (stack gecici secim):

```powershell
powershell -ExecutionPolicy Bypass -File .\development\scripts\scaffold-demo-commercial.ps1 `
  -TargetPath "D:\work\qr-pay-check-workspace" `
  -Stack node-service `
  -InitGitRepos
```

2. Sonra `demo/` ve `commercial/` icinde .NET + Vite klasor yapisini manuel olarak bu plana gore yerlestir.

Not: Sonraki iterasyonda bu proje icin `dotnet-vite-monorepo` overlay'i eklenmesi onerilir.

## 4. Tasima Sirasi

1. `commercial/` tarafina once `apps/api`, `apps/restaurant-web`, `infrastructure`, `docs` (private bolumler) tasin.
2. Ardindan `demo/` tarafina `apps/customer-web` ve paylasilabilir paketler tasin.
3. `demo/` tarafinda API bagimliligini minimum endpoint setine dusurun.
4. `development/` altina migration notlari ve karar matrisi kaydini alin.

## 5. Demo Guvenlik Temizligi

- Demo repoda asagidaki alanlar olmamali:
  - tenant/branch yonetim endpointleri
  - auth-flow ve database-design gibi detayli operasyon belgeleri
  - runtime log dosyalari
  - altyapi dagitim dosyalari

## 6. Dogrulama Komutlari (Ornek)

Demo repo:

```powershell
Set-Location "D:\work\qr-pay-check-workspace\demo"
npm install
npm run dev
```

Commercial repo:

```powershell
Set-Location "D:\work\qr-pay-check-workspace\commercial"
npm install
npm run dev
```

API dogrulama (commercial icinde):

```powershell
Set-Location "D:\work\qr-pay-check-workspace\commercial\apps\api"
dotnet build
dotnet test
```

## 7. Kabul Kriterleri

- Demo repo publice cikabilecek kadar temiz ve calisabilir olmali
- Commercial repo tam ozellik setiyle build/test gecebilmeli
- Dosya bazli siniflandirma tablosunda tum satirlar `verified` olmali