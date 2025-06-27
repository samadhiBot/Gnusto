import Foundation

/// Handles the "CHOMP" command for biting, gnawing, or chewing actions.
///
/// This handler manages bite actions with intelligent disambiguation for edible items.
/// When the player chomps on something edible, it asks whether they want to eat it completely
/// or just take a bite. Based on ZIL tradition of atmospheric commands with modern conversation system.
public struct ChompActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb),
    ]

    public let verbs: [Verb] = [.chomp, .bite, .chew]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "CHOMP" command.
    ///
    /// This action provides responses to player attempts to bite or chew things.
    /// For edible items, it asks for disambiguation between eating completely or just taking a bite.
    /// Can be used with or without a target object.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        if let directObjectRef = command.directObject {
            // Chomping on something
            guard case .item(let targetItemID) = directObjectRef else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.thatsNotSomethingYouCan(.chomp)
                )
            }

            // Check if item exists and is accessible
            let targetItem = try await engine.item(targetItemID)
            guard await engine.playerCanReach(targetItemID) else {
                throw ActionResponse.itemNotAccessible(targetItemID)
            }

            // Handle edible items with disambiguation
            if targetItem.hasFlag(.isEdible) {
                // Ask whether the player wants to eat it completely or just take a bite
                let question = "Do you mean you want to eat \(targetItem.withDefiniteArticle)?"

                // Create the EAT command to execute if they confirm
                let eatCommand = Command(
                    verb: .eat,
                    directObject: .item(targetItemID),
                    rawInput: "eat \(targetItem.name)"
                )

                return await YesNoQuestionHandler.askToDisambiguate(
                    question: question,
                    clarifiedCommand: eatCommand,
                    originalCommand: command,
                    engine: engine
                )
            }
            // Handle characters with special response
            else if targetItem.hasFlag(.isPerson) || targetItem.hasFlag(.isCharacter) {
                let message = engine.messenger.chompCharacter(
                    targetItem.withDefiniteArticle
                )

                return ActionResult(
                    message,
                    await engine.setFlag(.isTouched, on: targetItem),
                    await engine.updatePronouns(to: targetItem)
                )
            }
            // Handle regular items with humorous response
            else {
                let message = engine.messenger.chompTargetResponse(
                    item: targetItem.withDefiniteArticle
                )

                return ActionResult(
                    message,
                    await engine.setFlag(.isTouched, on: targetItem),
                    await engine.updatePronouns(to: targetItem)
                )
            }
        } else {
            // General chomping (no object)
            return ActionResult(
                engine.messenger.chompResponse()
            )
        }
    }
}
