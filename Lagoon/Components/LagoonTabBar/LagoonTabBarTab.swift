import Foundation

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

    /// Called when the user taps this tab while it's already selected.
    /// Useful for scroll-to-top or similar behaviors.
    let onReselect: (() -> Void)?

    /// Creates a tab with an SF Symbol icon.
    ///
    /// - Parameters:
    ///   - value: The tab identifier.
    ///   - title: The title displayed below the icon.
    ///   - systemImage: The SF Symbol name for the icon.
    ///   - onReselect: Called when the user taps this tab while it's already selected.
    init(
        value: Value,
        title: String,
        systemImage: String,
        onReselect: (() -> Void)? = nil
    ) {
        self.value = value
        self.title = title
        self.systemImage = systemImage
        self.image = nil
        self.imageBundle = nil
        self.onReselect = onReselect
    }

    /// Creates a tab with a custom image from a bundle.
    ///
    /// - Parameters:
    ///   - value: The tab identifier.
    ///   - title: The title displayed below the icon.
    ///   - image: The custom image name.
    ///   - imageBundle: The bundle containing the image. Defaults to `.main`.
    ///   - onReselect: Called when the user taps this tab while it's already selected.
    init(
        value: Value,
        title: String,
        image: String,
        imageBundle: Bundle? = nil,
        onReselect: (() -> Void)? = nil
    ) {
        self.value = value
        self.title = title
        self.systemImage = nil
        self.image = image
        self.imageBundle = imageBundle ?? .main
        self.onReselect = onReselect
    }
}
