import UIKit

/// The symbol effect to play when a tab is selected.
@available(iOS 26.0, *)
enum TabSymbolEffect {
    case bounce
    case wiggle
    case rotate
    case breathe

    func apply(to imageView: UIImageView) {
        switch self {
        case .bounce:
            imageView.addSymbolEffect(.bounce, options: .nonRepeating)
        case .wiggle:
            imageView.addSymbolEffect(.wiggle, options: .nonRepeating)
        case .rotate:
            imageView.addSymbolEffect(.rotate, options: .nonRepeating)
        case .breathe:
            imageView.addSymbolEffect(.breathe, options: .nonRepeating)
        }
    }
}

/// A tab configuration for LagoonTabBar.
///
/// Each tab represents an item in the tab bar with an icon and title.
/// The tab is identified by a generic `Value` type that must conform to `Hashable`.
@available(iOS 26.0, *)
struct LagoonTabBarTab<Value: Hashable>: Identifiable {
    var id: Value { value }

    /// The tab identifier.
    let value: Value

    /// The title displayed below the icon.
    let title: String

    /// The SF Symbol name for the icon. Used when `image` is nil.
    let systemImage: String?

    /// The custom image name from a bundle. Takes precedence over `systemImage` when set.
    let image: String?

    /// The bundle containing the custom image. Defaults to `.main` if not specified.
    let imageBundle: Bundle?

    /// The symbol effect to play when this tab is selected.
    let symbolEffect: TabSymbolEffect

    /// Called when the user taps this tab while it's already selected.
    /// Useful for scroll-to-top or similar behaviors.
    let onReselect: (() -> Void)?

    /// Creates a tab with an SF Symbol icon.
    init(
        value: Value,
        title: String,
        systemImage: String,
        symbolEffect: TabSymbolEffect = .bounce,
        onReselect: (() -> Void)? = nil
    ) {
        self.value = value
        self.title = title
        self.systemImage = systemImage
        self.image = nil
        self.imageBundle = nil
        self.symbolEffect = symbolEffect
        self.onReselect = onReselect
    }

    /// Creates a tab with a custom image from a bundle.
    init(
        value: Value,
        title: String,
        image: String,
        imageBundle: Bundle? = nil,
        symbolEffect: TabSymbolEffect = .bounce,
        onReselect: (() -> Void)? = nil
    ) {
        self.value = value
        self.title = title
        self.systemImage = nil
        self.image = image
        self.imageBundle = imageBundle ?? .main
        self.symbolEffect = symbolEffect
        self.onReselect = onReselect
    }
}
