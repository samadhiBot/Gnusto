import Foundation

/// Handles the "PUT <direct object> ON <indirect object>" command, allowing the player
/// to place an item they are holding onto a surface item.
public struct PutOnActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .on, .indirectObject),
    ]

    public let synonyms: [Verb] = [.put, .place, .set, .balance, .hang]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "PUT ... ON" command.
    ///
    /// This action validates prerequisites and handles placing items onto surfaces.
    /// Checks that both objects exist, the item is held, and the surface is accessible.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Get direct object (item to put)
        guard let itemToPut = try await context.itemDirectObject(
            locationMessage: { await context.msg.putItemOn($0.withDefiniteArticle) },
            universalMessage: { context.msg.putItemOn($0.withDefiniteArticle) },
            playerMessage: context.msg.putMeOn()
        ) else {
            throw ActionResponse.doWhat(context)
        }

        // Get indirect object (surface)
        guard let surfaceItem = try await context.itemIndirectObject(
            failureMessage: context.msg.putOnBadTarget(itemToPut.withDefiniteArticle)
        ) else {
            throw ActionResponse.feedback(
                await context.msg.putOnWhat(
                    itemToPut.withDefiniteArticle
                )
            )
        }

        // Check if player is holding the item
        guard try await itemToPut.playerIsHolding else {
            throw ActionResponse.itemNotHeld(itemToPut)
        }

        // Prevent putting item onto itself
        if itemToPut.id == surfaceItem.id {
            throw await ActionResponse.feedback(
                context.msg.putCannotPutOnSelf(itemToPut.withDefiniteArticle)
            )
        }

        // Recursive check: is the target surface inside the item we are putting?
        var currentParent = try await surfaceItem.parent
        while case .item(let parentItem) = currentParent {
            if parentItem == itemToPut {
                throw ActionResponse.feedback(
                    await context.msg.putItemOnCircular(
                        itemToPut.withDefiniteArticle,
                        container: surfaceItem.withDefiniteArticle
                    )
                )
            }
            currentParent = try await parentItem.parent
        }

        // Check if target is actually a surface
        guard await surfaceItem.hasFlag(.isSurface) else {
            throw ActionResponse.feedback(
                await context.msg.putItemOnNonSurface(
                    itemToPut.withDefiniteArticle,
                    container: surfaceItem.withDefiniteArticle
                )
            )
        }

        // Perform the action
        return try await ActionResult(
            context.msg.youPutItemOnSurface(
                context.verb,
                item: itemToPut.withDefiniteArticle,
                surface: surfaceItem.withDefiniteArticle
            ),
            itemToPut.move(to: .item(surfaceItem.id)),
            itemToPut.setFlag(.isTouched),
            surfaceItem.setFlag(.isTouched)
        )
    }
}
