import SwiftUI

struct OnboardingStartView: View {
    @State var currentIndex = 0
    @State var navigateToHome = false
    @Environment(NotificationManager.self) private var notificationManager
    var onComplete: () -> Void
    let totalViews = 7

    var body: some View {
        ZStack {
            VStack {
                Group {
                    switch currentIndex {
                    case 0: FirstScreen(action: { currentIndex += 1 })
                    case 1: ChemistryExplanationScreen(action: { currentIndex += 1 })
                    case 2: PoolProfileScreen(action: { currentIndex += 1 })
                    case 3: LocationWeatherScreen(action: { currentIndex += 1 })
                    case 4: GoalsUnitsScreen(action: { currentIndex += 1 })
                    case 5: NotificationScreen(action: { currentIndex += 1 })
                    case 6: CareTaskSelectionScreen(action: { onComplete() })
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
                if currentIndex > 0 && currentIndex < totalViews {
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
