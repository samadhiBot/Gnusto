import Foundation

/// Handles the "TELL" command for telling characters about topics.
/// Implements communication mechanics following ZIL patterns for character interaction.
public struct TellActionHandler: ActionHandler {
    public init() {}

    /// Validates the "TELL" command.
    ///
    /// This method ensures that:
    /// 1. Both direct and indirect objects are specified (who to tell and what to tell about).
    /// 2. The direct object (who to tell) is a character.
    /// 3. The character is present and reachable.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // TELL requires both direct object (who) and indirect object (what about)
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Tell whom?")
        }
        guard context.command.indirectObject != nil else {
            throw ActionResponse.prerequisiteNotMet("Tell about what?")
        }

        guard case .item(let characterID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only tell characters about things.")
        }

        // Check if character exists and is reachable
        let character = try await context.engine.item(characterID)
        guard character.hasFlag(.isCharacter) else {
            throw ActionResponse.prerequisiteNotMet("You can't tell the \(character.name) about anything.")
        }

        guard await context.engine.playerCanReach(characterID) else {
            throw ActionResponse.itemNotAccessible(characterID)
        }
    }

    /// Processes the "TELL" command.
    ///
    /// Handles telling characters about topics. By default, most characters
    /// don't have specific responses, but game-specific ItemEventHandlers
    /// can provide custom dialogue.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate dialogue response and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
              case .item(let characterID) = directObjectRef,
              let indirectObjectRef = context.command.indirectObject else {
            throw ActionResponse.internalEngineError("TellActionHandler: missing required objects in process.")
        }

        let character = try await context.engine.item(characterID)
        var stateChanges: [StateChange] = []

        // Mark character as touched (interacted with)
        if let touchedChange = await context.engine.setFlag(.isTouched, on: character) {
            stateChanges.append(touchedChange)
        }

        // Update pronouns to refer to the character
        if let pronounChange = await context.engine.updatePronouns(to: character) {
            stateChanges.append(pronounChange)
        }

        // Determine what's being told about
        let topicDescription: String
        switch indirectObjectRef {
        case .item(let topicItemID):
            let topicItem = try await context.engine.item(topicItemID)
            topicDescription = topicItem.name
        case .player:
            topicDescription = "yourself"
        case .location(let locationID):
            let location = try await context.engine.location(locationID)
            topicDescription = location.name
        }

        // Default response - games can override with ItemEventHandlers
        let message = "\(character.name.capitalizedFirst) listens politely to what you say about \(topicDescription)."

        return ActionResult(
            message: message,
            stateChanges: stateChanges
        )
    }

    /// Performs any post-processing after the tell action completes.
    ///
    /// Currently no post-processing is needed for basic telling.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext) async throws {
        // No post-processing needed for tell
    }
}
