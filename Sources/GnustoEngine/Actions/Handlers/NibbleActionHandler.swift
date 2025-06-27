import Foundation

/// Handles the "NIBBLE" command, which typically means to eat something in small bites.
/// Demonstrates the disambiguation pattern where ambiguous commands trigger yes/no questions
/// to clarify player intent (e.g., "Do you mean you want to eat the apple?").
public struct NibbleActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let verbs: [Verb] = [.nibble, .bite]

    public let actions: [Intent] = [.eat]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "NIBBLE" command.
    ///
    /// Since "nibble" is conceptually similar to "eat" but less common,
    /// this handler asks for confirmation before proceeding with the eating action.
    /// This demonstrates the ZIL pattern of disambiguation through yes/no questions.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        guard let itemID = command.directObjectItemID else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.nibbleWhat()
            )
        }

        let item = try await engine.item(itemID)

        // Check basic prerequisites
        guard await engine.playerCanReach(itemID) else {
            throw ActionResponse.itemNotAccessible(itemID)
        }

        // Check if the item is something that can be eaten
        guard item.hasFlag(.isEdible) else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotEat(item: item.withDefiniteArticle)
            )
        }

        // Create the clarified EAT command
        let eatCommand = Command(
            verb: .eat,
            directObject: command.directObject,
            rawInput: "eat \(item.name)"
        )

        // Ask for confirmation using the disambiguation pattern
        return await YesNoQuestionHandler.askToDisambiguate(
            question: "Do you mean you want to eat \(item.withDefiniteArticle)?",
            clarifiedCommand: eatCommand,
            originalCommand: command,
            engine: engine
        )
    }
}
