import SwiftUI
import UIKit

/// A UIViewRepresentable that wraps a TabBarSegmentedControl for tab bar functionality.
/// The segmented control's labels are hidden and replaced with custom UIKit label views,
/// preserving UIKit's touch handling and glass effects while allowing full control over rendering.
@available(iOS 26.0, *)
struct LagoonTabBarRepresentable<Value: Hashable>: UIViewRepresentable {
    var tabs: [LagoonTabBarTab<Value>]
    var action: LagoonTabBarAction

    @Binding var activeTab: Value

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> GlassTabBarView<Value> {
        // Use system images for segment sizing - labels will be hidden
        let images = tabs.compactMap { _ in
            UIImage(systemName: "circle")
        }
        let control = TabBarSegmentedControl(items: images)
        control.showsLargeContentViewer = false
        let selectedIndex = tabs.firstIndex { $0.value == activeTab } ?? 0
        control.selectedSegmentIndex = selectedIndex

        // Set titles for accessibility
        for (index, tab) in tabs.enumerated() {
            control.setTitle(tab.title, forSegmentAt: index)
        }

        control.selectedSegmentTintColor = .label.withAlphaComponent(0.08)

        control.addTarget(context.coordinator, action: #selector(context.coordinator.tabSelected(_:)), for: .valueChanged)

        // Handle reselection (tapping already-selected segment)
        let coordinator = context.coordinator
        control.onReselect = { index in
            if index >= 0 && index < coordinator.parent.tabs.count {
                coordinator.parent.tabs[index].onReselect?()
            }
        }

        // Wrap in glass tab bar view with segmented control, tabs overlay, and FAB
        let container = GlassTabBarView(
            segmentedControl: control,
            tabs: tabs,
            selectedIndex: selectedIndex,
            action: action
        )

        container.labelsOverlay.inactiveTintColor = .label

        return container
    }

    func updateUIView(_ uiView: GlassTabBarView<Value>, context: Context) {
        context.coordinator.parent = self

        let control = uiView.segmentedControl
        let newIndex = tabs.firstIndex { $0.value == activeTab } ?? 0
        let selectionChanged = control.selectedSegmentIndex != newIndex
        if selectionChanged {
            control.selectedSegmentIndex = newIndex
        }

        // Always update the labels overlay's selected index - the segmented control
        // may already have the correct index from touch handling, but the overlay
        // needs to know the final selection for when onHighlightEnd is called
        uiView.labelsOverlay.setSelectedIndex(newIndex, animated: false)

        // Use .label for active tab color (black in light, white in dark)
        uiView.labelsOverlay.activeTintColor = .label

        // Update FAB icon if it changed
        uiView.updateFabIcon(systemImage: action.systemImage)
    }

    @MainActor
    class Coordinator: NSObject {
        var parent: LagoonTabBarRepresentable<Value>

        init(parent: LagoonTabBarRepresentable<Value>) {
            self.parent = parent
        }

        @objc func tabSelected(_ control: UISegmentedControl) {
            let index = control.selectedSegmentIndex
            if index >= 0 && index < parent.tabs.count {
                parent.activeTab = parent.tabs[index].value
            }
        }
    }
}
