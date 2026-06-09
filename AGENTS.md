# Gacha

All in-repo content is in English, except i18n translation resources.

Markdown documentation files must be minimal: no rationale, examples, or
multi-section structure unless explicitly requested.

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
├── Suppression/          system-state probes (full screen, capture, Focus)
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
- A file > ~200 lines is a split signal. Splitting means rethinking whether
  the file became a dumping ground and redesigning it along functional lines,
  not relocating the latest addition to dodge the limit.
- A capability that is semantically independent from the consumer context
  lives at a sibling top-level, even with only one caller today (e.g. a
  generic SwiftUI key-event bridge). A capability whose semantics are bound
  to the consumer stays inside that context. When in doubt, judge by whether
  the type would still make sense if the consumer were a different context.
- Each user-facing feature owns one `*Strings.swift` loaded via
  `AppStrings.localized`.

## Development

- Commit messages must use Conventional Commits.
- After functional changes, rerun `make dev` directly without asking user. Never run `swift build` nor `make format` first. Run `make test` on demand.
- `make dev` builds and launches within 5 seconds.
- Codex should use foreground `make dev` as the launch path and leave it running when it stays active.
- macOS Accessibility (AX) APIs may be used to inspect and operate UI during
  development, but screenshots require user consent before capture.

## Release

- Bump `CFBundleShortVersionString` and `CFBundleVersion` in `App/Info.plist`.
- Run `make dmg`.
- Create and push a `vX.Y.Z` tag.
- Create the GitHub Release and upload `build/Gacha-X.Y.Z.dmg`.
- Write release notes in Keep a Changelog style:
  https://keepachangelog.com/en/1.1.0/.
- Release notes must describe the net user-visible changes between the previous
  release and the new release, not individual commits or intermediate states.
- Update the Homebrew tap cask with the new version and DMG SHA-256, then run
  Homebrew style/audit/install checks.
