# Demo / Commercial Template

## Amaç
Bu template, aynı ürünün iki ayrı depo ile yönetildiği yapılar için başlangıç iskeleti sunar.

- `demo/`: herkese açık, showcase veya tanıtım amaçlı repo
- `commercial/`: özel, müşteri veya ürünleştirilmiş ana repo
- `development/`: iki repo arasında ortak planlama, kontrol listeleri ve operasyon notları, .gitignore'a eklenir uzak depoya gitmez.
- `stacks/`: base template üzerine uygulanacak teknoloji katmanları

Bu yapı iki senaryoda kullanılmalıdır:

1. Sıfırdan yeni bir demo + ticari çalışma alanı oluştururken
2. Mevcut bir projeyi demo / commercial ayrımına dönüştürürken

## Repo Politikası

- `demo` deposu public tutulur
- `commercial` deposu private tutulur
- Her dizin kendi `.git` geçmişine sahip bağımsız bir repo olarak düşünülür
- Workspace seviyesinde tutulan dosyalar yalnızca ortak yönetim amacı taşır; ürün kodu repo sınırlarını ihlal etmemelidir

Örnek hesaplar:

- Public demo repoları: `https://github.com/drokian`
- Private ticari repolar: `https://github.com/docyazilim`

Örnek eşleşme:

- Demo repo: `https://github.com/drokian/QR-pay-check-demo`
- Commercial repo: `https://github.com/docyazilim/QR-pay-check`

## Hedef Dizin Yapısı

```text
workspace/
├── .claude/
├── .docs/
│   ├── architecture/
│   ├── conventions/
│   ├── workflows/
│   ├── decisions/
│   └── glossary/
├── .github/
│   └── workflows/
│       ├── ci.yml
│       ├── release.yml
│       ├── submodule-sync.yml
│       └── template-validation.yml
├── development/
│   ├── guides/
│   └── checklists/
│   ├── migration/
│   ├── scripts/
│   ├── decisions/
│   └── templates/
├── stacks/
│   ├── node-service/
│   ├── python-service/
│   └── nextjs-app/
├── demo/
│   ├── src/
│   ├── tests/
│   ├── scripts/
│   ├── config/
│   ├── docs/
│   ├── CHANGELOG.md
│   ├── LICENSE
│   ├── package.json
│   └── README.md
└── commercial/
    ├── src/
    ├── tests/
    ├── scripts/
    ├── config/
    ├── docs/
    ├── CHANGELOG.md
    ├── LICENSE
    ├── package.json
    └── README.md
```

Notlar:

- `demo/` ve `commercial/` içindeki gerçek uygulama klasörleri teknolojiye göre sonradan eklenir
- Bu template bilinçli olarak teknoloji bağımsız tutulur
- Ortak süreç dokümanları workspace düzeyindedir, ürün kodu repo düzeyindedir
- Eğer workspace kökü de bir git reposu olarak tutuluyorsa `development/` uzak repoya gönderilmemeli, kök `.gitignore` içinde hariç tutulmalıdır

## Dizinlerin Sorumluluğu

### `.claude/`
Ajana veya ekip içi otomasyon araçlarına verilecek çalışma kuralları burada tutulur.

### `.docs/`
Workspace düzeyindeki mimari, operasyon ve karar kayıtları burada tutulur.

### `.github/`
Ortak issue template, workflow taslakları veya süreç notları burada bulunur. Repo içi özel workflow'lar daha sonra ilgili repoya taşınabilir.

### `development/`
Kurulum, geçiş, teslim ve kalite kontrol listeleri burada tutulur.

### `stacks/`
Node, Python ve Next.js gibi teknolojiye özel overlay şablonları burada tutulur.

### `demo/`
Demo veya showcase amacıyla yayınlanan public repo içeriği burada başlar.

### `commercial/`
Ürünün private, müşteri odaklı veya lisanslı sürümü burada başlar.

## Uygulama Kuralları

