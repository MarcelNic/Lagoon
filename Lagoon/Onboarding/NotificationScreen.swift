import SwiftUI

struct NotificationScreen: View {
    var action: () -> Void

    @Environment(NotificationManager.self) private var notificationManager

    @AppStorage("reminderHour") private var reminderHour: Int = 9
    @AppStorage("reminderMinute") private var reminderMinute: Int = 0

    @State private var reminderTime = Date()
    @State private var permissionRequested = false

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.yellow, .orange)
                    .microAnimation(delay: 0.2)

                Text("Erinnerungen")
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                    .microAnimation(delay: 0.3)

                Text("Wann möchtest du erinnert werden?")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .microAnimation(delay: 0.5)
            }
            .padding(.horizontal, 30)

            Spacer()

            // Time Picker
            DatePicker(
                "",
                selection: $reminderTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(height: 150)
            .microAnimation(delay: 0.6)

            Spacer()

            // Permission status
            if permissionRequested && notificationManager.isAuthorized {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Benachrichtigungen aktiviert")
                        .fontWeight(.medium)
                }
                .padding()
                .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                .transition(.scale.combined(with: .opacity))
                .padding(.horizontal, 30)
            }

            Spacer()

            VStack(spacing: 12) {
                Button("Überspringen") {
                    action()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .microAnimation(delay: 0.9)

                PrimaryButton(title: "Erlauben") {
                    saveReminderTime()
                    Task {
                        await notificationManager.requestPermission()
                        permissionRequested = true
                        action()
                    }
                }
                .microAnimation(delay: 1.0)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            // Initialize time picker from stored values
            var components = DateComponents()
            components.hour = reminderHour
            components.minute = reminderMinute
            if let date = Calendar.current.date(from: components) {
                reminderTime = date
            }
        }
    }

    private func saveReminderTime() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        reminderHour = components.hour ?? 9
        reminderMinute = components.minute ?? 0
        notificationManager.scheduleDailyReminder(hour: reminderHour, minute: reminderMinute)
    }
}

#Preview {
    NotificationScreen(action: {})
        .environment(NotificationManager())
}
