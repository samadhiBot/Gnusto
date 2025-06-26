import Foundation

/// Handles the "BURN" command.
///
/// The BURN verb allows players to attempt to set fire to objects.
/// This handler checks if the target object is flammable and provides
/// appropriate responses. Most objects cannot be burned, but some specific
/// items (like paper, wood, etc.) may have special burn behavior.
public struct BurnActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .with, .indirectObject),
    ]

    public let verbs: [Verb] = [.burn, .ignite, .light]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "BURN" command.
    ///
    /// This action validates prerequisites and attempts to burn the specified item.
    /// Checks if the item is flammable and provides appropriate responses.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.thatsNotSomethingYouCan(.burn)
            )
        }

        // Check if the item exists and is accessible
        let targetItem = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // If an indirect object is specified, validate it as a tool for burning
        if let indirectObjectRef = command.indirectObject {
            guard case .item(let toolItemID) = indirectObjectRef else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.cannotActWithThat(verb: "burn")
                )
            }

            let toolItem = try await engine.item(toolItemID)
            guard toolItem.parent == .player else {
                throw ActionResponse.itemNotHeld(toolItemID)
            }
        }

        // Check if the item is flammable
        if targetItem.hasFlag(.isFlammable) {
            return ActionResult(
                engine.messenger.itemBurnsToAshes(
                    item: targetItem.withDefiniteArticle
                ),
                await engine.setFlag(.isTouched, on: targetItem),
                await engine.updatePronouns(to: targetItem),
                await engine.move(targetItem, to: .nowhere)
            )
        } else {
            // Most items cannot be burned
            return ActionResult(
                engine.messenger.burnCannotBurn(item: targetItem.withDefiniteArticle),
                await engine.setFlag(.isTouched, on: targetItem),
                await engine.updatePronouns(to: targetItem)
            )
        }
    }
}
