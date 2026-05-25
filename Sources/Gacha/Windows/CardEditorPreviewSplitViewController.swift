import AppKit

final class CardEditorPreviewSplitViewController: NSSplitViewController {
  var onBodyChange: ((String) -> Void)?
  var onEmptyStateClick: (() -> Void)?

  private let editorViewController = CardTextPaneViewController(
    syntaxHighlighter: MarkdownSyntaxHighlighter())
  private let previewViewController = CardTextPaneViewController()

  init() {
    super.init(nibName: nil, bundle: nil)

    editorViewController.onTextChange = { [weak self] text in
      self?.previewViewController.setText(text)
      self?.onBodyChange?(text)
    }
    editorViewController.onClick = { [weak self] in
      self?.onEmptyStateClick?()
    }
    previewViewController.onClick = { [weak self] in
      self?.onEmptyStateClick?()
    }

    splitView.isVertical = false
    splitView.dividerStyle = .thin

    addSplitViewItem(Self.editorPaneSplitViewItem(viewController: editorViewController))
    addSplitViewItem(Self.previewPaneSplitViewItem(viewController: previewViewController))
    show(card: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func show(card: MemoryCard?) {
    let isEmptyState = card == nil
    let text = card?.body ?? ""
    editorViewController.setEditable(card != nil)
    editorViewController.setText(text)
    editorViewController.setClickHandlingEnabled(isEmptyState)
    previewViewController.setEditable(false)
    previewViewController.setText(text)
    previewViewController.setClickHandlingEnabled(isEmptyState)
  }

  func focusEditor() {
    editorViewController.focusTextView()
  }

  private static func editorPaneSplitViewItem(
    viewController: CardTextPaneViewController
  ) -> NSSplitViewItem {
    let item = NSSplitViewItem(viewController: viewController)
    item.minimumThickness = 250
    item.canCollapse = false
    return item
  }

  private static func previewPaneSplitViewItem(
    viewController: CardTextPaneViewController
  ) -> NSSplitViewItem {
    let item = NSSplitViewItem(viewController: viewController)
    item.minimumThickness = 250
    item.canCollapse = false
    return item
  }
}

final class CardTextPaneViewController: NSViewController, NSTextViewDelegate {
  var onTextChange: ((String) -> Void)?
  var onClick: (() -> Void)?

  private let syntaxHighlighter: MarkdownSyntaxHighlighter?
  private var text = ""
  private var isEditable = false
  private var isApplyingText = false
  private var handlesClicks = false
  private weak var clickCatchingView: ClickCatchingView?
  private weak var textView: NSTextView?

  init(syntaxHighlighter: MarkdownSyntaxHighlighter? = nil) {
    self.syntaxHighlighter = syntaxHighlighter
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    let rootView = ClickCatchingView()
    rootView.onClick = { [weak self] in
      self?.onClick?()
    }
    rootView.isClickHandlingEnabled = handlesClicks
    clickCatchingView = rootView

    let scrollView = NSTextView.scrollableTextView()
    guard let textView = scrollView.documentView as? NSTextView else {
      view = rootView
      return
    }

    scrollView.drawsBackground = true
    scrollView.backgroundColor = .textBackgroundColor

    textView.string = text
    textView.font = .preferredFont(forTextStyle: .body)
    textView.backgroundColor = .textBackgroundColor
    textView.isEditable = isEditable
    textView.isSelectable = true
    textView.allowsUndo = true
    textView.textContainerInset = NSSize(width: 20, height: 20)
    textView.delegate = self
    self.textView = textView

    scrollView.translatesAutoresizingMaskIntoConstraints = false
    rootView.addSubview(scrollView)
    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: rootView.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
    ])

    view = rootView
  }

  func setText(_ text: String) {
    self.text = text

    isApplyingText = true
    textView?.string = text
    applyHighlight()
    isApplyingText = false
  }

  func setEditable(_ isEditable: Bool) {
    self.isEditable = isEditable
    textView?.isEditable = isEditable
  }

  func setClickHandlingEnabled(_ isEnabled: Bool) {
    handlesClicks = isEnabled
    clickCatchingView?.isClickHandlingEnabled = isEnabled
  }

  func focusTextView() {
    guard let textView else {
      return
    }

    view.window?.makeFirstResponder(textView)
  }

  func textDidChange(_ notification: Notification) {
    guard !isApplyingText, let textView else {
      return
    }

    applyHighlight()
    onTextChange?(textView.string)
  }

  private func applyHighlight() {
    guard let syntaxHighlighter, let textView else {
      return
    }

    syntaxHighlighter.apply(to: textView)
  }
}

private final class ClickCatchingView: NSView {
  var isClickHandlingEnabled = false
  var onClick: (() -> Void)?

  override func hitTest(_ point: NSPoint) -> NSView? {
    guard isClickHandlingEnabled, isMousePoint(point, in: bounds) else {
      return super.hitTest(point)
    }

    return self
  }

  override func mouseDown(with event: NSEvent) {
    guard isClickHandlingEnabled else {
      super.mouseDown(with: event)
      return
    }

    onClick?()
  }
}
