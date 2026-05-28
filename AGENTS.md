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

- One primary type per file. File name matches it.
- A file > ~200 lines is a split signal.
- A capability that is semantically independent from the consumer context
  lives at a sibling top-level, even with only one caller today (e.g. a
  generic SwiftUI key-event bridge). A capability whose semantics are bound
  to the consumer stays inside that context. When in doubt, judge by whether
  the type would still make sense if the consumer were a different context.
- Each user-facing feature owns one `*Strings.swift` loaded via
  `AppStrings.localized`.

## Development

- After functional changes, the agent should kill the running `Gacha` process and rerun `make dev`.
