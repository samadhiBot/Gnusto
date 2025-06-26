import Foundation

/// Handles the "READ" command, allowing the player to attempt to read text from an item.
public struct ReadActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let verbs: [VerbID] = [.read]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "READ" command.
    ///
    /// This action validates prerequisites and handles reading text from items.
    /// Checks that the item exists, is reachable, readable, and provides appropriate text output.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Ensure we have a direct object and it's an item
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.custom(
                engine.messenger.doWhat(verb: command.verb)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.thatsNotSomethingYouCan(.read)
            )
        }

        // Check if item exists
        let targetItem = try await engine.item(targetItemID)

        // Check if room is lit (unless item provides light)
        guard await engine.playerLocationIsLit() else {
            throw ActionResponse.roomIsDark
        }

        // Check reachability
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Check if item is readable
        guard targetItem.hasFlag(.isReadable) else {
            throw ActionResponse.itemNotReadable(targetItemID)
        }

        // Determine read text
        let readText =
            if let textToRead: String = try await engine.attribute(
                .readText, of: targetItem.id
            ), !textToRead.isEmpty {
                textToRead
            } else {
                engine.messenger.nothingWrittenOn(item: targetItem.withDefiniteArticle)
            }

        // Build final message
        let message =
            if targetItem.shouldTakeFirst {
                """
                \(engine.messenger.taken())
                \(readText)
                """
            } else {
                readText
            }

        return ActionResult(
            message,
            targetItem.shouldTakeFirst ? await engine.move(targetItem, to: .player) : nil,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }
}
