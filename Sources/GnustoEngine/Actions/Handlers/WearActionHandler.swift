import Foundation

/// Handles the "WEAR" command and its synonyms (e.g., "DON"), allowing the player to
/// equip an item that is wearable.
public struct WearActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObjects),
        .match(.put, .on, .directObjects),
    ]

    public let synonyms: [Verb] = [.wear, .don]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "WEAR" command.
    ///
    /// This action validates prerequisites and handles wearing wearable items.
    /// Checks that items exist, are held by the player, are wearable, and not already worn.
    /// Supports both single items and ALL commands.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Get item proxies based on command type
        let items: [ItemProxy]
        if context.command.isAllCommand {
            items = try await context.itemDirectObjects()
        } else {
            // For single item commands, ensure we have at least one direct object
            guard context.command.directObjects.isNotEmpty else {
                throw ActionResponse.doWhat(context)
            }
            items = try await context.itemDirectObjects()
        }

        var allStateChanges = [StateChange]()
        var wornItems: [ItemProxy] = []

        // Process each object individually
        for item in items {
            do {
                // Check if player is holding the item
                guard await item.playerIsHolding else {
                    throw ActionResponse.itemNotHeld(item)
                }

                // Check if item is wearable
                guard await item.hasFlag(.isWearable) else {
                    throw ActionResponse.cannotDo(context, item)
                }

                // Check if already worn
                guard await !item.hasFlag(.isWorn) else {
                    throw await ActionResponse.feedback(
                        context.msg.itemIsAlreadyWorn(item.withDefiniteArticle)
                    )
                }

                // Set .isWorn flag
                await allStateChanges.appendIfPresent(
                    item.setFlag(.isWorn)
                )

                // Set .isTouched flag if not already set
                await allStateChanges.appendIfPresent(
                    item.setFlag(.isTouched)
                )

                wornItems.append(item)

            } catch {
                // For ALL commands, skip items that cause errors
                if !context.command.isAllCommand {
                    throw error
                }
            }
        }

        // Generate appropriate message
        let message: String
        if wornItems.isEmpty {
            if context.command.isAllCommand {
                message = context.msg.nothingHereToDo(context.command)
            } else {
                throw ActionResponse.doWhat(context)
            }
        } else {
            message = await context.msg.youPutOn(wornItems.listWithDefiniteArticles() ?? "")
        }

        return ActionResult(
            message: message,
            changes: allStateChanges
        )
    }
}