### 1. Ayrışma
- Demo içinde ticari sır, lisanslı içerik veya müşteri verisi bulunmamalıdır
- Commercial repo, demo repoya göre daha geniş özellik seti içerebilir

### 2. Dokümantasyon
- Her repo kendi `README.md` dosyasına sahip olmalıdır
- Her repo kendi `docs/` klasöründe repo-özel dokümanlarını tutmalıdır
- Ortak süreç ve karar notları workspace seviyesinde saklanmalıdır

### 3. Git ve Yayınlama
- `demo/` ve `commercial/` klasörlerinde bağımsız git init yapılmalıdır
- Branch, release ve CI akışları repo bazında ayrı yönetilmelidir
- Demo repoya aktarılacak içerik, ticari repodan doğrudan kopyalanmadan önce temizlenmelidir

### 4. Geçiş Senaryosu
Mevcut tekil bir projeyi bu yapıya dönüştürürken:

1. Kaynak projenin hangi dosyalarının `demo` için uygun olduğunu ayırın
2. Lisanslı, müşteri özel veya hassas içerikleri yalnızca `commercial` içinde bırakın
3. Ortak operasyon notlarını `development/` altına taşıyın
4. Repo bazlı README ve dokümantasyon ayrımını tamamlayın

## Stack Overlay Katmanı
Bu template artık üç adet başlangıç overlay'i içerir:

- `stacks/node-service/`: sade Node.js servis başlangıcı
- `stacks/python-service/`: sade Python servis başlangıcı
- `stacks/nextjs-app/`: web arayüzü odaklı Next.js başlangıcı

Kullanım şekli:

1. Önce base template workspace'ini oluşturun
2. Sonra uygun stack overlay'ini seçin
3. Overlay içindeki `demo/` ve `commercial/` dosyalarını ilgili repo köklerine kopyalayın
4. Projenin gerçek bağımlılıkları ve kodu ile bu iskeleti genişletin

## Checklist ve Migration Paketleri
Template'in bu sürümünde aşağıdaki operasyon dosyaları hazır gelir:

- `development/checklists/repo-split-checklist.md`
- `development/checklists/demo-release-checklist.md`
- `development/checklists/commercial-release-checklist.md`
- `development/project-migration-guide.md`
- `development/project-migration-steps.md`

## Otomatik Scaffold Komutu
Bu template, script ile hizli sekilde yeni workspace uretebilir:

- Script: `development/scripts/scaffold-demo-commercial.ps1`
- Amac: base template + secili stack overlay ile hedef dizin olusturmak

Ornek kullanim:

```powershell
powershell -ExecutionPolicy Bypass -File .\development\scripts\scaffold-demo-commercial.ps1 `
    -TargetPath "D:\work\my-product-workspace" `
    -Stack node-service `
    -InitGitRepos
```

Not: `-KeepDevelopmentLocal` acik oldugunda script, hedef workspace kokundeki `.gitignore` dosyasina `development/` kaydini ekler.

## İlk Sürüm Kapsamı
Bu template'in ilk sürümü aşağıdakileri sağlamalıdır:

- Workspace seviyesinde temel yönetim dosyaları
- `demo` ve `commercial` için package, changelog, lisans ve src/docs/tests iskeleti
- `development` altında guides, checklists, migration, scripts, decisions, templates alanlari
- `node`, `python` ve `nextjs` için başlangıç overlay'leri
- Mevcut projeyi ayırmak için migration kılavuzu

## Sonraki Genişletmeler
İleride bu template'e aşağıdaki katmanlar eklenebilir:

- `fastapi`, `nestjs`, `electron` gibi yeni overlay'ler
- demo -> commercial senkronizasyon rehberi
- branch ve release isimlendirme standardı
- stack secimine gore bagimlilik kurulum otomasyonu

## Karar
Bu template bir uygulama kodu şablonu değil, repo organizasyonu ve çalışma modeli şablonudur. Kod yığınına ait başlangıç dosyaları daha sonra ayrı template katmanları olarak eklenmelidir.