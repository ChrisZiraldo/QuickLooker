import Cocoa
import Quartz

class PreviewViewController: NSViewController, QLPreviewingController {

    private let scrollView = NSScrollView()
    private let textView   = NSTextView()

    // MARK: - View lifecycle

    override func loadView() {
        // Build a scroll view / text view pair without a XIB.
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.drawsBackground = true
        textView.backgroundColor = .textBackgroundColor
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = .width
        textView.textContainer?.widthTracksTextView = true
        textView.textContainerInset = NSSize(width: 8, height: 8)

        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        self.view = scrollView
    }

    // MARK: - QLPreviewingController

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let result = TextFileDetector.detect(at: url) else {
                DispatchQueue.main.async { handler(PreviewError.notTextFile) }
                return
            }

            let font  = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            let attrs: [NSAttributedString.Key: Any] = [
                .font:            font,
                .foregroundColor: NSColor.textColor,
            ]
            let attributed = NSAttributedString(string: result.text, attributes: attrs)

            DispatchQueue.main.async {
                self.textView.textStorage?.setAttributedString(attributed)
                // Resize text view to fit its content so the scroll view works correctly.
                self.textView.sizeToFit()
                handler(nil)
            }
        }
    }

    // MARK: - Errors

    enum PreviewError: LocalizedError {
        case notTextFile
        var errorDescription: String? { "File does not appear to contain plain text." }
    }
}
