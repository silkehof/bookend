import SwiftUI

struct OnboardingView: View {
    @AppStorage("userName") private var userName = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var nameInput = ""
    @FocusState private var isNameFocused: Bool
    @State private var step = 0

    @StateObject private var calendarService = CalendarService.shared

    var body: some View {
        if step == 0 {
            nameStep
        } else {
            calendarStep
        }
    }

    // MARK: - Step 0: Name

    private var nameStep: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.warmAccent)

                Text("Welcome to Bookend")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Your space for daily reflection.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Text("What should we call you?")
                    .font(.headline)

                TextField("Your name", text: $nameInput)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.warmCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .focused($isNameFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        saveName()
                    }
            }
            .padding(.horizontal, 40)

            Spacer()

            Button {
                saveName()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.warmGradientStart, .warmGradientEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(nameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(nameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .onAppear {
            isNameFocused = true
        }
    }

    // MARK: - Step 1: Calendar Opt-in

    private var calendarStep: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "calendar")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.warmAccent)

                Text("See your day at a glance")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Bookend can show your calendar events in the morning view to help you set intentions and priorities.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            if calendarService.authorizationStatus == .fullAccess && !calendarService.availableCalendars.isEmpty {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(calendarService.availableCalendars, id: \.calendarIdentifier) { cal in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color(cgColor: cal.cgColor))
                                    .frame(width: 12, height: 12)
                                Text(cal.title)
                                    .font(.subheadline)
                                Spacer()
                                Image(systemName: calendarService.isCalendarSelected(cal) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(calendarService.isCalendarSelected(cal) ? Color.warmAccent : Color.secondary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                calendarService.toggleCalendar(cal)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.warmCardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 240)
            }

            Spacer()

            VStack(spacing: 12) {
                if calendarService.authorizationStatus != .fullAccess {
                    Button {
                        Task {
                            await calendarService.requestAccess()
                        }
                    } label: {
                        Text("Allow Calendar Access")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.warmGradientStart, .warmGradientEnd],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                } else {
                    Button {
                        completeOnboarding()
                    } label: {
                        Text("Done")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.warmGradientStart, .warmGradientEnd],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                }

                Button("Skip for now") {
                    completeOnboarding()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Helpers

    private func saveName() {
        let trimmedName = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        userName = trimmedName
        withAnimation {
            step = 1
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}

#Preview {
    OnboardingView()
}
