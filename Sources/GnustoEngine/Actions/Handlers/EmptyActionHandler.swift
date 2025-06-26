import Foundation

/// Handles the "EMPTY" command for emptying containers of their contents.
/// Implements emptying mechanics following ZIL patterns.
public struct EmptyActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .into, .indirectObject),
        .match(.verb, .out, .directObject),
    ]

    public let verbs: [VerbID] = [.empty, .dump, .pour]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "EMPTY" command.
    ///
    /// This action validates prerequisites and handles emptying containers of their contents.
    /// Checks that the item exists, is reachable, is a container, and is currently open.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Empty requires a direct object (what to empty)
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.canOnlyEmptyContainers()
            )
        }

        // Check if target exists and is accessible
        let targetItem = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Check if item is a container
        guard targetItem.hasFlag(.isContainer) else {
            throw ActionResponse.targetIsNotAContainer(targetItemID)
        }

        // Check if container is open (can't empty closed containers)
        guard try await engine.hasFlag(.isOpen, on: targetItemID) else {
            throw ActionResponse.containerIsClosed(targetItemID)
        }

        // Get current contents of the container
        let contents = await engine.items(in: .item(targetItemID))

        let message: String
        var allStateChanges: [StateChange] = []

        if contents.isEmpty {
            message = engine.messenger.containerAlreadyEmpty(
                container: targetItem.withDefiniteArticle.capitalizedFirst
            )
        } else {
            // Determine destination for contents
            let destinationParent: ParentEntity

            if let indirectObjectRef = command.indirectObject {
                // "EMPTY X INTO Y" syntax
                guard case .item(let destinationItemID) = indirectObjectRef else {
                    throw ActionResponse.prerequisiteNotMet(
                        "🤡 engine.messenger.cannotEmptyIntoThat()"
                    )
                }

                let destinationItem = try await engine.item(destinationItemID)
                guard destinationItem.hasFlag(.isContainer) else {
                    throw ActionResponse.targetIsNotAContainer(destinationItemID)
                }

                guard try await engine.hasFlag(.isOpen, on: destinationItemID) else {
                    throw ActionResponse.containerIsClosed(destinationItemID)
                }

                destinationParent = .item(destinationItemID)
            } else {
                // Default: empty into current location
                let currentLocationID = await engine.playerLocationID
                destinationParent = .location(currentLocationID)
            }

            // Move all contents to destination
            for item in contents {
                let moveChange = await engine.move(item, to: destinationParent)
                allStateChanges.append(moveChange)
            }

            message = engine.messenger.emptySuccess(
                container: targetItem.withDefiniteArticle,
                items: contents.listWithIndefiniteArticles,
                count: contents.count
            )
        }

        // Add standard state changes
        if let touchedChange = await engine.setFlag(.isTouched, on: targetItem) {
            allStateChanges.append(touchedChange)
        }

        if let pronounChange = await engine.updatePronouns(to: targetItem) {
            allStateChanges.append(pronounChange)
        }

        return ActionResult(
            message: message,
            changes: allStateChanges
        )
    }
}
