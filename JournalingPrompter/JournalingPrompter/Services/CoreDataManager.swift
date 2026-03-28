import CoreData
import Foundation

class CoreDataManager {
    static let shared = CoreDataManager()

    let persistentContainer: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    private init() {
        persistentContainer = NSPersistentContainer(name: "JournalingPrompter")

        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data: \(error)")
            }
        }

        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func save() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }

    func createJournalEntry(
        prompt: String,
        content: String,
        mood: String,
        activities: [String]
    ) -> JournalEntry {
        let entry = JournalEntry(context: viewContext)
        entry.id = UUID()
        entry.date = Date()
        entry.prompt = prompt
        entry.content = content
        entry.mood = mood
        entry.activities = activities.joined(separator: ",")
        save()
        return entry
    }

    func fetchAllEntries() -> [JournalEntry] {
        let request: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntry.date, ascending: false)]

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch entries: \(error)")
            return []
        }
    }

    func deleteEntry(_ entry: JournalEntry) {
        viewContext.delete(entry)
        save()
    }
}
