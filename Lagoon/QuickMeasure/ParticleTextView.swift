import SwiftUI

struct ParticleTextView: View {
    let texts: [String]
    var fontSize: CGFloat = 72
    var particlesPerCharacter: Int = 600
    @Binding var dissolving: Bool

    @State private var particles: [Particle] = []
    @State private var size: CGSize = .zero
    @State private var displayLink: CADisplayLink?

    init(text: String, fontSize: CGFloat = 72, particlesPerCharacter: Int = 600, dissolving: Binding<Bool> = .constant(false)) {
        self.texts = [text]
        self.fontSize = fontSize
        self.particlesPerCharacter = particlesPerCharacter
        self._dissolving = dissolving
    }

    init(texts: [String], fontSize: CGFloat = 72, particlesPerCharacter: Int = 600, dissolving: Binding<Bool> = .constant(false)) {
        self.texts = texts
        self.fontSize = fontSize
        self.particlesPerCharacter = particlesPerCharacter
        self._dissolving = dissolving
    }

    private var totalCharCount: Int {
        texts.reduce(0) { $0 + max(1, $1.count) }
    }

    private var particleCount: Int {
        totalCharCount * particlesPerCharacter
    }

    var body: some View {
        Canvas { context, canvasSize in
            let shading = GraphicsContext.Shading.color(.primary.opacity(0.7))
            let particleSize = CGSize(width: 1.0, height: 1.0)
            for particle in particles {
                let rect = CGRect(origin: CGPoint(x: particle.x, y: particle.y), size: particleSize)
                context.fill(Path(ellipseIn: rect), with: shading)
            }
        }
        .overlay(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        size = geometry.size
                        createParticles()
                    }
            }
        )
        .onChange(of: texts) {
            createParticles()
        }
        .onChange(of: dissolving) {
            if dissolving {
                startDissolving()
            }
        }
        .onDisappear {
            stopDisplayLink()
        }
    }

    /// Builds a view for a single text, rendering any trailing fraction (e.g. "1/2") smaller.
    @ViewBuilder
    private func styledText(_ text: String) -> some View {
        if let spaceIndex = text.lastIndex(of: " "),
           text[text.index(after: spaceIndex)...].contains("/") {
            let whole = String(text[..<spaceIndex])
            let fraction = String(text[text.index(after: spaceIndex)...])
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(whole)
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                Text(fraction)
                    .font(.system(size: fontSize * 0.5, weight: .bold, design: .rounded))
            }
        } else {
            Text(text)
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
        }
    }

    private func createParticles() {
        stopDisplayLink()

        let renderWidth = max(size.width, 200)

        let content: AnyView
        if texts.count == 1 {
            content = AnyView(
                styledText(texts[0])
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(width: renderWidth)
            )
        } else {
            content = AnyView(
                HStack(spacing: 0) {
                    ForEach(Array(texts.enumerated()), id: \.offset) { _, text in
                        styledText(text)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(width: renderWidth)
            )
        }

        let renderer = ImageRenderer(content: content)
        renderer.scale = 1.0

        guard let image = renderer.uiImage,
              let cgImage = image.cgImage,
              let pixelData = cgImage.dataProvider?.data,
              let data = CFDataGetBytePtr(pixelData) else { return }

        let width = Int(image.size.width)
        let height = Int(image.size.height)

        guard width > 0, height > 0 else { return }

        let offsetX = (size.width - CGFloat(width)) / 2
        let offsetY = (size.height - CGFloat(height)) / 2

        particles = (0..<particleCount).map { _ in
            var x, y: Int
            repeat {
                x = Int.random(in: 0..<width)
                y = Int.random(in: 0..<height)
            } while data[((width * y) + x) * 4 + 3] < 128

            return Particle(
                x: Double.random(in: -size.width...size.width * 2),
                y: Double.random(in: 0...size.height * 2),
                baseX: Double(x) + offsetX,
                baseY: Double(y) + offsetY,
                density: Double.random(in: 5...20)
            )
        }

        startDisplayLink(dissolve: false)
    }

    private func startDisplayLink(dissolve: Bool) {
        stopDisplayLink()
        let link = CADisplayLink(target: DisplayLinkTarget { [self] in
            if dissolve {
                for i in particles.indices {
                    particles[i].updateDissolve()
                }
            } else {
                var allSettled = true
                for i in particles.indices {
                    particles[i].update()
                    if !particles[i].settled {
                        allSettled = false
                    }
                }
                if allSettled {
                    stopDisplayLink()
                }
            }
        }, selector: #selector(DisplayLinkTarget.tick))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    private func startDissolving() {
        stopDisplayLink()
        for i in particles.indices {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = Double.random(in: 3...12)
            particles[i].velocityX = cos(angle) * speed
            particles[i].velocityY = sin(angle) * speed
        }
        startDisplayLink(dissolve: true)
    }
}

// MARK: - CADisplayLink Target

private class DisplayLinkTarget {
    let callback: () -> Void
    init(_ callback: @escaping () -> Void) {
        self.callback = callback
    }
    @objc func tick() {
        callback()
    }
}
