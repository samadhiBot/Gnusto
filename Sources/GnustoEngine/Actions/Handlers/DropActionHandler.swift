import Foundation

/// Handles the "DROP" command and its synonyms (e.g., "PUT DOWN"), allowing the player
/// to remove an item from their inventory and place it in the current location.
public struct DropActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObjects)
    ]

    public let synonyms: [Verb] = [.drop, .discard]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "DROP" command.
    ///
    /// This action validates prerequisites and moves the specified item(s) from the player's
    /// inventory to the current location. Handles both single items and ALL commands.
    public func process(context: ActionContext) async throws -> ActionResult {
        let dropItems = try await context.itemDirectObjects()

        guard dropItems.isNotEmpty else {
            if context.command.isAllCommand {
                throw ActionResponse.feedback(
                    context.msg.youAreEmptyHanded()
                )
            } else {
                throw ActionResponse.doWhat(context)
            }
        }

        var allStateChanges = [StateChange]()
        var droppedItems: [ItemProxy] = []

        // Get current location for dropping items
        let currentLocation = await ParentEntity.location(
            context.player.location.id
        )

        for dropItem in dropItems {
            guard await dropItem.playerIsHolding else {
                if context.command.isAllCommand { continue }
                throw ActionResponse.itemNotHeld(dropItem)
            }

            if await dropItem.hasFlag(.omitDescription) {
                if context.command.isAllCommand { continue }
                throw ActionResponse.cannotDo(context, dropItem)
            }

            await allStateChanges.append(
                contentsOf: [
                    dropItem.move(to: currentLocation),
                    dropItem.setFlag(.isTouched),
                    dropItem.clearFlag(.isWorn),
                ].compactMap(\.self)
            )

            droppedItems.append(dropItem)
        }

        // Generate appropriate message
        let message =
            if context.command.isAllCommand {
                if droppedItems.isEmpty {
                    context.msg.youAreEmptyHanded()
                } else {
                    await context.msg.youDoMultipleItems(
                        context.command,
                        items: droppedItems
                    )
                }
            } else {
                context.msg.dropped()
            }

        return ActionResult(
            message: message,
            changes: allStateChanges
        )
    }
}
