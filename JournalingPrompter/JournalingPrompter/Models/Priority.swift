import CoreData
import Foundation

@objc(Priority)
public class Priority: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var text: String?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var dailyEntry: DailyEntry?
    @NSManaged public var rolledOverFromDate: Date?
}

extension Priority {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Priority> {
        return NSFetchRequest<Priority>(entityName: "Priority")
    }

    public var wasRolledOver: Bool {
        rolledOverFromDate != nil
    }
}
