import SwiftUI

struct OnboardingStartView: View {
    @State var currentIndex = 0
    @State private var previousIndex = 0
    @State var navigateToHome = false
    @State var showDashboardOverlay = false
    @Environment(NotificationManager.self) private var notificationManager
    var onComplete: () -> Void
    let totalViews = 8

    private var isMovingForward: Bool {
        currentIndex >= previousIndex
    }

    private func goToNext() {
        previousIndex = currentIndex
        currentIndex += 1
    }

    private func goBack() {
        if currentIndex > 0 {
            previousIndex = currentIndex
            currentIndex -= 1
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
                    case 3: LocationWeatherScreen(action: goToNext)
                    case 4: NotificationScreen(action: goToNext)
                    case 5: GoalsUnitsScreen(action: goToNext)
                    case 6: CareTaskSelectionScreen(action: { showDashboardOverlay = true })
                    default: EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: isMovingForward ? .trailing : .leading).combined(with: .opacity),
                    removal: .move(edge: isMovingForward ? .leading : .trailing).combined(with: .opacity)
                ))
            }
            .animation(.linear(duration: 0.3), value: currentIndex)
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
                if currentIndex > 0 && currentIndex < totalViews - 1 {
                    let shiftedIndex = Binding<Int>(
                        get: { max(0, currentIndex - 1) },
                        set: { newValue in
                            currentIndex = newValue + 1
                        }
                    )
                    OnboardingProgressView(steps: totalViews - 2, currentStep: shiftedIndex)
                        .padding(.horizontal, 80)
                        .offset(y: 20)
                }
            }

            // Dashboard Overlay (Screen 8)
            if showDashboardOverlay {
                DashboardOverlayScreen(onComplete: {
                    onComplete()
                })
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showDashboardOverlay)
    }
}

#Preview {
    OnboardingStartView(onComplete: {})
        .environment(NotificationManager())
}
