# Gacha

All in-repo content is in English, except i18n translation resources.

Documentation must be minimal: no rationale, examples, or multi-section
structure unless explicitly requested.

## Source layout

Top level groups bounded contexts, not layers. Within a context, group by
subdomain or UI surface. Capability shared by two contexts goes to its own
top-level directory, not nested inside one consumer.

Example:

```
Sources/Gacha/
├── App/                  process entry, bootstrapping
├── Core/                 cross-cutting infra (logger, settings, codecs)
├── Cards/                card domain (models, scheduler, persistence)
├── Markdown/             markdown rendering + highlighting (shared)
├── Notch/                notch UI (controller, view model, views)
├── MenuBar/
└── Windows/
    ├── CardManagement/
    │   ├── Sidebar/
    │   ├── List/
    │   ├── Editor/       input side: source editor + highlighter glue
    │   ├── Preview/      output side: rendered markdown
    │   └── Sheets/
    └── Settings/
```

Rules:

- One primary type per file. File name matches the type.
- A file > ~200 lines or holding multiple top-level types is a split signal.
- A directory that consumes a capability shared with another context (e.g.
  markdown rendering used by both `Notch/` and `Windows/CardManagement/`)
  must not own that capability — promote it to a sibling top-level.
- Each user-facing feature owns one `*Strings.swift` loaded via
  `AppStrings.localized`.
