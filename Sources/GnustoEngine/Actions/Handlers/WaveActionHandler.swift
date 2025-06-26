import Foundation

/// Handles the "WAVE" command for waving objects.
/// Implements waving mechanics following ZIL patterns for physical interactions.
public struct WaveActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.wave, .at, .directObject),
        .match(.wave, .to, .directObject),
        .match(.verb, .directObject, .at, .indirectObject),
    ]

    public let verbs: [VerbID] = [.wave, .brandish]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "WAVE" command.
    ///
    /// This action validates prerequisites and handles waving attempts on different types
    /// of objects. Generally provides descriptive responses following ZIL traditions.
    /// Can optionally wave at a target specified in the indirect object.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Wave requires a direct object (what to wave)
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "wave")
            )
        }

        // Check if target exists and is accessible
        let targetItem = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Handle optional target to wave at (indirect object)
        var additionalStateChanges: [StateChange] = []
        if let indirectObjectRef = command.indirectObject {
            guard case .item(let waveTargetID) = indirectObjectRef else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.cannotWaveAtThat()
                )
            }

            let waveTarget = try await engine.item(waveTargetID)
            guard await engine.playerCanReach(waveTargetID) else {
                throw ActionResponse.itemNotAccessible(waveTargetID)
            }

            // Mark wave target as touched too
            if let targetTouchedChange = await engine.setFlag(.isTouched, on: waveTarget) {
                additionalStateChanges.append(targetTouchedChange)
            }
        }

        // Determine appropriate response based on object type and properties
        let message =
            if !targetItem.hasFlag(.isTakable) {
                // Fixed objects can't be waved
                engine.messenger.waveFixedObject(item: targetItem.withDefiniteArticle)
            } else if targetItem.parent != .player {
                // Must be holding the item to wave it
                engine.messenger.mustBeHoldingToWave(item: targetItem.withDefiniteArticle)
            } else if targetItem.hasFlag(.isWeapon) {
                // Weapons are brandished
                if let indirectObjectRef = command.indirectObject,
                    case .item(let waveTargetID) = indirectObjectRef
                {
                    let waveTarget = try await engine.item(waveTargetID)
                    engine.messenger.waveWeaponAt(
                        weapon: targetItem.withDefiniteArticle,
                        target: waveTarget.withDefiniteArticle
                    )
                } else {
                    engine.messenger.waveWeapon(item: targetItem.withDefiniteArticle)
                }
            } else if targetItem.hasFlag(.isMagical) {
                // Magical items might have special waving effects
                engine.messenger.waveMagicalItem(item: targetItem.withDefiniteArticle)
            } else {
                // Generic waving response for other takable objects
                if let indirectObjectRef = command.indirectObject,
                    case .item(let waveTargetID) = indirectObjectRef
                {
                    let waveTarget = try await engine.item(waveTargetID)
                    engine.messenger.waveObjectAt(
                        item: targetItem.withDefiniteArticle,
                        target: waveTarget.withDefiniteArticle
                    )
                } else {
                    engine.messenger.waveObject(item: targetItem.withDefiniteArticle)
                }
            }

        return ActionResult(
            message,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem),
            additionalStateChanges
        )
    }
}
