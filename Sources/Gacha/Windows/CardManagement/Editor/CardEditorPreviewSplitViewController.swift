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
