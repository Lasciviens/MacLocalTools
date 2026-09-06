import Foundation

struct SystemTweaks: Sendable {
    private let runner = ProcessRunner()

    func setShowHiddenFiles(_ enabled: Bool) async throws {
        _ = try await runner.run(
            executable: "/usr/bin/defaults",
            arguments: ["write", "com.apple.finder", "AppleShowAllFiles", "-bool", enabled ? "true" : "false"]
        )
        _ = try await runner.run(executable: "/usr/bin/killall", arguments: ["Finder"])
    }

    func setShowAllFileExtensions(_ enabled: Bool) async throws {
        _ = try await runner.run(
            executable: "/usr/bin/defaults",
            arguments: ["write", "NSGlobalDomain", "AppleShowAllExtensions", "-bool", enabled ? "true" : "false"]
        )
        _ = try await runner.run(executable: "/usr/bin/killall", arguments: ["Finder"])
    }
}
