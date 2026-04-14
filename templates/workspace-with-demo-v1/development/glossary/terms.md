# Terimler Sozlugu

Bu dosya workspace-with-demo-v1 sablonunda kullanilan teknik ve operasyonel terimleri tanimlar.

---

## A

**ADR (Architecture Decision Record)**
Mimari karar kaydi. `development/decisions/` klasorunde saklanir. Format: `NNNN-kisa-baslik.md`.

## B

**Backlog**
Yapilacaklar listesi. `development/backlogs/backlog.md` tek kaynak kabul edilir. Is sirasi P0 → P1 → P2.

**Baseline**
Bir template'in donmus baslangic durumu. `TEMPLATE_VERSION` ve `TEMPLATE_CHANGELOG.md` ile takip edilir.

## D

**Demo**
Kullanicilarla paylasilan public klasor/repo. `demo/` submodule olarak eklenir. Hicbir gizli bilgi iceremez.

**Denylist**
Demo'ya kopyalanmasi yasak dosya/klasor kaliplari. `template-manifest.yml` icindeki `demo_sync_denylist` listesinde tanimlanir.

## F

**forbidden_globs**
Workspace icinde bulunmasi kabul edilemez dosya kaliplari (ornek: `.env`). `template-manifest.yml` `forbidden_globs` listesinde tanimlanir; CI bozulur.

## G

**Glossary**
Bu dosya. Terimleri tanimlayan referans dokumani.

## M

**Manifest**
`.github/template-manifest.yml` dosyasi. `required_dirs`, `required_files`, `forbidden_globs` ve `demo_sync_denylist` listelerini icerir. CI tarafindan dogrulanir (tek kaynak).

## R

**required_dirs** / **required_files**
Manifest icindeki listeler. PR'da bu yapinin eksik olmasi CI fail'e yol acar.

## S

**Scaffold**
Yeni bir workspace uretmek icin template'i hedef dizine kopyalayan islem. `scripts/scaffold-demo-commercial.ps1` ile yurutulur.

**Sprint**
Kisa sureli calisma donemi. `development/sprints/current.md` aktif sprint'i, `development/sprints/archive/` biten sprint'leri saklar.

**Submodule**
`demo/` klasorunun ayri bir Git repo olarak workspace'e baglanma sekli. `git submodule` komutlariyla yonetilir.

**Sync**
`scripts/sync-to-demo.ps1` ile workspace dosyalarinin demo/ submodule'une guvenli kopyalanmasi islemi. Denylist ve secret kontrolu icerir.

## T

**Template**
Bu workspace yapisi ve icindeki tum kurallar. Harmonia meta-workspace'te gelistirilir ve surumlanir.

**TEMPLATE_VERSION**
Semver formatinda (`vX.Y.Z`) tek satir dosya. `TEMPLATE_CHANGELOG.md`, `README.md` baseline satiri ve manifest ile birlikte Single-Source kuraline tabidir.

## V

**validate-template.ps1**
`scripts/` altindaki dogrulama scripti. Manifest'e gore workspace yapisini, forbidden_globs kurallarini ve minimum dosya varlıklarini kontrol eder.

**verify-no-secrets-in-demo.ps1**
`scripts/` altindaki guvenlik scripti. `demo/` icinde secret kaliplarini tararır; temizse exit 0, bulursa exit 1.

**Versioning**
Bu workspace'te Semantic Versioning (`MAJOR.MINOR.PATCH`) kullanilir. Detay icin `development/conventions/versioning-strategy.md`.
