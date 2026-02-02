import SwiftUI

struct OnboardingView: View {
    var buttonTitle: String = "Continue"
    var icon: String
    var title: String
    var subtitle: String
    var action: () -> Void
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 61)).foregroundColor(.blue)
                .microAnimation(delay: 0.0)
            Text(title)
                .font(.title).bold().padding(.top)
                .microAnimation(delay: 0.5)
            Text(subtitle)
                .microAnimation(delay: 0.8)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 70)
        .overlay(alignment: .bottom) {
            PrimaryButton(title: buttonTitle, action: { action() })
                .padding(.horizontal, 30).padding(.bottom, 40)
                .microAnimation(delay: 1.0)
        }
    }
}
