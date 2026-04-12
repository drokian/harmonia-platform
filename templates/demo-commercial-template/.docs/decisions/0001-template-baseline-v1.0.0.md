# ADR 0001: Template Baseline v1.0.0

## Status

Accepted

## Date

2026-04-12

## Context

Workspace template scope expanded from a simple demo/commercial skeleton to a reusable operating baseline.

## Decision

Adopt `v1.0.0` as first stable baseline with:

- root governance files (`.editorconfig`, `.gitignore`, version and changelog)
- structured documentation taxonomy under `.docs/`
- starter GitHub workflows under `.github/workflows/`
- explicit development operations areas under `development/`
- richer starter repository skeletons under `demo/` and `commercial/`

## Consequences

- New projects can start from a consistent and auditable baseline.
- Template validation can enforce both required paths and required files.
- Future template changes should increment `TEMPLATE_VERSION` and append `TEMPLATE_CHANGELOG.md`.