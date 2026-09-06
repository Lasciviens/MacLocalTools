import Foundation

enum NetworkPolicy: Sendable {
    case denied
    case allowedForExplicitFeature(String)

    var allowsNetworkAccess: Bool {
        switch self {
        case .denied:
            return false
        case .allowedForExplicitFeature:
            return true
        }
    }
}

struct AppSecurityPolicy: Sendable {
    let networkPolicy: NetworkPolicy

    static let localOnly = AppSecurityPolicy(networkPolicy: .denied)
}
