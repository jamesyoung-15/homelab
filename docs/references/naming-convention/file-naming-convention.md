# File Naming Convention

Reference convention for documents, photos, and other related files.

Goal is to be chronologically sortable, parseable by programs, and human-readable (or at least somewhat).

## Core schema

```bash
YYYY-MM-DD_<Field>_<Field>_##.ext
```

- ISO date (dashed): `YYYY-MM-DD`, zero-padded month/day, date first so lexicographic sort = chronological sort.
- Structural separator is **underscore**: never use `_` inside a field, so `split("_")` always yields clean fields.
- Dashes are allowed only *inside* a field (e.g. `company-payslip`, `New-York-Trip`).
- `##` is a zero-padded de-dup counter; only used on collision.

## Examples

| Type | Pattern | Example |
|------|---------|---------|
| Document | `YYYY-MM-DD_<Category>_<Description>_##.ext` | `2026-01-19_company-payslip.pdf` |
| Standalone photo | `YYYY-MM-DD_<Description>_##.jpg` | `2026-01-19_New-York-Trip_019.jpg` |

A 4th field (e.g. `_draft` / `_final`) slots in before the counter if ever needed.

## Rules

1. **Collision handling:** first file stays plain, first duplicate gets `_01`, then `_02`, ...
2. **Descriptions:** short and noun-first (`company-payslip`, avoid things like `payslip-from-company-2026`). Prefer to leave tags/details to metadata/EXIF.
3. **Separators:** `_` = field boundary; `-` = word hyphen inside a field. Never underscore inside a description.
4. **No spaces, no `/\:*?"<>|`**, no leading dash (CLI flag ambiguity).
5. **Lowercase** except proper nouns (`New-York-Trip` is fine).
6. **Extensions:** keep original; never rename/re-encode to "fix" names.
7. **Fixed-width padding:** months/days (and the counter) always padded.

## Exceptions

I'm leaving below exception, may revise in future, mostly media related things:

- Music related files/directories (eg. albums/artists/songs)
- Movies/TV Shows
