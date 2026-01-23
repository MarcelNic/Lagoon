import SwiftUI
import UIKit

/// Slide to action button with liquid glass effect
struct SlideToConfirm: View {
    let label: String
    let icon: String
    let action: () -> Void

    @State private var offset: CGFloat = 0
    @State private var lastHapticStep: Int = 0
    @State private var hasReachedThreshold: Bool = false
    @State private var isDragging: Bool = false

    private let knobSize: CGFloat = 72
    private let trackHeight: CGFloat = 88
    private let padding: CGFloat = 8
    private let commitThreshold: CGFloat = 0.85

    // Haptic feedback generators
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()

    var body: some View {
        GeometryReader { geo in
            let maxOffset = geo.size.width - knobSize - (padding * 2)
            let progress = min(1, max(0, offset / maxOffset))

            ZStack(alignment: .leading) {
                // Track (Liquid Glass Clear)
                Color.clear
                    .glassEffect(.clear, in: .capsule(style: .continuous))

                // Dots across the track
                HStack(spacing: 16) {
                    ForEach(0..<8, id: \.self) { _ in
                        Circle()
                            .fill(.secondary.opacity(0.3))
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
                                if !isDragging {
                                    lightImpact.impactOccurred(intensity: 0.5)
                                    isDragging = true
                                }

                                let newOffset = min(maxOffset, max(0, value.translation.width))
                                offset = newOffset

                                let currentProgress = newOffset / maxOffset
                                let currentStep = Int(currentProgress * 10)

                                if currentStep != lastHapticStep {
                                    selectionGenerator.selectionChanged()
                                    if currentStep >= 3 && currentStep <= 7 {
                                        lightImpact.impactOccurred(intensity: 0.7)
                                    }
                                    lastHapticStep = currentStep
                                }

                                if currentProgress >= commitThreshold && !hasReachedThreshold {
                                    selectionGenerator.selectionChanged()
                                    hasReachedThreshold = true
                                } else if currentProgress < commitThreshold {
                                    hasReachedThreshold = false
                                }
                            }
                            .onEnded { _ in
                                let currentProgress = offset / maxOffset

                                if currentProgress >= commitThreshold {
                                    notificationGenerator.notificationOccurred(.success)
                                    action()
                                } else {
                                    rigidImpact.impactOccurred(intensity: 0.6)
                                }

                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    offset = 0
                                }
                                lastHapticStep = 0
                                hasReachedThreshold = false
                                isDragging = false
                            }
                    )
            }
        }
        .frame(height: trackHeight)
        .containerShape(.capsule)
        .onAppear {
            lightImpact.prepare()
            rigidImpact.prepare()
            selectionGenerator.prepare()
            notificationGenerator.prepare()
        }
    }
}
