import XCTest
@testable import MacLocalTools

final class SleepDoctorTests: XCTestCase {
    func testParseBlockersFindsActiveSleepAssertion() {
        let sample = """
        PreventUserIdleSystemSleep 1
        PreventSystemSleep 0
        NetworkClientActive 0
        """

        let blockers = SleepDoctor.parseBlockers(sample)
        XCTAssertEqual(blockers.count, 1)
        XCTAssertTrue(blockers[0].line.contains("PreventUserIdleSystemSleep"))
    }

    func testParseWakeEventsFindsRelevantLines() {
        let sample = """
        random line
        DarkWake from Normal Sleep
        MaintenanceWake due to timer
        Wake reason: EC.DarkPME
        """

        let events = SleepDoctor.parseWakeEvents(sample)
        XCTAssertEqual(events.count, 3)
    }

    func testInsightsDetectSharingdAndTCPKeepAlive() {
        let assertions = "PreventUserIdleSystemSleep named: sharingd"
        let custom = "tcpkeepalive 1\npowernap 0"
        let insights = SleepDoctor.buildInsights(assertions: assertions, custom: custom, log: "")

        XCTAssertTrue(insights.contains { $0.title.contains("sharingd") })
        XCTAssertTrue(insights.contains { $0.title.contains("TCPKeepAlive") })
        XCTAssertFalse(insights.contains { $0.title.contains("Power Nap") })
    }

    func testCountsDarkWakeEntries() {
        let log = "DarkWake\nDarkWake\nMaintenanceWake"
        XCTAssertEqual(SleepDoctor.countOccurrences("darkwake", in: log), 2)
    }
}
