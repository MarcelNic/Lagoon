import SwiftUI

/// View modifier that positions a LagoonTabBar at the bottom of the view.
///
/// This modifier handles all the layout details:
/// - Wraps in `.safeAreaBar(edge: .bottom)`
/// - Applies appropriate padding
/// - Ignores bottom safe area for manual positioning
/// - Hides automatically on regular horizontal size class (iPad)
/// - Injects calculated safe area padding into the environment
@available(iOS 26.0, *)
struct LagoonTabBarModifier<Value: Hashable>: ViewModifier {
    @Binding var selection: Value
    let tabs: [LagoonTabBarTab<Value>]
    let action: LagoonTabBarAction
    let isVisible: Bool

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var bottomSafeAreaInset: CGFloat = 0

    /// Whether the LagoonTabBar should be displayed.
    /// Only shows on compact horizontal size class (iPhone) when visible.
    private var showsLagoonTabBar: Bool {
        horizontalSizeClass == .compact && isVisible
    }

    /// Total content margin needed to clear the LagoonTabBar.
    private var bottomContentMargin: CGFloat {
        Constants.barHeight + Constants.bottomPadding
    }

    /// The padding to inject into the environment.
    /// This is the total content margin minus the device's safe area inset,
    /// because `safeAreaPadding` adds to the existing safe area.
    /// Returns 0 when the LagoonTabBar is not showing.
    private var calculatedPadding: CGFloat {
        showsLagoonTabBar ? bottomContentMargin - bottomSafeAreaInset : 0
    }

    func body(content: Content) -> some View {
        content
            .safeAreaBar(edge: .bottom) {
                if showsLagoonTabBar {
                    LagoonTabBar(selection: $selection, tabs: tabs, action: action)
                        .padding(.horizontal, Constants.horizontalPadding)
                        .padding(.bottom, Constants.bottomPadding)
                }
            }
            .ignoresSafeArea(.all, edges: showsLagoonTabBar ? [.bottom] : [])
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.safeAreaInsets.bottom
            } action: { newValue in
                bottomSafeAreaInset = newValue
            }
            .environment(\.lagoonTabBarBottomSafeAreaPadding, calculatedPadding)
    }
}

@available(iOS 26.0, *)
extension View {
    /// Adds a LagoonTabBar to the bottom of the view.
    ///
    /// This is the recommended way to use LagoonTabBar. It handles positioning,
    /// safe area management, and automatically hides on iPad.
    ///
    /// ```swift
    /// TabView(selection: $selectedTab) {
    ///     Tab(value: .home) {
    ///         HomeView()
    ///             .lagoonTabBarSafeAreaPadding()
    ///             .toolbarVisibility(.hidden, for: .tabBar)
    ///     }
    ///     // more tabs...
    /// }
    /// .lagoonTabBar(selection: $selectedTab, tabs: tabs, action: action)
    /// ```
    ///
    /// - Parameters:
    ///   - selection: A binding to the currently selected tab.
    ///   - tabs: The tabs to display.
    ///   - action: The floating action button configuration.
    ///   - isVisible: Whether the LagoonTabBar is visible. Defaults to `true`.
    func lagoonTabBar<Value: Hashable>(
        selection: Binding<Value>,
        tabs: [LagoonTabBarTab<Value>],
        action: LagoonTabBarAction,
        isVisible: Bool = true
    ) -> some View {
        modifier(LagoonTabBarModifier(selection: selection, tabs: tabs, action: action, isVisible: isVisible))
    }
}
