//
//  LagoonTabBar.swift
//  Lagoon
//
//  Created by Marcel Nicaeus on 29.01.26.
//

import SwiftUI
import UIKit

struct LagoonTabBar<TabItemView: View>: UIViewRepresentable {
    var size: CGSize
    var activeTint: Color = .primary
    var inActiveTint: Color = .primary.opacity(0.45)
    var barTint: Color = .gray.opacity(0.2)
    @Binding var activeTab: LagoonTab
    @ViewBuilder var tabItemView: (LagoonTab) -> TabItemView

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UISegmentedControl {
        let items = LagoonTab.allCases.map(\.rawValue)
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = activeTab.index

        // Tab Item Views in Images konvertieren
        for (index, tab) in LagoonTab.allCases.enumerated() {
            let renderer = ImageRenderer(content: tabItemView(tab))
            renderer.scale = 2
            if let image = renderer.uiImage {
                control.setImage(image, forSegmentAt: index)
            }
        }

        // Hintergrund-ImageView ausblenden
        DispatchQueue.main.async {
            for subview in control.subviews {
                if subview is UIImageView && subview != control.subviews.last {
                    subview.alpha = 0
                }
            }
        }

        control.selectedSegmentTintColor = UIColor(barTint)
        control.setTitleTextAttributes([
            .foregroundColor: UIColor(activeTint)
        ], for: .selected)
        control.setTitleTextAttributes([
            .foregroundColor: UIColor(inActiveTint)
        ], for: .normal)

        control.addTarget(
            context.coordinator,
            action: #selector(context.coordinator.tabSelected(_:)),
            for: .valueChanged
        )
        return control
    }

    func updateUIView(_ uiView: UISegmentedControl, context: Context) {
        uiView.selectedSegmentIndex = activeTab.index
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: UISegmentedControl,
        context: Context
    ) -> CGSize? {
        return size
    }

    class Coordinator: NSObject {
        var parent: LagoonTabBar
        init(parent: LagoonTabBar) {
            self.parent = parent
        }

        @objc func tabSelected(_ control: UISegmentedControl) {
            parent.activeTab = LagoonTab.allCases[control.selectedSegmentIndex]
        }
    }
}
