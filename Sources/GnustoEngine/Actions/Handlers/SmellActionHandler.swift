import Foundation

/// Handles the "SMELL" command, providing a generic response when the player attempts
/// to smell their surroundings or a specific item.
///
/// By default, smelling the environment or a generic item doesn't reveal anything specific.
/// Game developers can provide more detailed smell descriptions for particular items or
/// locations by implementing custom `ItemEventHandler` or `LocationEventHandler` logic.
struct SmellActionHandler: ActionHandler {
    /// Validates the "SMELL" command.
    ///
    /// If a direct object is specified (e.g., "SMELL SWORD"), this method ensures that
    /// the direct object refers to an item. Smelling non-item entities is not permitted
    /// by this default handler.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: `ActionResponse.prerequisiteNotMet` if the direct object is not an item.
    func validate(context: ActionContext) async throws {
        // If a direct object is provided, it should be an item.
        if let directObjectRef = context.command.directObject {
            guard case .item(_) = directObjectRef else {
                throw ActionResponse.prerequisiteNotMet("You can only smell items directly.")
            }
            // Further validation (existence, reachability) could be added if desired,
            // but default SMELL is often lenient.
        }
    }

    /// Processes the "SMELL" command.
    ///
    /// - If a direct object (which must be an item, due to `validate`) is specified,
    ///   a generic response like "That smells about average." is returned.
    /// - If no direct object is specified (i.e., smelling the ambient environment),
    ///   a message like "You smell nothing unusual." is returned.
    ///
    /// Specific olfactory details for items or locations should be implemented via
    /// more targeted handlers.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with a default smell-related message.
    func process(context: ActionContext) async throws -> ActionResult {
        if let directObjectRef = context.command.directObject {
            // Validate should have ensured this is an .item if directObjectRef is not nil.
            // We don't need the itemID itself for the generic response.
            guard case .item(_) = directObjectRef else {
                // This case should ideally be caught by validate.
                return ActionResult("You can't smell that.")
            }
            // If smelling a specific item, give a generic response.
            // Specific items could be handled by ItemEventHandler or custom handlers.
            return ActionResult("That smells about average.")
        } else {
            return ActionResult("You smell nothing unusual.")
        }
    }
}
