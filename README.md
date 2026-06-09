# Gacha

[English](README.md) | [简体中文](README.zh-Hans.md)

![Gacha memory card](https://github.com/user-attachments/assets/7fa85c69-6a8f-43a8-a961-1c1f1a994f3c)

Gacha is a macOS memory card app that keeps reviews close without pulling you
out of your work.

Review cards in a compact notch surface, organize them by category, and let
FSRS scheduling decide what should come next.

## Features

- Markdown memory cards with ruby annotation support
- Notch-based review flow with keyboard shortcuts
- FSRS-powered spaced repetition
- System-aware suppression during full-screen apps, screen recording, and Focus
  mode
- AI agent integrations through a local MCP server and bundled CLI

## Install

Gacha currently requires macOS 15 or later.

### Homebrew

```sh
brew tap iven/tap
brew install --cask iven/tap/gacha
```

### DMG

Download the latest `Gacha-*.dmg` from GitHub Releases, open it, and drag
`Gacha.app` to Applications.

Gacha is distributed without Apple Developer ID signing or notarization. On
first launch, macOS may ask you to approve it in System Settings > Privacy &
Security.

## AI Agent Integrations

Gacha exposes local tools for AI agents to create cards, manage categories, and
send notices to the app.

Configure the MCP server and CLI from Gacha Settings.

## License

MIT
