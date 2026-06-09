# Gacha

[English](README.md) | [简体中文](README.zh-Hans.md)

![Gacha 记忆卡片](https://github.com/user-attachments/assets/7fa85c69-6a8f-43a8-a961-1c1f1a994f3c)

Gacha 是一款 macOS 记忆卡片应用，让复习保持在手边，而不会打断你正在做的事。

你可以在紧凑的刘海界面里复习卡片，按分类管理内容，并交给 FSRS 调度来决定下一张应该复习什么。

## 功能

- 支持 Markdown 的记忆卡片，并支持 ruby 注音。
- 基于刘海的复习流程，支持键盘快捷键。
- 基于 FSRS 的间隔重复调度。
- 在全屏应用、录屏或共享屏幕、专注模式下自动免打扰。
- 可脚本化 Markdown 通知，用于提醒、告警和更新推送。
- 通过本地 MCP 服务器和内置 CLI 集成 AI Agent。

## 安装

Gacha 当前需要 macOS 15 或更高版本。

### Homebrew

```sh
brew tap iven/tap
brew install --cask iven/tap/gacha
```

### DMG

从 GitHub Releases 下载最新的 `Gacha-*.dmg`，打开后将 `Gacha.app` 拖到 Applications。

Gacha 目前没有使用 Apple Developer ID 签名，也没有 notarization。首次启动时，macOS 可能会提示无法验证 Gacha，并提供「移到废纸篓」选项。点击「完成」后，打开 System Settings > Privacy & Security，在 Gacha 的提示旁点击「仍要打开」。

## AI Agent 集成

Gacha 为 AI Agent 暴露本地 MCP 工具，用于创建卡片、管理分类，以及向应用发送通知。你可以在 Gacha Settings 中配置 MCP 服务器。

## 向 Gacha 发送通知

Gacha 可以接收并显示来自脚本或 AI Agent 的 Markdown 通知。你可以通过内置 CLI 或本地 MCP 服务器发送通知，用于健康提醒，比如拉伸、坐姿、喝水，也可以用于用量告警通知和更新推送。

## 许可证

MIT
