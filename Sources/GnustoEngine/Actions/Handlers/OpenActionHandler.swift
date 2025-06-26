import Foundation

/// Handles the "OPEN" command, allowing the player to open an item that is openable,
/// not locked, and not already open.
public struct OpenActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let verbs: [Verb] = [.open]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "OPEN" command.
    ///
    /// This action validates prerequisites and opens the specified item if possible.
    /// Checks that the item exists, is reachable, openable, not locked, and not already open.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Check for multiple objects (not supported by OPEN)
        if command.directObjects.count > 1 {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.multipleObjectsNotSupported(verb: "open")
            )
        }

        // Ensure we have a direct object and it's an item
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.thatsNotSomethingYouCan(.open)
            )
        }

        // Check if item exists and is accessible
        let targetItem = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Check if item is openable
        guard targetItem.hasFlag(.isOpenable) else {
            throw ActionResponse.itemNotOpenable(targetItemID)
        }

        // Check if locked
        if targetItem.hasFlag(.isLocked) {
            throw ActionResponse.itemIsLocked(targetItemID)
        }

        // Check if already open
        if try await engine.hasFlag(.isOpen, on: targetItem.id) {
            throw ActionResponse.itemAlreadyOpen(targetItemID)
        }

        // Determine appropriate message based on contents
        let message: String
        if targetItem.hasFlag(.isContainer) {
            let itemsInside = await engine.items(in: .item(targetItemID))
            if itemsInside.isNotEmpty {
                // Announce what's revealed: "Opening the small mailbox reveals a leaflet."
                let itemList = itemsInside.sorted().listWithIndefiniteArticles
                message = engine.messenger.openingRevealsContents(
                    container: targetItem.withDefiniteArticle,
                    contents: itemList
                )
            } else {
                // Container is empty, use simple message
                message = engine.messenger.opened(item: targetItem.withDefiniteArticle)
            }
        } else {
            // Not a container, use simple message
            message = engine.messenger.opened(item: targetItem.withDefiniteArticle)
        }

        return ActionResult(
            message,
            await engine.setFlag(.isOpen, on: targetItem),
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }
}
