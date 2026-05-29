# JDS_Documentation hand-off

Content ready to paste into [`nj22az/JDS_Documentation`](https://github.com/nj22az/JDS_Documentation) to register Onsen Planner as a JDS project and the Joho Design System Manual as a JDS document.

The Onsen Planner repo is **source of truth** for the actual project and design-system documents (`docs/JDS-PRJ-SFW-002_onsen-planner.md`, `docs/JDS-MAN-SFW-001_joho-design-system.md`). The JDS repo just carries a project card plus register entries — same pattern as `JDS-PRJ-SFW-001_local-image-generator`.

## To apply

In your local clone of `nj22az/JDS_Documentation`:

```bash
# 1. Copy the project folder into place.
cp -R docs/jds-handoff/projects/software/JDS-PRJ-SFW-002_onsen-planner \
      <path-to-JDS_Documentation>/projects/software/

# 2. Add the register entries (see register-additions.md) to
#    jds/registry/document-register.md — preserve the file's existing
#    table format.

# 3. Commit and push.
cd <path-to-JDS_Documentation>
git add projects/software/JDS-PRJ-SFW-002_onsen-planner/ jds/registry/document-register.md
git commit -m "Register JDS-PRJ-SFW-002 Onsen Planner and JDS-MAN-SFW-001 Joho Design System Manual"
git push
```

## Contents

| File | Destination in JDS_Documentation |
|---|---|
| [`projects/software/JDS-PRJ-SFW-002_onsen-planner/README.md`](projects/software/JDS-PRJ-SFW-002_onsen-planner/README.md) | `projects/software/JDS-PRJ-SFW-002_onsen-planner/README.md` |
| [`projects/software/JDS-PRJ-SFW-002_onsen-planner/CHANGELOG.md`](projects/software/JDS-PRJ-SFW-002_onsen-planner/CHANGELOG.md) | `projects/software/JDS-PRJ-SFW-002_onsen-planner/CHANGELOG.md` |
| [`register-additions.md`](register-additions.md) | Append rows into `jds/registry/document-register.md` |

## Note on revisions

The manual `JDS-MAN-SFW-001` is now at **Rev C** (Rev A initial; Rev B synced after the IconCatalog/JohoColors dead-code sweeps; Rev C documents the expanded linter enforcement in §10.1). The register additions reflect Rev C.

The project card `JDS-PRJ-SFW-002` remains at Rev A — no scope or surface changes since creation.
