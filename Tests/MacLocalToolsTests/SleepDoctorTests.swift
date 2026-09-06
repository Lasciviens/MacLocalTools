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
}
