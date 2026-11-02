import SwiftUI
import UIKit

enum Theme {
    static let accent = Color(red: 0.26, green: 0.47, blue: 0.96)
    static let success = Color(red: 0.20, green: 0.72, blue: 0.47)
    static let warning = Color(red: 0.98, green: 0.62, blue: 0.18)
    static let frog = Color(red: 0.33, green: 0.69, blue: 0.33)
    static let reflect = Color(red: 0.42, green: 0.36, blue: 0.90)
    static let background = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var capitalizingFirst: String {
        guard let first = first else { return self }
        return first.uppercased() + dropFirst()
    }
}

enum Haptics {
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func tap() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
}
