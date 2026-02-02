import SwiftUI

struct OnboardingStartView: View {
    @State var currentIndex = 0
    @State var navigateToHome = false
    var onComplete: () -> Void
    let totalViews = 4

    var body: some View {
        ZStack {
            VStack {
                Group {
                    switch currentIndex {
                    case 0: FirstScreen(action: { currentIndex += 1 })
                    case 1: SelectionView(action: { currentIndex += 1 })
                    case 2: OnboardingView(icon: "lightbulb.fill", title: "Boost your creativity", subtitle: "Stay calm and mindful while exploring habits", action: { currentIndex += 1 })
                    case 3: OnboardingView(icon: "trophy.fill", title: "Boost your creativity", subtitle: "Build lasting routines", action: { currentIndex += 1 })
                    case 4: OnboardingView(buttonTitle: "Get started", icon: "trophy.fill", title: "Boost your creativity", subtitle: "Build lasting routines", action: { onComplete() })
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
                if currentIndex > 0 && currentIndex <= totalViews {
                    let shiftedIndex = Binding<Int>(
                        get: { max(0, currentIndex - 1) },
                        set: { newValue in
                            currentIndex = newValue + 1
                        }
                    )
                    OnboardingProgressView(steps: totalViews, currentStep: shiftedIndex)
                        .padding(.horizontal, 80)
                        .offset(y: 20)
                }
            }
        }
    }
}

#Preview {
    OnboardingStartView(onComplete: {})
}
