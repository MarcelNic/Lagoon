import SwiftUI

struct ParticleTextView: View {
    let text: String
    var fontSize: CGFloat = 72
    var particlesPerCharacter: Int = 600

    @State private var particles: [Particle] = []
    @State private var size: CGSize = .zero
    @State private var timer: Timer?

    private var particleCount: Int {
        max(1, text.count) * particlesPerCharacter
    }

    var body: some View {
        Canvas { context, canvasSize in
            for particle in particles {
                let path = Path(ellipseIn: CGRect(x: particle.x, y: particle.y, width: 1.2, height: 1.2))
                context.fill(path, with: .color(.primary.opacity(0.7)))
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
        .onChange(of: text) {
            createParticles()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private func createParticles() {
        timer?.invalidate()
        timer = nil

        let renderer = ImageRenderer(content: Text(text)
            .font(.system(size: fontSize, weight: .bold, design: .rounded)))
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

        startTimer()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 120.0, repeats: true) { _ in
            var allSettled = true
            for i in particles.indices {
                particles[i].update()
                if !particles[i].settled {
                    allSettled = false
                }
            }
            if allSettled {
                timer?.invalidate()
                timer = nil
            }
        }
    }
}
