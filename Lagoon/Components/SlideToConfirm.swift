import SwiftUI
import CoreHaptics

/// Slide to action button with liquid glass effect
struct SlideToConfirm: View {
    let label: String
    let icon: String
    let action: () -> Void

    @State private var offset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var hapticEngine: CHHapticEngine?
    @State private var hapticPlayer: CHHapticAdvancedPatternPlayer?

    private let knobSize: CGFloat = 72
    private let trackHeight: CGFloat = 88
    private let padding: CGFloat = 8
    private let commitThreshold: CGFloat = 0.85

    var body: some View {
        GeometryReader { geo in
            let maxOffset = geo.size.width - knobSize - (padding * 2)
            let progress = min(1, max(0, offset / maxOffset))

            ZStack(alignment: .leading) {
                // Track (Liquid Glass)
                Color.clear
                    .glassEffect(.regular.tint(Color.black.opacity(0.1)), in: .capsule(style: .continuous))

                // Dots across the track
                HStack(spacing: 16) {
                    ForEach(0..<8, id: \.self) { _ in
                        Circle()
                            .fill(Color(light: Color.black, dark: Color.white).opacity(0.5))
                            .frame(width: 6, height: 6)
                    }
                }
                .opacity(1 - progress)
                .frame(maxWidth: .infinity)

                // Knob
                Circle()
                    .fill(.clear)
                    .frame(width: knobSize, height: knobSize)
                    .glassEffect(.regular.tint(.white).interactive(), in: .circle)
                    .overlay {
                        ZStack {
                            Image(systemName: icon)
                                .opacity(1 - progress)
                                .blur(radius: progress * 10)

                            Image(systemName: "checkmark")
                                .opacity(progress)
                                .blur(radius: (1 - progress) * 10)
                        }
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.black)
                    }
                    .offset(x: offset + padding)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newOffset = min(maxOffset, max(0, value.translation.width))
                                offset = newOffset

                                let currentProgress = newOffset / maxOffset

                                if currentProgress > 0.05 && !isDragging {
                                    isDragging = true
                                    startContinuousHaptic()
                                } else if currentProgress <= 0.05 && isDragging {
                                    isDragging = false
                                    stopContinuousHaptic()
                                }

                                // Update intensity based on progress
                                if isDragging {
                                    updateHapticIntensity(progress: currentProgress)
                                }
                            }
                            .onEnded { _ in
                                stopContinuousHaptic()
                                isDragging = false
                                let currentProgress = offset / maxOffset

                                if currentProgress >= commitThreshold {
                                    playFireworkHaptic()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        offset = maxOffset
                                    }
                                    action()
                                } else {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        offset = 0
                                    }
                                }
                            }
                    )
            }
        }
        .frame(height: trackHeight)
        .containerShape(.capsule)
        .onAppear {
            prepareHapticEngine()
        }
        .onDisappear {
            stopContinuousHaptic()
            hapticEngine?.stop()
        }
    }

    // MARK: - Core Haptics

    private func prepareHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let engine = try CHHapticEngine()
            engine.resetHandler = { [self] in
                try? hapticEngine?.start()
            }
            engine.stoppedHandler = { _ in }
            try engine.start()
            hapticEngine = engine
        } catch {}
    }

    private func startContinuousHaptic() {
        guard let engine = hapticEngine else { return }

        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)

        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [intensity, sharpness],
            relativeTime: 0,
            duration: 30
        )

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            hapticPlayer = try engine.makeAdvancedPlayer(with: pattern)
            try hapticPlayer?.start(atTime: CHHapticTimeImmediate)
        } catch {}
    }

    private func updateHapticIntensity(progress: CGFloat) {
        let intensity = Float(0.4 + progress * 0.6)
        let sharpness = Float(0.3 + progress * 0.7)

        let intensityParam = CHHapticDynamicParameter(
            parameterID: .hapticIntensityControl,
            value: intensity,
            relativeTime: 0
        )
        let sharpnessParam = CHHapticDynamicParameter(
            parameterID: .hapticSharpnessControl,
            value: sharpness,
            relativeTime: 0
        )

        try? hapticPlayer?.sendParameters([intensityParam, sharpnessParam], atTime: CHHapticTimeImmediate)
    }

    private func stopContinuousHaptic() {
        try? hapticPlayer?.stop(atTime: CHHapticTimeImmediate)
        hapticPlayer = nil
    }

    private func playFireworkHaptic() {
        guard let engine = hapticEngine else { return }

        var events: [CHHapticEvent] = []

        // Initial explosion - strong sharp burst
        events.append(CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
            ],
            relativeTime: 0
        ))

        // Sparkle bursts - rapid taps that scatter and decay
        let sparkleCount = 14
        for i in 0..<sparkleCount {
            let time = 0.06 + Double(i) * 0.045
            let decay = 1.0 - (Double(i) / Double(sparkleCount))
            let intensity = Float(0.3 + decay * 0.7) * Float.random(in: 0.6...1.0)
            let sharpness = Float(0.4 + decay * 0.5) * Float.random(in: 0.5...1.0)

            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: time
            ))
        }

        // Final soft rumble tail
        events.append(CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.25),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
            ],
            relativeTime: 0.7,
            duration: 0.3
        ))

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {}
    }
}
