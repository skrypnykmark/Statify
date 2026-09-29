import SwiftUI

enum Theme {
    static let green = Color(red: 0.118, green: 0.843, blue: 0.376) // #1ED760
    static let background = Color(red: 0.071, green: 0.071, blue: 0.071) // #121212
    static let surfaceRaised = Color(red: 0.122, green: 0.122, blue: 0.122) // #1F1F1F
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.702, green: 0.702, blue: 0.702) // #B3B3B3
    static let track = Color.white.opacity(0.18)
}

enum Metrics {
    static let panelWidth: CGFloat = 300
    static let artworkSize: CGFloat = 52
    static let playButtonSize: CGFloat = 34
    static let cornerRadius: CGFloat = 6
}
