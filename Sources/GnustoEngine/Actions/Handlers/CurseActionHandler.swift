import Foundation

/// Handles the CURSE verb for swearing, cursing, or expressing frustration.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to curse or swear. Based on ZIL tradition.
public struct CurseActionHandler: ActionHandler {
    public init() {}

    public func validate(
        context: ActionContext
    ) async throws {
        // If there's a direct object, validate it exists and is reachable
        guard let directObjectRef = context.command.directObject else {
            return // General cursing is always valid
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only curse at items.")
        }

        // Check if item exists
        let _ = try await context.engine.item(targetItemID)

        // Check reachability (you can curse at things you can see)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    public func process(
        context: ActionContext
    ) async throws -> ActionResult {
        // Handle cursing at a specific object
        if let directObjectRef = context.command.directObject,
           case .item(let targetItemID) = directObjectRef {
            let targetItem = try await context.engine.item(targetItemID)

            let responses = [
                "You curse \(targetItem.name) roundly. You feel a bit better.",
                "You let loose a string of expletives at \(targetItem.name).",
                "You damn \(targetItem.name) to the seven hells.",
                "You swear colorfully at \(targetItem.name). How therapeutic!",
                "You curse \(targetItem.name) with words that would make a sailor blush."
            ]

            return ActionResult(responses.randomElement()!)
        } else {
            // General cursing
            let responses = [
                "You curse under your breath.",
                "You let out a string of colorful expletives.",
                "You swear like a sailor. Very cathartic.",
                "You curse the fates that brought you here.",
                "You damn everything in sight. You feel better now.",
                "You use language that would make your mother wash your mouth out with soap.",
                "You curse fluently in several languages.",
                "You swear with the passion of a thousand frustrated adventurers."
            ]

            return ActionResult(responses.randomElement()!)
        }
    }
}
