import AppKit
import SwiftUI

@main
struct MacLocalToolsApp: App {
    var body: some Scene {
        MenuBarExtra("MacLocalTools", systemImage: "wrench.and.screwdriver") {
            RootView()
                .frame(width: 680, height: 620)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var system = SystemSnapshot(cpuLoadPercent: 0, memoryUsedBytes: 0, memoryTotalBytes: 0)
    @Published var battery: BatterySnapshot?
    private let systemMonitor = SystemMonitor()
    private let batteryMonitor = BatteryMonitor()
    private var timer: Timer?

    func start() {
        refresh()
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func refresh() {
        system = systemMonitor.snapshot()
        battery = batteryMonitor.snapshot()
    }
}

@MainActor
final class SleepDoctorViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var report: SleepDoctorReport?
    @Published var errorMessage: String?
    private let doctor = SleepDoctor()

    func refresh() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do { report = try await doctor.diagnose() }
            catch { errorMessage = error.localizedDescription }
            isLoading = false
        }
    }
}

private struct RootView: View {
    @StateObject private var dashboard = DashboardViewModel()
    @StateObject private var clipboard = ClipboardManager()

    var body: some View {
        TabView {
            OverviewView(model: dashboard)
                .tabItem { Label("Monitor", systemImage: "gauge.with.dots.needle.67percent") }
            SleepDoctorView()
                .tabItem { Label("Sleep", systemImage: "moon.zzz") }
            ClipboardView(manager: clipboard)
                .tabItem { Label("Clipboard", systemImage: "doc.on.clipboard") }
            WindowToolsView()
                .tabItem { Label("Windows", systemImage: "rectangle.split.2x1") }
            TweaksView()
                .tabItem { Label("Tweaks", systemImage: "switch.2") }
        }
        .padding(8)
        .onAppear {
            dashboard.start()
            clipboard.start()
        }
        .onDisappear {
            dashboard.stop()
            clipboard.stop()
        }
    }
}

private struct OverviewView: View {
    @ObservedObject var model: DashboardViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("MacLocalTools").font(.title.bold())
                Text("Local-first macOS diagnostics and utilities").foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    MetricCard(title: "CPU", value: String(format: "%.1f%%", model.system.cpuLoadPercent), systemImage: "cpu")
                    MetricCard(title: "Memory", value: memoryText, systemImage: "memorychip")
                    MetricCard(title: "Battery", value: batteryText, systemImage: "battery.75percent")
                }

                GroupBox("Privacy") {
                    VStack(alignment: .leading, spacing: 7) {
                        Label("No telemetry or analytics", systemImage: "checkmark.shield")
                        Label("No outbound networking implementation", systemImage: "network.slash")
                        Label("Clipboard history stays in memory only", systemImage: "lock")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Temperature") {
                    Text("Not exposed in this build. Reliable Apple Silicon temperature readings require privileged/private interfaces; MacLocalTools intentionally avoids them for now.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
    }

    private var memoryText: String {
        guard model.system.memoryTotalBytes > 0 else { return "—" }
        let used = ByteCountFormatter.string(fromByteCount: Int64(model.system.memoryUsedBytes), countStyle: .memory)
        let total = ByteCountFormatter.string(fromByteCount: Int64(model.system.memoryTotalBytes), countStyle: .memory)
        return "\(used) / \(total)"
    }

    private var batteryText: String {
        guard let battery = model.battery else { return "—" }
        return "\(battery.percentage)%\(battery.isCharging ? " ⚡︎" : "")"
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: systemImage).foregroundStyle(.secondary)
                Text(value).font(.headline).lineLimit(2).minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
        }
    }
}

