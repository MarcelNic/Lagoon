import SwiftUI

struct OnboardingStartView: View {
    @State var currentIndex = 0
    @State private var previousIndex = 0
    @State private var isTransitioning = false
    @Environment(NotificationManager.self) private var notificationManager
    var onComplete: () -> Void
    let totalViews = 7

    private var isMovingForward: Bool {
        currentIndex >= previousIndex
    }

    private func goToNext() {
        guard !isTransitioning else { return }
        isTransitioning = true
        previousIndex = currentIndex
        currentIndex += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            isTransitioning = false
        }
    }

    private func goBack() {
        guard !isTransitioning, currentIndex > 0 else { return }
        isTransitioning = true
        previousIndex = currentIndex
        currentIndex -= 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            isTransitioning = false
        }
    }

    var body: some View {
        ZStack {
            VStack {
                Group {
                    switch currentIndex {
                    case 0: FirstScreen(action: goToNext)
                    case 1: ChemistryExplanationScreen(action: goToNext)
                    case 2: PoolProfileScreen(action: goToNext)
                    case 3: GoalsUnitsScreen(action: goToNext)
                    case 4: LocationWeatherScreen(action: goToNext)
                    case 5: NotificationScreen(action: goToNext)
                    case 6: CareTaskSelectionScreen(action: { onComplete() })
                    default: EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .offset(x: isMovingForward ? 60 : -60).combined(with: .opacity),
                    removal: .offset(x: isMovingForward ? -60 : 60).combined(with: .opacity)
                ))
                .allowsHitTesting(!isTransitioning)
            }
            .animation(.spring(duration: 0.5, bounce: 0.0, blendDuration: 0.3), value: currentIndex)
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        let horizontalAmount = value.translation.width
                        let verticalAmount = abs(value.translation.height)

                        // Only trigger if horizontal swipe is dominant
                        if horizontalAmount > 50 && horizontalAmount > verticalAmount && currentIndex > 0 {
                            goBack()
                        }
                    }
            )
            .overlay(alignment: .top) {
                if currentIndex > 0 {
                    let shiftedIndex = Binding<Int>(
                        get: { max(0, currentIndex - 1) },
                        set: { newValue in
                            currentIndex = newValue + 1
                        }
                    )
                    OnboardingProgressView(steps: totalViews - 1, currentStep: shiftedIndex)
                        .padding(.horizontal, 80)
                        .offset(y: 20)
                }
            }

        }
    }
}

#Preview {
    OnboardingStartView(onComplete: {})
        .environment(NotificationManager())
}
