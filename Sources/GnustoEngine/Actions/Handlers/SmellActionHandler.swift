import Foundation

/// Handles the "SMELL" command, providing a generic response when the player attempts
/// to smell their surroundings or a specific item.
///
/// By default, smelling the environment or a generic item doesn't reveal anything specific.
/// Game developers can provide more detailed smell descriptions for particular items or
/// locations by implementing custom `ItemEventHandler` or `LocationEventHandler` logic.
public struct SmellActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.verb, .directObject),
    ]

    public let verbs: [VerbID] = [.smell, .sniff]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods
    public init() {}
    /// Validates the "SMELL" command.
    ///
    /// If a direct object is specified (e.g., "SMELL SWORD"), this method ensures that
    /// the direct object refers to an item. Smelling non-item entities is not permitted
    /// by this default handler.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: `ActionResponse.prerequisiteNotMet` if the direct object is not an item.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {

        // If a direct object is provided, it should be an item.
        guard
            let directObjectRef = command.directObject,
            case .item(let itemID) = directObjectRef
        else { return }

        guard await engine.playerCanReach(itemID) else {
            throw ActionResponse.itemNotAccessible(itemID)
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
        let message: String
        if let directObjectRef = command.directObject {
            switch directObjectRef {
            case .item(let itemID):
                let item = try await engine.item(itemID)
                message = engine.messenger.smellsAverage(item: item.withDefiniteArticle)
            case .location(let locationID):
                _ = try await engine.location(locationID)
                message = engine.messenger.smellNothingUnusual()
            case .player:
                message = engine.messenger.smellMyself()
            }
        } else {
            message = engine.messenger.smellNothingUnusual()
        }

        return ActionResult(message)
    }
}
