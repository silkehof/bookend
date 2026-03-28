import SwiftUI

@main
struct JournalingPrompterApp: App {
    let coreDataManager = CoreDataManager.shared
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var streakManager = StreakManager()
    @StateObject private var customPromptsManager = CustomPromptsManager()
    @StateObject private var calendarService = CalendarService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataManager.viewContext)
                .environmentObject(notificationManager)
                .environmentObject(streakManager)
                .environmentObject(customPromptsManager)
                .environmentObject(calendarService)
        }
    }
}
