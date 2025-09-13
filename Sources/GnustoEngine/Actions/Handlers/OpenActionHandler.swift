import Foundation

/// Handles the "OPEN" command, allowing the player to open an item that is openable,
/// not locked, and not already open.
public struct OpenActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let synonyms: [Verb] = [.open]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "OPEN" command.
    ///
    /// This action validates prerequisites and opens the specified item if possible.
    /// Checks that the item exists, is reachable, openable, not locked, and not already open.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let container = try await context.itemDirectObject() else {
            throw ActionResponse.doWhat(context)
        }

        // Check if item is openable
        guard await container.isOpenable else {
            throw ActionResponse.cannotDo(context, container)
        }

        // Check if locked
        if await container.hasFlag(.isLocked) {
            throw await ActionResponse.feedback(
                context.msg.itemIsLocked(container.withDefiniteArticle)
            )
        }

        // Check if already open
        if await container.isOpen {
            throw await ActionResponse.feedback(
                context.msg.itemAlreadyOpen(container.withDefiniteArticle)
            )
        }

        // Determine appropriate message based on contents
        let message: String
        if await container.isContainer {
            let itemsInside = try await container.visibleItems
            if itemsInside.isEmpty {
                // Container is empty, use simple message
                message = await context.msg.opened(container.withDefiniteArticle)
            } else {
                // Announce what's revealed: "Opening the small mailbox reveals a leaflet."
                let itemList = await itemsInside.sorted().listWithIndefiniteArticles() ??
                context.msg.nothing()

                message = await context.msg.openingRevealsContents(
                    container.withDefiniteArticle,
                    contents: itemList
                )
            }
        } else if await container.isDoor {
            message = await context.msg.opened(container.withDefiniteArticle)
        } else {
            // Not a container
            message = await context.msg.cannotDo(
                context.command,
                item: container.withDefiniteArticle
            )
        }

        return try await ActionResult(
            message,
            container.setFlag(.isOpen),
            container.setFlag(.isTouched)
        )
    }
}
