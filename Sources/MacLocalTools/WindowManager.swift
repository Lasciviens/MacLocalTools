import AppKit
import ApplicationServices
import Foundation

enum WindowPlacement: String, CaseIterable, Identifiable {
    case leftHalf = "Left Half"
    case rightHalf = "Right Half"
    case maximize = "Maximize"
    case center = "Center"

    var id: String { rawValue }
}

enum WindowManagerError: Error, LocalizedError {
    case accessibilityPermissionRequired
    case noFrontmostApplication
    case noFocusedWindow
    case noScreen

    var errorDescription: String? {
        switch self {
        case .accessibilityPermissionRequired: return "Accessibility permission is required in System Settings → Privacy & Security → Accessibility."
        case .noFrontmostApplication: return "No frontmost application found."
        case .noFocusedWindow: return "No focused window found."
        case .noScreen: return "No screen found."
        }
    }
}

struct WindowManager {
    var hasAccessibilityPermission: Bool { AXIsProcessTrusted() }

    func moveFrontmostWindow(_ placement: WindowPlacement) throws {
        guard hasAccessibilityPermission else { throw WindowManagerError.accessibilityPermissionRequired }
        guard let app = NSWorkspace.shared.frontmostApplication else { throw WindowManagerError.noFrontmostApplication }
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { throw WindowManagerError.noScreen }

        let application = AXUIElementCreateApplication(app.processIdentifier)
        var focused: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(application, kAXFocusedWindowAttribute as CFString, &focused)
        guard status == .success, let focused else { throw WindowManagerError.noFocusedWindow }
        let window = focused as! AXUIElement

        let frame = targetFrame(for: placement, in: screen.visibleFrame)
        var position = CGPoint(x: frame.minX, y: screen.frame.maxY - frame.maxY)
        var size = CGSize(width: frame.width, height: frame.height)

        if let positionValue = AXValueCreate(.cgPoint, &position) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        }
        if let sizeValue = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        }
    }

    private func targetFrame(for placement: WindowPlacement, in visible: CGRect) -> CGRect {
        switch placement {
        case .leftHalf:
            return CGRect(x: visible.minX, y: visible.minY, width: visible.width / 2, height: visible.height)
        case .rightHalf:
            return CGRect(x: visible.midX, y: visible.minY, width: visible.width / 2, height: visible.height)
        case .maximize:
            return visible
        case .center:
            let width = visible.width * 0.72
            let height = visible.height * 0.78
            return CGRect(x: visible.midX - width / 2, y: visible.midY - height / 2, width: width, height: height)
        }
    }
}
