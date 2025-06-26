import Foundation

/// Handles the "LOOK INSIDE" command and its variants (e.g., "LOOK IN", "LOOK WITH").
/// This command allows players to look inside containers or examine the contents of objects.
/// By default, it delegates to examine behavior, but specific items can override this via ItemEventHandlers.
public struct LookInsideActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .in, .directObject),
        .match(.verb, .inside, .directObject),
    ]

    public let verbs: [VerbID] = [.look, .peek]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "LOOK INSIDE" command.
    ///
    /// This action validates prerequisites and handles looking inside containers or examining
    /// the internal contents of objects. Provides specialized messaging for containers.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.canOnlyLookInsideItems()
            )
        }

        // Check if item exists and is accessible
        let targetItem = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Determine the message based on whether item is a container
        let message: String
        if targetItem.hasFlag(.isContainer) {
            // For containers, provide container-specific messaging
            let isOpen = try await engine.hasFlag(.isOpen, on: targetItem.id)

            if !isOpen {
                if targetItem.hasFlag(.isTransparent) {
                    // Can see through transparent containers even when closed
                    let items = await engine.items(in: .item(targetItem.id))
                    if items.isEmpty {
                        message = engine.messenger.containerIsEmpty(
                            container: targetItem.withDefiniteArticle
                        )
                    } else {
                        let itemListing = items.listWithIndefiniteArticles
                        message = engine.messenger.containerContains(
                            container: targetItem.withDefiniteArticle,
                            contents: itemListing
                        )
                    }
                } else {
                    message = engine.messenger.containerIsClosed(
                        container: targetItem.withDefiniteArticle
                    )
                }
            } else {
                // Show container contents
                let items = await engine.items(in: .item(targetItem.id))
                if items.isEmpty {
                    message = engine.messenger.containerIsEmpty(
                        container: targetItem.withDefiniteArticle
                    )
                } else {
                    let itemListing = items.listWithIndefiniteArticles
                    message = engine.messenger.containerContains(
                        container: targetItem.withDefiniteArticle,
                        contents: itemListing
                    )
                }
            }
        } else {
            // For non-containers, provide specialized "look inside" messaging
            if targetItem.hasFlag(.isSurface) {
                // Surfaces can have items "on" them, not "in" them
                message = engine.messenger.cannotLookInsideSurface(
                    item: targetItem.withDefiniteArticle
                )
            } else {
                // Generic non-container
                message = engine.messenger.nothingSpecialInside(
                    item: targetItem.withDefiniteArticle
                )
            }
        }

        return ActionResult(
            message,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }
}
