import SwiftUI
import SpriteKit

// MARK: - Model
struct Chip: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
}

// MARK: - SwiftUI Wrapper
struct SelectionView: View {
    var action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale
    @State private var selectedTitles: [String] = []
    @State private var scene: FocusScene?

    let chips: [Chip] = [
        Chip(title: "Write",    icon: "pencil.and.outline", color: .teal),
        Chip(title: "Cook",     icon: "fork.knife",         color: .green),
        Chip(title: "Work",     icon: "laptopcomputer",     color: .indigo),
        Chip(title: "Exercise", icon: "figure.run",         color: .blue),
        Chip(title: "Podcast",  icon: "mic.fill",           color: .mint),
        Chip(title: "Explore",  icon: "safari.fill",        color: .cyan),
        Chip(title: "Learn",    icon: "book.fill",          color: .orange),
        Chip(title: "Code",     icon: "curlybraces.square", color: .pink),
        Chip(title: "Design",   icon: "paintpalette.fill",  color: .yellow),
        Chip(title: "Research", icon: "magnifyingglass",    color: .purple),
        Chip(title: "Meditate", icon: "brain.head.profile", color: .indigo),
        Chip(title: "Travel",   icon: "airplane",           color: .brown),
        Chip(title: "Finance",  icon: "banknote",           color: .magenta),
        Chip(title: "Garden",   icon: "leaf",               color: .lime),
        Chip(title: "Music",    icon: "music.quarternote.3",color: .orangeRed),
        Chip(title: "Photo",    icon: "camera",             color: .gray),
        Chip(title: "Shop",     icon: "cart",               color: .brown2)
    ]

    var body: some View {
        ZStack {
            // Title
            VStack(spacing: 10) {
                Text("Build Around What You Love")
                    .microAnimation(delay: 0.5)
                    .font(.system(size: 40).bold())
                Text("Choosing activities helps you track progress and stay motivated every day")
                    .foregroundStyle(.secondary)
                    .microAnimation(delay: 0.8)
            }
            .multilineTextAlignment(.center)
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 50)

            VStack(spacing: 0) {
                GeometryReader { proxy in
                    ZStack {
                        Color.clear.onAppear {
                            if scene == nil {
                                scene = FocusScene(
                                    size: proxy.size,
                                    chips: chips,
                                    displayScale: displayScale,
                                    backgroundColor: .clear,
                                    gravityY: -8,
                                    bounceFactor: 0.8,
                                    startDelay: 1.0,
                                    isDarkMode: (colorScheme == .dark),
                                    onSelectionChange: { selected in
                                        selectedTitles = selected
                                    }
                                )
                            } else {
                                scene?.setAppearance(isDark: (colorScheme == .dark))
                            }
                        }
                        if let scene = scene {
                            SpriteView(scene: scene, options: [.allowsTransparency])
                                .ignoresSafeArea()
                        }
                    }
                }

                PrimaryButton(title: "Continue", action: { action() })
                    .padding(.top, 30)
                    .padding(.bottom, 34)
                    .microAnimation(delay: 1.2)
                Spacer()
            }
        }
        .padding(.horizontal, 30)
        .onChange(of: colorScheme) { _, newScheme in
            scene?.setAppearance(isDark: (newScheme == .dark))
        }
    }
}

// MARK: - SpriteKit Scene
final class FocusScene: SKScene {
    private let chips: [Chip]
    private let displayScale: CGFloat
    private let backgroundColorConfig: SKColor
    private let restitution: CGFloat
    private let gravityY: CGFloat
    private let startDelay: TimeInterval
    private let onSelectionChange: ([String]) -> Void

    private var chipNodes: [(node: SKSpriteNode, chip: Chip)] = []
    private var selectedChips: Set<UUID> = []
    private var isDarkMode: Bool

    init(size: CGSize,
         chips: [Chip],
         displayScale: CGFloat,
         backgroundColor: SKColor,
         gravityY: CGFloat,
         bounceFactor: CGFloat,
         startDelay: TimeInterval,
         isDarkMode: Bool,
         onSelectionChange: @escaping ([String]) -> Void) {
        self.chips = chips
        self.displayScale = displayScale
        self.backgroundColorConfig = backgroundColor
        self.gravityY = gravityY
        self.restitution = bounceFactor
        self.startDelay = startDelay
        self.isDarkMode = isDarkMode
        self.onSelectionChange = onSelectionChange
        super.init(size: size)
        scaleMode = .resizeFill
    }

    required init?(coder: NSCoder) { nil }

