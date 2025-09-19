import Foundation

/// Handles the "READ" command, allowing the player to attempt to read text from an item.
public struct ReadActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let synonyms: [Verb] = [.read]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "READ" command.
    ///
    /// This action validates prerequisites and handles reading text from items.
    /// Checks that the item exists, is reachable, readable, and provides appropriate text output.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Get direct object (with automatic reachability checking)
        guard let targetItem = try await context.itemDirectObject() else {
            throw ActionResponse.doWhat(context)
        }

        // Check if item is readable
        guard await targetItem.hasFlag(.isReadable) else {
            throw ActionResponse.cannotDo(context, targetItem)
        }

        // Determine read text
        let readText =
            if let textToRead = await targetItem.readText, textToRead.isNotEmpty {
                textToRead
            } else {
                await context.msg.nothingWrittenOn(targetItem.withDefiniteArticle)
            }

        return if await targetItem.shouldTakeFirst {
            await ActionResult(
                """
                \(context.msg.takenImplied())
                \(readText)
                """,
                targetItem.move(to: .player),
                targetItem.setFlag(.isTouched)
            )
        } else {
            await ActionResult(
                readText,
                targetItem.setFlag(.isTouched)
            )
        }
    }
}
