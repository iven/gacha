import AppKit

final class CardEditorPreviewSplitViewController: NSSplitViewController {
  private let editorViewController = CardTextPaneViewController()
  private let previewViewController = CardTextPaneViewController()

  init() {
    super.init(nibName: nil, bundle: nil)

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
    let text = card?.body ?? CardManagementStrings.emptyCategory
    editorViewController.setText(text)
    previewViewController.setText(text)
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

final class CardTextPaneViewController: NSViewController {
  private var text = ""
  private weak var textView: NSTextView?

  override func loadView() {
    let scrollView = NSTextView.scrollableTextView()
    guard let textView = scrollView.documentView as? NSTextView else {
      view = scrollView
      return
    }

    scrollView.drawsBackground = true
    scrollView.backgroundColor = .textBackgroundColor

    textView.string = text
    textView.font = .preferredFont(forTextStyle: .body)
    textView.backgroundColor = .textBackgroundColor
    textView.isEditable = false
    textView.isSelectable = true
    textView.textContainerInset = NSSize(width: 20, height: 20)
    self.textView = textView

    view = scrollView
  }

  func setText(_ text: String) {
    self.text = text
    textView?.string = text
  }
}
