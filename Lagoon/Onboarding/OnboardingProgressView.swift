import SwiftUI

struct OnboardingProgressView: View {
    var steps: Int
    @Binding var currentStep: Int
    @State private var hasAppeared = false
    var body: some View {
        HStack {
            ForEach(0..<steps, id: \.self) { item in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .frame(width: geo.size.width, height: 5)
                            .foregroundStyle(.gray.opacity(0.3))
                        Capsule()
                            .frame(
                                width: (item == 0 && !hasAppeared) ? 0 :
                                       (currentStep >= item ? geo.size.width : 0),
                                height: 5
                            )
                            .onAppear {
                                if item == 0 {
                                    withAnimation(.easeInOut) { hasAppeared = true }
                                }
                            }.animation(.easeInOut, value: currentStep)
                    }
                }
            }
        }.frame(height: 6)
    }
}

#Preview {
    OnboardingProgressView(steps: 5, currentStep: .constant(0))
}
