import Foundation

/// Handles the "LOOK INSIDE" command and its variants (e.g., "LOOK IN", "LOOK WITH").
/// This command allows players to look inside containers or examine the contents of objects.
/// By default, it delegates to examine behavior, but specific items can override this via ItemEventHandlers.
public struct LookInsideActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .in, .directObject),
        .match(.verb, .inside, .directObject),
        .match(.verb, .with, .directObject),
    ]

    public let synonyms: [Verb] = [.look, .peek, .peer]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "LOOK INSIDE" command.
    ///
    /// This action validates prerequisites and handles looking inside containers or examining
    /// the internal contents of objects. Provides specialized messaging for containers.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Get direct object (with automatic reachability checking)
        guard let container = try await context.itemDirectObject() else {
            throw ActionResponse.doWhat(context)
        }

        // Determine the message based on whether item is a container
        let message: String

        if await container.isContainer {
            // For containers, provide container-specific messaging
            if await container.contentsAreVisible {
                let contents = try await container.contents
                if contents.isEmpty {
                    message = await context.msg.containerIsEmpty(
                        container.withDefiniteArticle
                    )
                } else {
                    message = await context.msg.containerContents(
                        container.withDefiniteArticle,
                        contents: contents.listWithIndefiniteArticles() ?? ""
                    )
                }
            } else {
                message = await context.msg.containerIsClosed(
                    container.withDefiniteArticle
                )
            }
        } else {
            // Generic non-container
            message = await context.msg.nothingOfInterestInside(
                container.withDefiniteArticle
            )
        }

        return try await ActionResult(
            message,
            container.setFlag(.isTouched)
        )
    }
}
