# Demo / Commercial Template

Bu klasor, tek bir urunun `demo` ve `commercial` olarak iki ayri repo halinde yonetilecegi workspace iskeletini barindirir.

## Baseline Version

- Current baseline: `v1.0.0`
- Version source: `TEMPLATE_VERSION`
- Change history: `TEMPLATE_CHANGELOG.md`
- Version bump script: `development/scripts/bump-template-version.ps1`

## Icerik

- `.claude/`: ajan ve otomasyon kurallari
- `.docs/`: ortak karar ve mimari notlari
- `.github/`: ortak surec ve workflow taslaklari
- `development/`: gecis ve operasyon checklist'leri
- `stacks/`: teknolojiye ozel overlay'ler
- `demo/`: public repo baslangic alani
- `commercial/`: private repo baslangic alani

## Ornek Dizin Yapisı

```text
/
|-- .editorconfig
|-- .gitignore
|-- README.md
|
|-- .docs/
|   |-- architecture/
|   |-- workflows/
|   |-- conventions/
|   |-- decisions/
|   |-- glossary/
|   `-- README.md
|
|-- .github/
|   |-- workflows/
|   |   |-- ci.yml
|   |   |-- release.yml
|   |   |-- submodule-sync.yml
|   |   `-- template-validation.yml
|   `-- README.md
|
|-- demo/
|   |-- package.json
|   |-- README.md
|   |-- CHANGELOG.md
|   |-- LICENSE
|   |-- src/
|   |   |-- core/
|   |   |-- modules/
|   |   `-- index.js
|   |-- docs/
|   |   |-- usage.md
|   |   |-- examples.md
|   |   `-- api.md
|   |-- tests/
|   |-- scripts/
|   `-- config/
|
|-- commercial/
|   |-- package.json
|   |-- README.md
|   |-- CHANGELOG.md
|   |-- LICENSE
|   |-- src/
|   |   |-- core/
|   |   |-- modules/
|   |   |-- agents/
|   |   `-- index.js
|   |-- docs/
|   |   |-- architecture.md
|   |   `-- business-rules.md
|   |-- tests/
|   |-- scripts/
|   `-- config/
|
`-- development/
	|-- README.md
	|-- guides/
	|-- checklists/
	|-- migration/
	|-- scripts/
	|-- decisions/
	`-- templates/
```

## Kullanim

1. Bu template'i yeni bir workspace'e kopyalayin.
2. `demo/` ve `commercial/` icinde bagimsiz repo yapilarini olusturun.
3. `stacks/` altindan uygun teknoloji overlay'ini secin.
4. Overlay dosyalarini ilgili repo koklerine kopyalayin.
5. Ortak surec notlarini workspace seviyesinde tutun.

## Hizli Scaffold

Bu template, yeni bir workspace olusturmak icin script ile de kullanilabilir.

```powershell
powershell -ExecutionPolicy Bypass -File .\development\scripts\scaffold-demo-commercial.ps1 `
	-TargetPath "D:\work\my-product-workspace" `
	-Stack nextjs-app `
	-InitGitRepos
```

Desteklenen `-Stack` degerleri:

- `node-service`
- `python-service`
- `nextjs-app`

Script, base template'i hedef klasore kopyalar ve secilen stack overlay'ini `demo/` ile `commercial/` uzerine uygular.

Kaynak projeden gecis icin ornek runbook: `development/project-migration-steps.md`
Detayli file-level ornek: `development/migration/example-qr-pay-check.md`

Bu template teknoloji bagimsizdir. Uygulama stack'i daha sonra ayri template katmanlariyla eklenmelidir.

Eger workspace koku da bir git reposu olacaksa, `development/` klasorunu uzak depoya gondermemek icin kok `.gitignore` icinde hariç tutun.