private struct SleepDoctorView: View {
    @StateObject private var model = SleepDoctorViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Sleep Doctor").font(.title2.bold())
                    Text("pmset-based local sleep diagnostics").foregroundStyle(.secondary)
                }
                Spacer()
                Button("Refresh") { model.refresh() }.disabled(model.isLoading)
            }

            if model.isLoading {
                ProgressView("Reading sleep diagnostics…").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = model.errorMessage {
                ContentUnavailableView("Diagnosis failed", systemImage: "exclamationmark.triangle", description: Text(error))
            } else if let report = model.report {
                List {
                    Section("Summary") {
                        LabeledContent("DarkWake entries", value: "\(report.darkWakeCount)")
                        LabeledContent("MaintenanceWake entries", value: "\(report.maintenanceWakeCount)")
                        LabeledContent("Current blockers", value: "\(report.blockers.count)")
                    }
                    Section("Interpretation") {
                        ForEach(report.insights) { insight in
                            VStack(alignment: .leading, spacing: 3) {
                                Label(insight.title, systemImage: insight.severity == .warning ? "exclamationmark.triangle" : "info.circle")
                                    .font(.headline)
                                Text(insight.detail).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    Section("Current assertions") {
                        if report.blockers.isEmpty { Text("No obvious blocker found.").foregroundStyle(.secondary) }
                        ForEach(report.blockers) { Text($0.line).font(.system(.caption, design: .monospaced)).textSelection(.enabled) }
                    }
                    Section("Recent wake events") {
                        ForEach(report.wakeEvents) { Text($0.line).font(.system(.caption, design: .monospaced)).textSelection(.enabled) }
                    }
                }
            } else {
                ContentUnavailableView("Ready to diagnose", systemImage: "moon.zzz", description: Text("Press Refresh to inspect sleep behavior."))
            }
        }
        .padding()
        .task { if model.report == nil { model.refresh() } }
    }
}

private struct ClipboardView: View {
    @ObservedObject var manager: ClipboardManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Clipboard").font(.title2.bold())
                    Text("RAM-only history; nothing is persisted to disk").foregroundStyle(.secondary)
                }
                Spacer()
                Button("Clear") { manager.clear() }.disabled(manager.entries.isEmpty)
            }

            if manager.entries.isEmpty {
                ContentUnavailableView("No clipboard history", systemImage: "doc.on.clipboard", description: Text("Copy text in any app and it will appear here."))
            } else {
                List(manager.entries) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.text).lineLimit(3).textSelection(.enabled)
                            Text(entry.capturedAt, style: .time).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Copy") { manager.copy(entry) }
                    }
                }
            }
        }
        .padding()
    }
}

private struct WindowToolsView: View {
    @State private var message: String?
    private let manager = WindowManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Window Manager").font(.title2.bold())
            Text("Moves the currently focused window. Accessibility permission is required.").foregroundStyle(.secondary)

            ForEach(WindowPlacement.allCases) { placement in
                Button(placement.rawValue) {
                    do {
                        try manager.moveFrontmostWindow(placement)
                        message = "Applied: \(placement.rawValue)"
                    } catch { message = error.localizedDescription }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !manager.hasAccessibilityPermission {
                Button("Open Accessibility Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }

            if let message { Text(message).font(.caption).foregroundStyle(.secondary) }
            Spacer()
        }
        .padding()
    }
}

private struct TweaksView: View {
    @State private var status: String?
    @State private var isWorking = false
    private let tweaks = SystemTweaks()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Safe Tweaks").font(.title2.bold())
            Text("Only fixed, allow-listed macOS commands are used. No arbitrary shell execution.").foregroundStyle(.secondary)

            tweakRow("Hidden Finder files", enable: "Show", disable: "Hide") {
                try await tweaks.setShowHiddenFiles($0)
            }
            tweakRow("All file extensions", enable: "Show", disable: "Hide") {
                try await tweaks.setShowAllFileExtensions($0)
            }

            if let status { Text(status).font(.caption).foregroundStyle(.secondary) }
            Spacer()
        }
        .padding()
    }

    @ViewBuilder
    private func tweakRow(_ title: String, enable: String, disable: String, action: @escaping (Bool) async throws -> Void) -> some View {
        GroupBox(title) {
            HStack {
                Button(enable) { run(true, action: action) }.disabled(isWorking)
                Button(disable) { run(false, action: action) }.disabled(isWorking)
                Spacer()
            }
        }
    }

    private func run(_ enabled: Bool, action: @escaping (Bool) async throws -> Void) {
        isWorking = true
        Task {
            do {
                try await action(enabled)
                status = "Applied successfully."
            } catch { status = error.localizedDescription }
            isWorking = false
        }
    }
}
