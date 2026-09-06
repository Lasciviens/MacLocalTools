import SwiftUI

@main
struct MacLocalToolsApp: App {
    var body: some Scene {
        MenuBarExtra("MacLocalTools", systemImage: "stethoscope") {
            SleepDoctorView()
                .frame(width: 560, height: 520)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
private final class SleepDoctorViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var report: SleepDoctorReport?
    @Published var errorMessage: String?

    private let doctor = SleepDoctor()

    func refresh() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                report = try await doctor.diagnose()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

private struct SleepDoctorView: View {
    @StateObject private var model = SleepDoctorViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Sleep Doctor")
                        .font(.title2.bold())
                    Text("Local macOS sleep and wake diagnostics")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Refresh") {
                    model.refresh()
                }
                .disabled(model.isLoading)
            }

            Divider()

            if model.isLoading {
                ProgressView("Reading pmset diagnostics…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = model.errorMessage {
                ContentUnavailableView(
                    "Diagnosis failed",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
            } else if let report = model.report {
                List {
                    Section("Possible sleep blockers") {
                        if report.blockers.isEmpty {
                            Text("No obvious blocker found in current assertions.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(report.blockers) { blocker in
                                Text(blocker.line)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                        }
                    }

                    Section("Recent wake-related events") {
                        if report.wakeEvents.isEmpty {
                            Text("No matching wake events found.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(report.wakeEvents) { event in
                                Text(event.line)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    "Ready to diagnose",
                    systemImage: "moon.zzz",
                    description: Text("Press Refresh to inspect current sleep assertions and recent wake events.")
                )
            }

            Divider()
            Text("Network access: disabled by default")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .task {
            if model.report == nil {
                model.refresh()
            }
        }
    }
}
