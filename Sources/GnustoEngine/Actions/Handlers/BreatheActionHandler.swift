import Foundation

/// Handles the "BREATHE" command, an atmospheric command that provides varied responses.
/// In ZIL traditions, this is a simple command that doesn't require objects.
public struct BreatheActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.verb, .on, .directObject),
    ]

    public let verbs: [Verb] = [.breathe]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "BREATHE" command.
    ///
    /// This action provides atmospheric responses to breathing. Can be used without objects
    /// for general breathing, or with objects for breathing on specific items.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        if let directObjectRef = command.directObject {
            // Breathing on something
            guard case .item(let targetItemID) = directObjectRef else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.cannotDoThat(verb: "breathe")
                )
            }

            let targetItem = try await engine.item(targetItemID)
            guard await engine.playerCanReach(targetItemID) else {
                throw ActionResponse.itemNotAccessible(targetItemID)
            }

            return ActionResult(
                engine.messenger.breatheOnResponse(
                    item: targetItem.withDefiniteArticle
                ),
                await engine.setFlag(.isTouched, on: targetItem),
                await engine.updatePronouns(to: targetItem)
            )
        } else {
            // General breathing
            return ActionResult(
                engine.messenger.breatheResponse()
            )
        }
    }
}
