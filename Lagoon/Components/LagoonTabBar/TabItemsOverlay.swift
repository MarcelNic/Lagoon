import UIKit

/// A UIView that overlays custom tab items on top of the segmented control.
/// Positioned using Auto Layout to align with each segment.
@available(iOS 26.0, *)
final class TabItemsOverlay<Value: Hashable>: UIView {
    private var tabItemViews: [TabItemView<Value>] = []
    private var selectedIndex: Int = 0
    private var highlightedIndex: Int?

    var activeTintColor: UIColor = .label {
        didSet {
            tabItemViews.forEach { $0.activeTintColor = activeTintColor }
            updateHighlightStates()
        }
    }

    var inactiveTintColor: UIColor = .label {
        didSet {
            tabItemViews.forEach { $0.inactiveTintColor = inactiveTintColor }
            updateHighlightStates()
        }
    }

    init(tabs: [LagoonTabBarTab<Value>], selectedIndex: Int) {
        self.selectedIndex = selectedIndex
        super.init(frame: .zero)

        isUserInteractionEnabled = false
        accessibilityElementsHidden = true
        setupTabViews(tabs: tabs)
        updateHighlightStates()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupTabViews(tabs: [LagoonTabBarTab<Value>]) {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false

        for tab in tabs {
            let tabItemView = TabItemView(tab: tab)
            tabItemView.activeTintColor = activeTintColor
            tabItemView.inactiveTintColor = inactiveTintColor
            tabItemViews.append(tabItemView)
            stackView.addArrangedSubview(tabItemView)
        }

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func setSelectedIndex(_ index: Int, animated: Bool) {
        let changed = selectedIndex != index
        selectedIndex = index
        if highlightedIndex == nil {
            updateHighlightStates(animated: animated)
        }
        if changed {
            playSymbolEffect(at: index)
        }
    }

    private func playSymbolEffect(at index: Int) {
        guard index >= 0 && index < tabItemViews.count else { return }
        tabItemViews[index].playSymbolEffect()
    }

    func setHighlightedIndex(_ index: Int?) {
        highlightedIndex = index
        updateHighlightStates(animated: true)
    }

    private func updateHighlightStates(animated: Bool = false) {
        let activeIndex = highlightedIndex ?? selectedIndex

        for (index, view) in tabItemViews.enumerated() {
            let shouldHighlight = (index == activeIndex)
            if view.isHighlighted != shouldHighlight {
                view.isHighlighted = shouldHighlight
                view.updateColors(animated: animated)
            }
        }
    }
}
