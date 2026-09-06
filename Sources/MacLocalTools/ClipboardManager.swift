import AppKit
import Foundation

struct ClipboardEntry: Identifiable, Hashable, Sendable {
    let id = UUID()
    let text: String
    let capturedAt: Date
}

@MainActor
final class ClipboardManager: ObservableObject {
    @Published private(set) var entries: [ClipboardEntry] = []

    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    private let maxEntries = 50

    init() {
        lastChangeCount = pasteboard.changeCount
    }

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func clear() {
        entries.removeAll()
    }

    func copy(_ entry: ClipboardEntry) {
        pasteboard.clearContents()
        pasteboard.setString(entry.text, forType: .string)
        lastChangeCount = pasteboard.changeCount
    }

    private func poll() {
        let currentChangeCount = pasteboard.changeCount
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount

        guard let text = pasteboard.string(forType: .string), !text.isEmpty else { return }
        if entries.first?.text == text { return }

        entries.insert(ClipboardEntry(text: text, capturedAt: Date()), at: 0)
        if entries.count > maxEntries {
            entries.removeLast(entries.count - maxEntries)
        }
    }
}
