import Foundation

/// Handles the "PUT <direct object> ON <indirect object>" command, allowing the player
/// to place an item they are holding onto a surface item.
public struct PutOnActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject, .on, .indirectObject)
    ]

    public let verbs: [Verb] = [.put, .place, .set, .balance, .hang]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "PUT ... ON" command.
    ///
    /// This action validates prerequisites and handles placing items onto surfaces.
    /// Checks that both objects exist, the item is held, and the surface is accessible.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Validate direct object (item to put)
        guard let directObjectRef = command.directObject else {
            if let indirectObjectRef = command.indirectObject,
                case .item(let surfaceID) = indirectObjectRef
            {
                let surfaceItem = try await engine.item(surfaceID)
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.putWhatOn(item: surfaceItem.withDefiniteArticle)
                )
            } else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.doWhat(verb: command.verb)
                )
            }
        }

        let itemToPutID: ItemID
        switch directObjectRef {
        case .item(let itemID):
            itemToPutID = itemID
        case .location:
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.thatsNotSomethingYouCanPutOnThings()
            )
        case .player:
            throw ActionResponse.prerequisiteNotMet(
                "🤡 You can't put yourself on that."
            )
        }

        // Validate indirect object (surface)
        guard let indirectObjectRef = command.indirectObject else {
            let itemToPut = try await engine.item(itemToPutID)
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.putOnWhat(
                    item: itemToPut.withDefiniteArticle
                )
            )
        }
        guard case .item(let surfaceID) = indirectObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.thatsNotSomethingYouCan(.wear)
            )
        }

        // Get items and validate existence
        let itemToPut = try await engine.item(itemToPutID)
        let surfaceItem = try await engine.item(surfaceID)

        // Check if player is holding the item
        guard await engine.playerIsHolding(itemToPutID) else {
            throw ActionResponse.itemNotHeld(itemToPutID)
        }

        // Check if surface is accessible
        guard await engine.playerCanReach(surfaceID) else {
            throw ActionResponse.itemNotAccessible(surfaceID)
        }

        // Prevent putting item onto itself
        if itemToPutID == surfaceID {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.putCannotPutOnSelf()
            )
        }

        // Recursive check: is the target surface inside the item we are putting?
        var currentParent = surfaceItem.parent
        while case .item(let parentItemID) = currentParent {
            if parentItemID == itemToPutID {
                let preposition =
                    if itemToPut.hasFlag(.isContainer) {
                        "inside"
                    } else if itemToPut.hasFlag(.isSurface) {
                        "on"
                    } else {
                        "in"
                    }
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.putCannotPutCircular(
                        item: itemToPut.withDefiniteArticle,
                        container: surfaceItem.withDefiniteArticle,
                        preposition: preposition
                    )
                )
            }
            let parentItem = try await engine.item(parentItemID)
            currentParent = parentItem.parent
        }

        // Check if target is actually a surface
        guard surfaceItem.hasFlag(.isSurface) else {
            throw ActionResponse.targetIsNotASurface(surfaceID)
        }

        // Perform the action
        return ActionResult(
            engine.messenger.youPutItemOnSurface(
                item: itemToPut.withDefiniteArticle,
                surface: surfaceItem.withDefiniteArticle
            ),
            await engine.move(itemToPut, to: .item(surfaceItem.id)),
            await engine.setFlag(.isTouched, on: itemToPut),
            await engine.setFlag(.isTouched, on: surfaceItem),
            await engine.updatePronouns(to: itemToPut)
        )
    }
}
