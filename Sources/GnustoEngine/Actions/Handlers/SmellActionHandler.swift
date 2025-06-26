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

    public let verbs: [Verb] = [.smell, .sniff]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "SMELL" command.
    ///
    /// This action provides olfactory responses to smelling. Can be used without objects
    /// for general environmental smelling, or with objects for smelling specific items.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        if let directObjectRef = command.directObject {
            // Smelling something specific
            switch directObjectRef {
            case .item(let itemID):
                let item = try await engine.item(itemID)
                guard await engine.playerCanReach(itemID) else {
                    throw ActionResponse.itemNotAccessible(itemID)
                }

                return ActionResult(
                    engine.messenger.smellsAverage(item: item.withDefiniteArticle),
                    await engine.setFlag(.isTouched, on: item),
                    await engine.updatePronouns(to: item)
                )

            case .location(let locationID):
                _ = try await engine.location(locationID)
                return ActionResult(
                    engine.messenger.smellNothingUnusual()
                )

            case .player:
                return ActionResult(
                    engine.messenger.smellMyself()
                )
            }
        } else {
            // General environmental smelling
            return ActionResult(
                engine.messenger.smellNothingUnusual()
            )
        }
    }
}
