import Foundation

/// Configuration for the floating action button (FAB) in LagoonTabBar.
///
/// The FAB appears as a circular glass button next to the tab items,
/// morphing with the iOS 26 glass effect.
@available(iOS 26.0, *)
struct LagoonTabBarAction {
    /// The SF Symbol name for the button icon.
    let systemImage: String

    /// The accessibility label for VoiceOver users.
    let accessibilityLabel: String

    /// The action to perform when the button is tapped.
    let action: () -> Void

    /// Creates a floating action button configuration.
    ///
    /// - Parameters:
    ///   - systemImage: The SF Symbol name for the button icon.
    ///   - accessibilityLabel: The accessibility label for VoiceOver users.
    ///   - action: The action to perform when the button is tapped.
    init(
        systemImage: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }
}
