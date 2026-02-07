import SwiftUI

struct Particle {
    var x: Double
    var y: Double
    let baseX: Double
    let baseY: Double
    let density: Double
    var velocityX: Double = 0
    var velocityY: Double = 0

    var settled: Bool {
        let dx = baseX - x
        let dy = baseY - y
        return sqrt(dx * dx + dy * dy) < 0.5
    }

    mutating func update() {
        let dx = baseX - x
        let dy = baseY - y
        let distance = sqrt(dx * dx + dy * dy)

        guard distance > 0.01 else { return }

        let forceDirectionX = dx / distance
        let forceDirectionY = dy / distance

        let maxDistance: Double = 280
        let force = (maxDistance - distance) / maxDistance
        let directionX = forceDirectionX * force * density
        let directionY = forceDirectionY * force * density

        if distance < 30 {
            x += directionX * 0.01
            y += directionY * 0.01
        } else if distance < maxDistance {
            x += directionX * 2.5
            y += directionY * 2.5
        } else {
            x -= (x - baseX) / 10
            y -= (y - baseY) / 10
        }
    }

    mutating func updateDissolve() {
        x += velocityX
        y += velocityY
    }
}
