import Foundation

/// Handles the "FILL" command for filling containers with liquids.
/// Implements container filling mechanics following ZIL patterns.
public struct FillActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .with, .indirectObject),
        .match(.verb, .directObject, .from, .indirectObject),
    ]

    public let synonyms: [Verb] = [.fill]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "FILL" command.
    ///
    /// This action validates prerequisites and handles filling containers with liquids.
    /// Supports filling from specified sources or auto-detecting water sources in the location.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Fill requires a direct object (what to fill)
        guard let containerItem = try await context.itemDirectObject() else {
            throw ActionResponse.doWhat(context)
        }

        // Check if target is actually a container
        guard await containerItem.isContainer else {
            throw ActionResponse.targetIsNotAContainer(containerItem)
        }

        // Check if container is open (can't fill closed containers)
        guard await containerItem.isOpen else {
            throw ActionResponse.containerIsClosed(containerItem)
        }

        // Check if source is specified
        guard let sourceItem = try await context.itemIndirectObject() else {
            return ActionResult(
                context.msg.fillContainerWithWhat(
                    await containerItem.withDefiniteArticle
                ),
                try await containerItem.setFlag(.isTouched)
            )
        }

        return ActionResult(
            context.msg.fillContainerWithSource(
                await containerItem.withDefiniteArticle,
                source: await sourceItem.withDefiniteArticle
            ),
            try await containerItem.setFlag(.isTouched)
        )
    }
}
