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
        return (dx * dx + dy * dy) < 0.25 // 0.5²
    }

    mutating func update() {
        let dx = baseX - x
        let dy = baseY - y
        let distSq = dx * dx + dy * dy

        guard distSq > 0.0001 else { return }

        let distance = sqrt(distSq)
        let invDist = 1.0 / distance
        let forceDirectionX = dx * invDist
        let forceDirectionY = dy * invDist

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
            x -= (x - baseX) * 0.1
            y -= (y - baseY) * 0.1
        }
    }

    mutating func updateDissolve() {
        x += velocityX
        y += velocityY
    }
}
