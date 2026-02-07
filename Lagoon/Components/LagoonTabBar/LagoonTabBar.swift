import SwiftUI
import os

/// A customizable iOS 26 glass tab bar with a floating action button.
///
/// LagoonTabBar provides a native-looking iOS 26 tab bar where you control what goes in it,
/// including a FAB that morphs with the glass effect.
///
/// ## Usage
///
/// The recommended way to use LagoonTabBar is with the `.lagoonTabBar()` modifier:
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
/// .lagoonTabBar(
///     selection: $selectedTab,
///     tabs: [
///         LagoonTabBarTab(value: .home, title: "Home", systemImage: "house.fill"),
///         LagoonTabBarTab(value: .explore, title: "Explore", systemImage: "compass"),
///         LagoonTabBarTab(value: .profile, title: "Profile", systemImage: "person.fill"),
///     ],
///     action: LagoonTabBarAction(systemImage: "plus", accessibilityLabel: "Add Item") {
///         // Handle tap
///     }
/// )
/// ```
///
/// For more control over positioning, you can use the `LagoonTabBar` view directly.

@available(iOS 26.0, *)
struct LagoonTabBar<Value: Hashable>: View {
    /// The currently selected tab.
    @Binding var selection: Value

    /// The tabs to display.
    let tabs: [LagoonTabBarTab<Value>]

    /// The floating action button configuration.
    var action: LagoonTabBarAction

    /// Creates a LagoonTabBar with the specified configuration.
    ///
    /// - Parameters:
    ///   - selection: A binding to the currently selected tab.
    ///   - tabs: The tabs to display.
    ///   - action: The floating action button configuration.
    init(
        selection: Binding<Value>,
        tabs: [LagoonTabBarTab<Value>],
        action: LagoonTabBarAction
    ) {
        self._selection = selection
        self.tabs = tabs
        self.action = action
    }

    var body: some View {
        if tabs.isEmpty {
            Color.clear
                .frame(height: Constants.barHeight)
                .onAppear {
                    lagoonTabBarLogger.warning("LagoonTabBar initialized with empty tabs array - nothing will be displayed")
                }
        } else {
            LagoonTabBarRepresentable(
                tabs: tabs,
                action: action,
                activeTab: $selection
            )
            .frame(height: Constants.barHeight)
        }
    }
}
