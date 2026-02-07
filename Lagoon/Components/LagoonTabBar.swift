//
//  LagoonTabBar.swift
//  Lagoon
//
//  Created by Marcel Nicaeus on 29.01.26.
//

import SwiftUI

typealias LagoonTabBarTab = FabBarTab
typealias LagoonTabBarAction = FabBarAction

extension View {
    func lagoonTabBar<Value: Hashable>(
        selection: Binding<Value>,
        tabs: [LagoonTabBarTab<Value>],
        action: LagoonTabBarAction,
        isVisible: Bool = true
    ) -> some View {
        self.fabBar(selection: selection, tabs: tabs, action: action, isVisible: isVisible)
    }

    func lagoonTabBarSafeAreaPadding() -> some View {
        self.fabBarSafeAreaPadding()
    }
}
