import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var calendarService: CalendarService
    @AppStorage("geminiAPIKey") private var apiKey = ""

    @State private var showingAPIKeyAlert = false
    @State private var tempAPIKey = ""

    var body: some View {
        NavigationStack {
            Form {
                apiKeySection
                notificationSection
                calendarSection
                aboutSection
            }
            .navigationTitle("Settings")
        }
    }

    private var apiKeySection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gemini API Key")
                        .font(.subheadline)

                    if apiKey.isEmpty {
                        Text("Not configured (using offline prompts)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else {
                        Text("Configured")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }

                Spacer()

                Button(apiKey.isEmpty ? "Add" : "Update") {
                    tempAPIKey = apiKey
                    showingAPIKeyAlert = true
                }
                .buttonStyle(.bordered)
            }
        } header: {
            Text("AI Configuration")
        } footer: {
            Text("Optional. Without an API key, the app uses built-in prompts.")
        }
        .alert("Gemini API Key", isPresented: $showingAPIKeyAlert) {
            SecureField("Enter your API key", text: $tempAPIKey)
            Button("Cancel", role: .cancel) {
                tempAPIKey = ""
            }
            Button("Save") {
                apiKey = tempAPIKey
                tempAPIKey = ""
            }
        } message: {
            Text("Enter your Gemini API key from Google AI Studio.")
        }
    }

    private var notificationSection: some View {
        Section {
            if notificationManager.isAuthorized {
                DatePicker(
                    "Reminder Time",
                    selection: $notificationManager.reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .onChange(of: notificationManager.reminderTime) { _, newValue in
                    Task {
                        await notificationManager.updateReminderTime(newValue)
                    }
                }

                Button("Disable Reminders", role: .destructive) {
                    notificationManager.cancelReminder()
                }
            } else {
                Button("Enable Daily Reminders") {
                    Task {
                        await notificationManager.requestAuthorization()
                    }
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            if notificationManager.isAuthorized {
                Text("You'll receive a reminder to journal at this time every day.")
            } else {
                Text("Enable notifications to receive daily reminders to journal.")
            }
        }
    }

    private var calendarSection: some View {
        Section {
            Toggle("Show events in morning view", isOn: $calendarService.calendarEnabled)

            if calendarService.calendarEnabled {
                if calendarService.authorizationStatus == .fullAccess {
                    ForEach(calendarService.availableCalendars, id: \.calendarIdentifier) { cal in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color(cgColor: cal.cgColor))
                                .frame(width: 10, height: 10)
                            Toggle(cal.title, isOn: Binding(
                                get: { calendarService.isCalendarSelected(cal) },
                                set: { _ in calendarService.toggleCalendar(cal) }
                            ))
                        }
                    }
                } else {
                    Button("Grant Calendar Access") {
                        Task { await calendarService.requestAccess() }
                    }
                }
            }
        } header: {
            Text("Calendar")
        } footer: {
            Text("Selected calendars will be shown in your morning view.")
        }
        .onAppear {
            if calendarService.authorizationStatus == .fullAccess {
                calendarService.loadAvailableCalendars()
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }

            Link(destination: URL(string: "https://makersuite.google.com/app/apikey")!) {
                HStack {
                    Text("Get Gemini API Key")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(NotificationManager())
        .environmentObject(CalendarService.shared)
}
