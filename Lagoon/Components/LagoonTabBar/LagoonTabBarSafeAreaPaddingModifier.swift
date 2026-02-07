import SwiftUI

// MARK: - Environment Key

@available(iOS 26.0, *)
extension EnvironmentValues {
    /// The bottom safe area padding needed to clear the LagoonTabBar.
    /// This is `barHeight + bottomPadding` minus the device's bottom safe area inset.
    @Entry var lagoonTabBarBottomSafeAreaPadding: CGFloat = Constants.barHeight + Constants.bottomPadding
}

// MARK: - View Modifier

/// View modifier that applies bottom safe area padding to clear the LagoonTabBar.
@available(iOS 26.0, *)
struct LagoonTabBarSafeAreaPaddingModifier: ViewModifier {
    @Environment(\.lagoonTabBarBottomSafeAreaPadding) private var padding

    func body(content: Content) -> some View {
        content.safeAreaPadding(.bottom, padding)
    }
}

@available(iOS 26.0, *)
extension View {
    /// Applies bottom safe area padding to clear the LagoonTabBar.
    ///
    /// Use this on scrollable content within each tab to ensure
    /// content isn't hidden behind the LagoonTabBar.
    ///
    /// ```swift
    /// Tab(value: .home) {
    ///     HomeView()
    ///         .lagoonTabBarSafeAreaPadding()
    ///         .toolbarVisibility(.hidden, for: .tabBar)
    /// }
    /// ```
    func lagoonTabBarSafeAreaPadding() -> some View {
        modifier(LagoonTabBarSafeAreaPaddingModifier())
    }
}
