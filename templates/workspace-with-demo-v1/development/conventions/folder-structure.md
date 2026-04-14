# Klasor Yapisi

## Workspace Kok Dizini

```
workspace/
├── .github/                  # GitHub Actions ve manifest
│   ├── template-manifest.yml
│   └── workflows/
├── .claude/                  # Claude Code talimatlari
├── backups/                  # Yedek dosyalari (gitlenir, demo'ya gitmez)
│   ├── README.md
│   └── latest.json
├── demo/                     # Public demo submodule (git submodule)
├── development/              # Ozel surec notlari (.gitignore'da)
│   ├── backlogs/
│   ├── checklists/
│   ├── conventions/
│   ├── decisions/
│   ├── glossary/
│   ├── guides/
│   ├── scripts/
│   └── sprints/
├── docs/                     # MkDocs kaynak dosyalari
│   ├── architecture/
│   └── installation/
├── scripts/                  # Ops ve guvenlik scriptleri (kok seviye)
├── stacks/                   # Tech stack overlay'leri
├── .editorconfig
├── .gitignore
├── CLAUDE.md
├── README.md
├── TEMPLATE_CHANGELOG.md
└── TEMPLATE_VERSION
```

## Klasor Amac Aciklamalari

### `backups/`
`latest.json` gitlenir; gecmis yedekler icinde saklanmaz. BuyuMe riskinde Git LFS kullanilir (ADR-0003).

### `demo/`
Template kaynaginda statik placeholder. Scaffold sirasinda public repo'ya donusur ve `git submodule` olarak baglanir (ADR-0002).

### `development/`
Hedef workspace'te `.gitignore` tarafindan hariç tutulur. Template kaynaginda tam icerikle gitlenir — bu fark kasitlidir.

### `docs/`
MkDocs Material ile host edilen kullanici dokumantasyonu. `docs/installation/` 6 asamali kurulum rehberini icerir.

### `scripts/`
Guvenlik ve ops scriptleri kok seviyededir; `development/scripts/` degil. Kullanicilar kolayca bulur.

### `stacks/`
Tech stack overlay'leri (node-service, python-service, nextjs-app). Her stack `demo/` ve `workspace/` alt klasorlerini icerir.
