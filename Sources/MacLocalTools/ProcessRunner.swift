import Foundation

struct ProcessResult: Sendable {
    let stdout: String
    let stderr: String
    let exitCode: Int32
}

enum ProcessRunnerError: Error, LocalizedError {
    case executableNotAllowed(String)

    var errorDescription: String? {
        switch self {
        case .executableNotAllowed(let path):
            return "Executable is not allow-listed: \(path)"
        }
    }
}

struct ProcessRunner: Sendable {
    private static let allowedExecutables: Set<String> = [
        "/usr/bin/pmset",
        "/usr/bin/defaults",
        "/usr/bin/killall"
    ]

    func run(executable: String, arguments: [String]) async throws -> ProcessResult {
        guard Self.allowedExecutables.contains(executable) else {
            throw ProcessRunnerError.executableNotAllowed(executable)
        }

        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            process.terminationHandler = { process in
                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

                continuation.resume(returning: ProcessResult(
                    stdout: String(decoding: stdoutData, as: UTF8.self),
                    stderr: String(decoding: stderrData, as: UTF8.self),
                    exitCode: process.terminationStatus
                ))
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
