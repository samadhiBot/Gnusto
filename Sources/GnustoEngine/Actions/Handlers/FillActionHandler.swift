import Foundation

/// Handles the "FILL" command for filling containers with liquids.
/// Implements container filling mechanics following ZIL patterns.
public struct FillActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let verbID: VerbID = .fill

    public let syntax: [SyntaxRule] = [
        SyntaxRule(.verb, .directObject),
        SyntaxRule(.verb, .directObject, .particle("with"), .indirectObject),
        SyntaxRule(.verb, .directObject, .particle("from"), .indirectObject)
    ]

    public let synonyms: [String] = []

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Validates the "FILL" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to fill).
    /// 2. The target container exists, is reachable, and is a container.
    /// 3. If a source is specified, it exists and contains liquid.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // Fill requires a direct object (what to fill)
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.doWhat(verb: .fill)
            )
        }
        guard case .item(let containerItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.cannotDoThat(verb: "fill")
            )
        }

        // Check if container exists and is reachable
        let containerItem = try await context.engine.item(containerItemID)
        guard await context.engine.playerCanReach(containerItemID) else {
            throw ActionResponse.itemNotAccessible(containerItemID)
        }

        // Check if target is actually a container
        guard containerItem.hasFlag(.isContainer) else {
            throw ActionResponse.targetIsNotAContainer(containerItemID)
        }

        // Check if container is open (can't fill closed containers)
        guard containerItem.hasFlag(.isOpen) else {
            throw ActionResponse.containerIsClosed(containerItemID)
        }

        // If a source is specified, validate it
        if let indirectObjectRef = context.command.indirectObject {
            guard case .item(let sourceItemID) = indirectObjectRef else {
                throw ActionResponse.prerequisiteNotMet(
                    context.message.cannotFillFrom()
                )
            }

            _ = try await context.engine.item(sourceItemID)
            guard await context.engine.playerCanReach(sourceItemID) else {
                throw ActionResponse.itemNotAccessible(sourceItemID)
            }
        }
    }

    /// Processes the "FILL" command.
    ///
    /// Handles container filling with different scenarios:
    /// - Filling from specified sources (water taps, streams)
    /// - Filling from other containers
    /// - Auto-detecting water sources in the current location
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate filling message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
            case .item(let containerItemID) = directObjectRef
        else {
            let message = context.message.actionHandlerInternalError(
                handler: "FillActionHandler",
                details: "directObject was not an item in process"
            )
            throw ActionResponse.internalEngineError(message)
        }

        let containerItem = try await context.engine.item(containerItemID)

        // Handle filling from specified source
        if let indirectObjectRef = context.command.indirectObject,
            case .item(let sourceItemID) = indirectObjectRef
        {
            let sourceItem = try await context.engine.item(sourceItemID)

            // Check if source has drinkable liquid or is a water source
            let message =
                if sourceItem.hasFlag(.isDrinkable) {
                    context.message.fillSuccess(
                        container: containerItem.name,
                        source: sourceItem.name
                    )
                    // TODO: In a full implementation, you might create a new liquid item in the container
                } else {
                    context.message.noLiquidInSource(source: sourceItem.name)
                }

            return ActionResult(
                message: message,
                changes: [
                    await context.engine.setFlag(.isTouched, on: containerItem),
                    await context.engine.updatePronouns(to: containerItem),
                ]
            )
        } else {
            // No source specified - look for water sources in current location
            let currentLocationID = await context.engine.playerLocationID
            let locationItems = await context.engine.items(in: .location(currentLocationID))
            let waterSources = locationItems.filter { $0.hasFlag(.isDrinkable) }

            let message = if waterSources.isEmpty {
                context.message.noLiquidSourceAvailable()
            } else {
                context.message.fillSuccess(
                    container: containerItem.name,
                    source: waterSources[0].name
                )
                // TODO: In a full implementation, you might create a new liquid item in the container
            }

            return ActionResult(
                message: message,
                changes: [
                    await context.engine.setFlag(.isTouched, on: containerItem),
                    await context.engine.updatePronouns(to: containerItem),
                ]
            )
        }
    }

    /// Performs any post-processing after the fill action completes.
    ///
    /// Currently no post-processing is needed for filling.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext) async throws {
        // No post-processing needed for fill
    }
}

// MARK: - Engine Extension for Water Creation

extension GameEngine {
    /// Creates a water item in the specified container.
    /// This is a helper method for the fill action.
    ///
    /// - Parameter containerID: The ID of the container to fill with water.
    /// - Returns: A StateChange that creates water, or nil if unsuccessful.
    func createWaterItem(in containerID: ItemID) async -> StateChange? {
        // This is a simplified implementation
        // In a real game, this would reference the game's specific water item
        // For now, we'll return nil and let the message handle success
        return nil
    }
}
