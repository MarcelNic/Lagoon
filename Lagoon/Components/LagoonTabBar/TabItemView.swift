import UIKit
import os

/// A UIView that displays a single tab item with an icon and title stacked vertically.
/// Uses a UIImageView for the icon to support SF Symbol effects (bounce, wiggle, etc.).
@available(iOS 26.0, *)
final class TabItemView<Value: Hashable>: UIView {
    private let imageView: UIImageView
    private let titleLabel: UILabel
    private let imageAreaHeight: CGFloat = Constants.iconViewSize
    private let effect: TabSymbolEffect

    var activeTintColor: UIColor = .label {
        didSet { updateColors() }
    }

    var inactiveTintColor: UIColor = .label {
        didSet { updateColors() }
    }

    var isHighlighted: Bool = false

    init(tab: LagoonTabBarTab<Value>) {
        let config = UIImage.SymbolConfiguration(
            pointSize: Constants.tabIconPointSize,
            weight: .medium,
            scale: .large
        )

        var tabImage: UIImage?
        if let imageName = tab.image {
            let bundle = tab.imageBundle ?? .main
            tabImage = UIImage(named: imageName, in: bundle, with: config)
            if tabImage == nil {
                lagoonTabBarLogger.warning("Failed to load image '\(imageName)' from bundle for tab '\(tab.title)'")
            }
        } else if let systemImageName = tab.systemImage {
            tabImage = UIImage(systemName: systemImageName, withConfiguration: config)
            if tabImage == nil {
                lagoonTabBarLogger.warning("Failed to load SF Symbol '\(systemImageName)' for tab '\(tab.title)'")
            }
        }

        imageView = UIImageView(image: tabImage)
        imageView.contentMode = .center
        imageView.tintAdjustmentMode = .automatic

        titleLabel = UILabel()
        titleLabel.text = tab.title
        titleLabel.font = .systemFont(ofSize: Constants.tabTitleFontSize, weight: .medium)
        titleLabel.textAlignment = .center

        self.effect = tab.symbolEffect

        super.init(frame: .zero)

        isOpaque = false
        isUserInteractionEnabled = false

        addSubview(imageView)
        addSubview(titleLabel)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.heightAnchor.constraint(equalToConstant: imageAreaHeight),

            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor),
        ])

        // Vertically center the image+label group
        let group = UILayoutGuide()
        addLayoutGuide(group)
        NSLayoutConstraint.activate([
            group.topAnchor.constraint(equalTo: imageView.topAnchor),
            group.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            group.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        updateColors()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateColors(animated: Bool = false) {
        let color = isHighlighted ? activeTintColor : inactiveTintColor

        if animated {
            UIView.animate(withDuration: Constants.colorTransitionDuration) {
                self.imageView.tintColor = color
                self.titleLabel.textColor = color
            }
        } else {
            imageView.tintColor = color
            titleLabel.textColor = color
        }
    }

    func playSymbolEffect() {
        effect.apply(to: imageView)
    }
}
