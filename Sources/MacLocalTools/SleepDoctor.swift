import Foundation

struct SleepBlocker: Identifiable, Equatable, Sendable {
    let id = UUID()
    let line: String
}

struct WakeEvent: Identifiable, Equatable, Sendable {
    let id = UUID()
    let line: String
}

struct SleepDoctorReport: Sendable {
    let assertionsRaw: String
    let customRaw: String
    let logRaw: String
    let blockers: [SleepBlocker]
    let wakeEvents: [WakeEvent]
}

struct SleepDoctor: Sendable {
    private let runner = ProcessRunner()

    func diagnose() async throws -> SleepDoctorReport {
        async let assertions = runner.run(executable: "/usr/bin/pmset", arguments: ["-g", "assertions"])
        async let custom = runner.run(executable: "/usr/bin/pmset", arguments: ["-g", "custom"])
        async let log = runner.run(executable: "/usr/bin/pmset", arguments: ["-g", "log"])

        let (assertionsResult, customResult, logResult) = try await (assertions, custom, log)

        return SleepDoctorReport(
            assertionsRaw: assertionsResult.stdout,
            customRaw: customResult.stdout,
            logRaw: logResult.stdout,
            blockers: Self.parseBlockers(assertionsResult.stdout),
            wakeEvents: Self.parseWakeEvents(logResult.stdout)
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
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasSuffix(" 0") }
            .map(SleepBlocker.init(line:))
    }

    static func parseWakeEvents(_ text: String, limit: Int = 40) -> [WakeEvent] {
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
}
