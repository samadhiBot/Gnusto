import Foundation

/// Handles the "EMPTY" command for emptying containers of their contents.
/// Implements emptying mechanics following ZIL patterns.
public struct EmptyActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.pour, .out, .directObject),
        .match(.verb, .out, .directObject),
        .match(.pour, .directObject, .into, .indirectObject),
        .match(.verb, .directObject, .into, .indirectObject),
    ]

    public let synonyms: [Verb] = [.empty, .dump]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "EMPTY" command.
    ///
    /// This action validates prerequisites and handles emptying containers of their contents.
    /// Checks that the item exists, is reachable, is a container, and is currently open.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let container = try await context.itemDirectObject() else {
            // Empty requires a direct object (what to empty)
            throw ActionResponse.doWhat(context)
        }

        // Check if item is a container
        guard await container.isContainer else {
            throw ActionResponse.targetIsNotAContainer(container)
        }

        // Check if container is open (can't empty closed containers)
        guard await container.isOpen else {
            throw ActionResponse.containerIsClosed(container)
        }

        // Get current contents of the container
        let contents = try await container.contents

        guard contents.isNotEmpty else {
            throw ActionResponse.feedback(
                await context.msg.containerAlreadyEmpty(
                    container.withDefiniteArticle
                )
            )
        }

        let destination: ParentEntity
        let message: String
        var allStateChanges = [StateChange]()

        if let newContainer = try await context.itemIndirectObject() {
            // "EMPTY X INTO Y" syntax
            guard await newContainer.isContainer else {
                throw ActionResponse.targetIsNotAContainer(newContainer)
            }

            guard await newContainer.isOpen else {
                throw ActionResponse.containerIsClosed(newContainer)
            }

            destination = .item(newContainer.id)

            message = await context.msg.emptyIntoTargetSuccess(
                container.withDefiniteArticle,
                items: contents.listWithIndefiniteArticles() ?? "nothing",
                target: newContainer.withDefiniteArticle
            )

        } else {
            // Default: empty into current location
            let currentLocationID = try await context.player.location.id

            destination = .location(currentLocationID)

            message = await context.msg.emptyOntoGroundSuccess(
                container.withDefiniteArticle,
                items: contents.listWithIndefiniteArticles() ?? "nothing",
                count: contents.count
            )
        }

        // Move all contents to destination
        for item in contents {
            try await allStateChanges.append(
                contentsOf: [
                    item.move(to: destination),
                    item.setFlag(.isTouched),
                ].compactMap(\.self)
            )
        }

        // Add standard state changes
        allStateChanges.append(
            try await container.setFlag(.isTouched)
        )

        return ActionResult(
            message: message,
            changes: allStateChanges
        )
    }
}
