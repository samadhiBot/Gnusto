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

    public let verbs: [VerbID] = [.fill]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "FILL" command.
    ///
    /// This action validates prerequisites and handles filling containers with liquids.
    /// Supports filling from specified sources or auto-detecting water sources in the location.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Fill requires a direct object (what to fill)
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }

        guard case .item(let containerItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "fill")
            )
        }

        // Check if container exists and is accessible
        let containerItem = try await engine.item(containerItemID)
        guard await engine.playerCanReach(containerItemID) else {
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

        // Check if container is already full
        let containerContents = await engine.items(in: .item(containerItemID))
        if containerItem.capacity >= 0 {
            let currentLoad = containerContents.reduce(0) { $0 + $1.size }
            if currentLoad >= containerItem.capacity {
                return ActionResult(
                    engine.messenger.containerAlreadyFull(
                        container: containerItem.withDefiniteArticle
                    ),
                    await engine.setFlag(.isTouched, on: containerItem),
                    await engine.updatePronouns(to: containerItem)
                )
            }
        }

        var additionalStateChanges: [StateChange] = []

        // Handle filling from specified source
        if let indirectObjectRef = command.indirectObject {
            guard case .item(let sourceItemID) = indirectObjectRef else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.cannotFillFrom()
                )
            }

            let sourceItem = try await engine.item(sourceItemID)
            guard await engine.playerCanReach(sourceItemID) else {
                throw ActionResponse.itemNotAccessible(sourceItemID)
            }

            // Mark source as touched
            if let sourceTouchedChange = await engine.setFlag(.isTouched, on: sourceItem) {
                additionalStateChanges.append(sourceTouchedChange)
            }

            // Check if source has liquid or is a water source
            if sourceItem.hasFlag(.isWaterSource) {
                // Infinite water source (well, tap, stream)
                let message = engine.messenger.fillFromWaterSource(
                    container: containerItem.withDefiniteArticle,
                    source: sourceItem.withDefiniteArticle
                )

                return ActionResult(
                    message,
                    await engine.setFlag(.isTouched, on: containerItem),
                    await engine.updatePronouns(to: containerItem),
                    additionalStateChanges
                )
            } else if sourceItem.hasFlag(.isContainer) && sourceItem.hasFlag(.isOpen) {
                // Fill from another container
                let sourceContents = await engine.items(in: .item(sourceItemID))
                let liquidItems = sourceContents.filter { $0.hasFlag(.isDrinkable) }

                guard let liquid = liquidItems.first else {
                    throw ActionResponse.prerequisiteNotMet(
                        engine.messenger.noLiquidInContainer(
                            container: sourceItem.withDefiniteArticle
                        )
                    )
                }

                // Move liquid from source to target container
                let moveLiquidChange = await engine.move(liquid, to: .item(containerItemID))
                additionalStateChanges.append(moveLiquidChange)

                return ActionResult(
                    engine.messenger.fillFromContainer(
                        container: containerItem.withDefiniteArticle,
                        source: sourceItem.withDefiniteArticle,
                        liquid: liquid.withIndefiniteArticle
                    ),
                    await engine.setFlag(.isTouched, on: containerItem),
                    await engine.updatePronouns(to: containerItem),
                    additionalStateChanges
                )
            } else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.cannotFillFromThat(
                        source: sourceItem.withDefiniteArticle
                    )
                )
            }
        } else {
            // No source specified - look for water sources in current location
            let currentLocationID = await engine.playerLocationID
            let locationItems = await engine.items(in: .location(currentLocationID))
            let waterSources = locationItems.filter { $0.hasFlag(.isWaterSource) }

            if let waterSource = waterSources.first {
                return ActionResult(
                    engine.messenger.fillFromWaterSource(
                        container: containerItem.withDefiniteArticle,
                        source: waterSource.withDefiniteArticle
                    ),
                    await engine.setFlag(.isTouched, on: containerItem),
                    await engine.updatePronouns(to: containerItem)
                )
            } else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.noWaterSourceAvailable()
                )
            }
        }
    }
}
