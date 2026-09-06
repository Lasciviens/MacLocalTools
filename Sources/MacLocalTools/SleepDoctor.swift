import Foundation

struct SleepBlocker: Identifiable, Equatable, Sendable {
    let id = UUID()
    let line: String
}

struct WakeEvent: Identifiable, Equatable, Sendable {
    let id = UUID()
    let line: String
}

struct SleepInsight: Identifiable, Equatable, Sendable {
    enum Severity: String, Sendable { case info, warning }
    let id = UUID()
    let severity: Severity
    let title: String
    let detail: String
}

struct SleepDoctorReport: Sendable {
    let assertionsRaw: String
    let customRaw: String
    let logRaw: String
    let blockers: [SleepBlocker]
    let wakeEvents: [WakeEvent]
    let insights: [SleepInsight]
    let darkWakeCount: Int
    let maintenanceWakeCount: Int
}

struct SleepDoctor: Sendable {
    private let runner = ProcessRunner()

    func diagnose() async throws -> SleepDoctorReport {
        async let assertions = runner.run(executable: "/usr/bin/pmset", arguments: ["-g", "assertions"])
        async let custom = runner.run(executable: "/usr/bin/pmset", arguments: ["-g", "custom"])
        async let log = runner.run(executable: "/usr/bin/pmset", arguments: ["-g", "log"])

        let (assertionsResult, customResult, logResult) = try await (assertions, custom, log)
        let blockers = Self.parseBlockers(assertionsResult.stdout)
        let wakeEvents = Self.parseWakeEvents(logResult.stdout)
        let darkWakeCount = Self.countOccurrences("darkwake", in: logResult.stdout)
        let maintenanceWakeCount = Self.countOccurrences("maintenancewake", in: logResult.stdout)

        return SleepDoctorReport(
            assertionsRaw: assertionsResult.stdout,
            customRaw: customResult.stdout,
            logRaw: logResult.stdout,
            blockers: blockers,
            wakeEvents: wakeEvents,
            insights: Self.buildInsights(assertions: assertionsResult.stdout, custom: customResult.stdout, log: logResult.stdout),
            darkWakeCount: darkWakeCount,
            maintenanceWakeCount: maintenanceWakeCount
        )
    }

    static func parseBlockers(_ text: String) -> [SleepBlocker] {
        text
            .split(separator: "\n")
            .map(String.init)
            .filter { line in
                let lower = line.lowercased()
                return lower.contains("preventsystemsleep") ||
                    lower.contains("preventuseridlesystemsleep") ||
                    lower.contains("preventuseridledisplaysleep") ||
                    lower.contains("backgroundtask") ||
                    lower.contains("networkclientactive")
            }
            .filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                return !trimmed.hasSuffix(" 0") && !trimmed.hasSuffix("= 0")
            }
            .map(SleepBlocker.init(line:))
    }

    static func parseWakeEvents(_ text: String, limit: Int = 60) -> [WakeEvent] {
        let matches = text
            .split(separator: "\n")
            .map(String.init)
            .filter { line in
                let lower = line.lowercased()
                return lower.contains("darkwake") ||
                    lower.contains("maintenancewake") ||
                    lower.contains("wake reason") ||
                    lower.contains("wake requests")
            }
        return matches.suffix(limit).map(WakeEvent.init(line:))
    }

    static func buildInsights(assertions: String, custom: String, log: String) -> [SleepInsight] {
        let all = (assertions + "\n" + custom + "\n" + log).lowercased()
        var insights: [SleepInsight] = []

        if all.contains("sharingd") {
            insights.append(.init(severity: .warning, title: "Handoff / sharingd activity", detail: "sharingd appears in sleep-related diagnostics and can hold user-activity assertions."))
        }
        if custom.lowercased().contains("tcpkeepalive") && custom.range(of: #"tcpkeepalive\s+1"#, options: .regularExpression) != nil {
            insights.append(.init(severity: .info, title: "TCPKeepAlive enabled", detail: "The Mac may maintain network presence during sleep when macOS considers it necessary."))
        }
        if custom.lowercased().contains("powernap") && custom.range(of: #"powernap\s+1"#, options: .regularExpression) != nil {
            insights.append(.init(severity: .info, title: "Power Nap enabled", detail: "Background maintenance can intentionally wake the Mac during sleep."))
        }
        let darkWakes = countOccurrences("darkwake", in: log)
        if darkWakes >= 10 {
            insights.append(.init(severity: .warning, title: "Frequent DarkWake activity", detail: "Found \(darkWakes) DarkWake log entries in the available pmset history."))
        }
        if parseBlockers(assertions).isEmpty {
            insights.append(.init(severity: .info, title: "No obvious current blocker", detail: "No active high-level sleep-prevention assertion was detected in the current snapshot."))
        }
        return insights
    }

    static func countOccurrences(_ needle: String, in text: String) -> Int {
        text.lowercased().components(separatedBy: needle.lowercased()).count - 1
    }
}
