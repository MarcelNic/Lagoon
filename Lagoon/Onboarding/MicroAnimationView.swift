import SwiftUI

struct MicroAnimationView: View {
    var body: some View {
        Text("Build a Life Around What You Love")
            .font(.system(size: 40))
            .bold()
            .multilineTextAlignment(.center)
            .microAnimation(delay: 1.0, direction: .Bottom)
    }
}

#Preview {
    MicroAnimationView()
}

enum SlideDirection {
    case Top, Bottom, Left, Right
}

struct MicroAnimationModifier: ViewModifier {
    let delay: Double
    let direction: SlideDirection
    let offsetAmount: CGFloat
    @State var isVisible = false

    private var initialOffset: CGSize {
        switch direction {
        case .Top:
            return CGSize(width: 0, height: -offsetAmount)
        case .Bottom:
            return CGSize(width: 0, height: offsetAmount)
        case .Left:
            return CGSize(width: -offsetAmount, height: 0)
        case .Right:
            return CGSize(width: offsetAmount, height: 0)
        }
    }

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(isVisible ? .zero : initialOffset)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        isVisible = true
                    }
                }
            }
    }
}

extension View {
    func microAnimation(
        delay: Double = 0,
        direction: SlideDirection = .Bottom,
        offset: CGFloat = 40
    ) -> some View {
        self.modifier(MicroAnimationModifier(
            delay: delay,
            direction: direction,
            offsetAmount: offset
        ))
    }
}
