import Foundation
import IOKit.ps

struct BatterySnapshot: Sendable {
    let percentage: Int
    let isCharging: Bool
    let powerSource: String
    let timeRemainingMinutes: Int?
}

struct BatteryMonitor {
    func snapshot() -> BatterySnapshot? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
        else { return nil }

        for source in list {
            guard let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }

            let current = description[kIOPSCurrentCapacityKey as String] as? Int ?? 0
            let max = description[kIOPSMaxCapacityKey as String] as? Int ?? 100
            let percentage = max > 0 ? Int((Double(current) / Double(max) * 100).rounded()) : 0
            let state = description[kIOPSPowerSourceStateKey as String] as? String ?? "Unknown"
            let charging = description[kIOPSIsChargingKey as String] as? Bool ?? false

            var remaining: Int?
            let estimate = IOPSGetTimeRemainingEstimate()
            if estimate > 0, estimate != kIOPSTimeRemainingUnlimited, estimate != kIOPSTimeRemainingUnknown {
                remaining = Int((estimate / 60).rounded())
            }

            return BatterySnapshot(
                percentage: percentage,
                isCharging: charging,
                powerSource: state,
                timeRemainingMinutes: remaining
            )
        }
        return nil
    }
}
