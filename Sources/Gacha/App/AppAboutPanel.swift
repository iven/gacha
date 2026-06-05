import AppKit

@MainActor
enum AppAboutPanel {
  static func show() {
    NSApp.orderFrontStandardAboutPanel(options: options)
  }

  private static var options: [NSApplication.AboutPanelOptionKey: Any] {
    var options: [NSApplication.AboutPanelOptionKey: Any] = [
      .applicationName: AppMetadata.name,
      .applicationVersion: AppAboutStrings.version(AppMetadata.version),
      .credits: credits,
    ]
    if let applicationIcon = NSApp.applicationIconImage {
      options[.applicationIcon] = applicationIcon
    }
    return options
  }

  private static var credits: NSAttributedString {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    paragraphStyle.lineSpacing = 2

    return NSAttributedString(
      string: AppAboutStrings.credits,
      attributes: [
        .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
        .foregroundColor: NSColor.secondaryLabelColor,
        .paragraphStyle: paragraphStyle,
      ])
  }
}
