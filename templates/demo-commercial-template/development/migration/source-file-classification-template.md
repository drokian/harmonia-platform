# Source File Classification Template

Bu tabloyu, kaynak projedeki dosyalari tasimadan once doldurun.

## Kullanim Kurali

- `Target` alani su degerlerden biri olmali:
  - `demo + commercial`
  - `commercial only`
  - `development only`
  - `remove`

## Tablo

| Source Path | Target | Reason | Action Owner | Status |
| --- | --- | --- | --- | --- |
| src/api/public-check.ts | demo + commercial | Public API endpoint required by both repos | backend | planned |
| src/api/admin-report.ts | commercial only | Contains business-only reporting logic | backend | planned |
| docs/internal-audit.md | development only | Internal process note | product | planned |
| scripts/legacy-seed.js | remove | Obsolete script not needed after split | backend | planned |

## Durum Degerleri

- `planned`
- `migrated`
- `verified`