    override func didMove(to view: SKView) {
        backgroundColor = backgroundColorConfig

        let extendedFrame = CGRect(x: frame.minX, y: frame.minY,
                                   width: frame.width, height: frame.height + 1000)
        physicsBody = SKPhysicsBody(edgeLoopFrom: extendedFrame)
        physicsWorld.gravity = CGVector(dx: 0, dy: gravityY)

        let attractor = SKFieldNode.radialGravityField()
        attractor.categoryBitMask = 0x40
        attractor.strength = 0.0
        attractor.falloff = 0.0
        attractor.minimumRadius = 100
        attractor.position = CGPoint(x: frame.midX, y: frame.height * 0.2)
        addChild(attractor)

        DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) {
            self.spawn(y: self.frame.height + 200)
        }
    }

    func setAppearance(isDark: Bool) {
        guard isDarkMode != isDark else { return }
        isDarkMode = isDark
        refreshAllChipTextures()
    }

    private func spawn(y: CGFloat) {
        for (i, chip) in chips.enumerated() {
            let view = renderedChipView(chip, selected: false)
            let image = render(view: view)
            let texture = SKTexture(image: image)

            let node = SKSpriteNode(texture: texture)
            node.size = image.size

            let corner = node.size.height / 2
            let bodyRect = CGRect(origin: CGPoint(x: -node.size.width/2, y: -node.size.height/2),
                                  size: node.size)
            let path = CGPath(roundedRect: bodyRect,
                              cornerWidth: corner, cornerHeight: corner, transform: nil)
            node.physicsBody = SKPhysicsBody(polygonFrom: path)
            node.physicsBody?.restitution = restitution
            node.physicsBody?.usesPreciseCollisionDetection = true
            node.name = chip.id.uuidString

            let w = node.frame.width
            let x = CGFloat.random(in: (w/2 + 16)...(size.width - w/2 - 16))
            node.position = CGPoint(x: x, y: y + CGFloat.random(in: 0...80))

            node.alpha = 0
            node.run(.sequence([.wait(forDuration: 0.01 * Double(i)),
                                .fadeIn(withDuration: 0)]))

            addChild(node)
            chipNodes.append((node, chip))
        }
    }

    private func refreshAllChipTextures() {
        for i in chipNodes.indices {
            let chip = chipNodes[i].chip
            let isSelected = selectedChips.contains(chip.id)
            let view = renderedChipView(chip, selected: isSelected)
            let image = render(view: view)
            chipNodes[i].node.texture = SKTexture(image: image)
            chipNodes[i].node.size = image.size
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else { return }

        if let touched = nodes(at: location).compactMap({ $0 as? SKSpriteNode }).first,
           let idx = chipNodes.firstIndex(where: { $0.node == touched }) {

            let chip = chipNodes[idx].chip
            let id = chip.id

            if selectedChips.contains(id) { selectedChips.remove(id) }
            else { selectedChips.insert(id) }

            let newView = renderedChipView(chip, selected: selectedChips.contains(id))
            let newImage = render(view: newView)
            touched.texture = SKTexture(image: newImage)

            let selectedTitles = chipNodes
                .filter { selectedChips.contains($0.chip.id) }
                .map { $0.chip.title }
            onSelectionChange(selectedTitles)
        }
    }

    private func renderedChipView(_ chip: Chip, selected: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: chip.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(chip.color)
            Text(chip.title)
                .font(.system(size: 17)).bold()
                .foregroundStyle(isDarkMode ? Color.white : Color.black)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(chip.color.opacity(0.15), in: Capsule())
        .overlay(
            Capsule().strokeBorder(isDarkMode ? Color.white : Color.black,
                                   lineWidth: selected ? 2 : 0)
        )
    }

    private func render(view: some View) -> UIImage {
        let renderer = ImageRenderer(content: view)
        renderer.scale = displayScale
        renderer.isOpaque = false
        return renderer.uiImage ?? UIImage()
    }
}

// MARK: - Color Extensions
extension Color {
    static let magenta = Color(.sRGB, red: 1.0, green: 0.0, blue: 1.0, opacity: 1.0)
    static let lime = Color(.sRGB, red: 0.196, green: 0.804, blue: 0.196, opacity: 1.0)
    static let orangeRed = Color(.sRGB, red: 1.0, green: 0.2706, blue: 0.0, opacity: 1.0)
    static let brown2 = Color(.sRGB, red: 0.65, green: 0.40, blue: 0.25, opacity: 1.0)
}

#Preview { SelectionView(action: {}) }
