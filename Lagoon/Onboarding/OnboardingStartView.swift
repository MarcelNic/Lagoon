import SwiftUI

struct OnboardingStartView: View {
    @State var currentIndex = 0
    @State var navigateToHome = false
    @State var showDashboardOverlay = false
    @Environment(NotificationManager.self) private var notificationManager
    var onComplete: () -> Void
    let totalViews = 8

    var body: some View {
        ZStack {
            VStack {
                Group {
                    switch currentIndex {
                    case 0: FirstScreen(action: { currentIndex += 1 })
                    case 1: ChemistryExplanationScreen(action: { currentIndex += 1 })
                    case 2: PoolProfileScreen(action: { currentIndex += 1 })
                    case 3: LocationWeatherScreen(action: { currentIndex += 1 })
                    case 4: NotificationScreen(action: { currentIndex += 1 })
                    case 5: GoalsUnitsScreen(action: { currentIndex += 1 })
                    case 6: CareTaskSelectionScreen(action: { showDashboardOverlay = true })
                    default: EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
            .animation(.linear(duration: 0.3), value: currentIndex)
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
