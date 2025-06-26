import Foundation

/// Handles the "TURN" command for turning objects.
/// Implements turning mechanics following ZIL patterns for object manipulation.
public struct TurnActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .to, .indirectObject),
    ]

    public let verbs: [Verb] = [.turn, .rotate, .twist]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "TURN" command.
    ///
    /// This action validates prerequisites and handles turning attempts on different types
    /// of objects. Provides appropriate responses following ZIL traditions.
    /// Can optionally turn to a specific setting specified in the indirect object.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Turn requires a direct object (what to turn)
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "turn")
            )
        }

        // Check if target exists and is accessible
        let targetItem = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Handle optional setting to turn to (indirect object)
        var settingDescription: String?
        if let indirectObjectRef = command.indirectObject {
            switch indirectObjectRef {
            case .item(let settingItemID):
                let settingItem = try await engine.item(settingItemID)
                settingDescription = settingItem.name
            case .location(let locationID):
                let location = try await engine.location(locationID)
                settingDescription = location.name
            case .player:
                settingDescription = "yourself"
            }
        }

        // Determine appropriate response based on object type
        let message = "🤡 `turn` placeholder for \(targetItemID)"
//            if targetItem.hasFlag(.isCharacter) {
//                // Can't turn characters
//                engine.messenger.turnCharacter(character: targetItem.withDefiniteArticle)
//            } else if targetItem.hasFlag(.isKey) {
//                // Keys need to be used with something
//                engine.messenger.turnKey(item: targetItem.withDefiniteArticle)
//            } else if targetItem.hasFlag(.isDial) {
//                // Dials click into position
//                if let setting = settingDescription {
//                    engine.messenger.turnDialTo(
//                        dial: targetItem.withDefiniteArticle,
//                        setting: setting
//                    )
//                } else {
//                    engine.messenger.turnDial(item: targetItem.withDefiniteArticle)
//                }
//            } else if targetItem.hasFlag(.isKnob) {
//                // Knobs click into position
//                if let setting = settingDescription {
//                    engine.messenger.turnKnobTo(
//                        knob: targetItem.withDefiniteArticle,
//                        setting: setting
//                    )
//                } else {
//                    engine.messenger.turnKnob(item: targetItem.withDefiniteArticle)
//                }
//            } else if targetItem.hasFlag(.isWheel) {
//                // Wheels rotate with effort
//                engine.messenger.turnWheel(item: targetItem.withDefiniteArticle)
//            } else if targetItem.hasFlag(.isHandle) {
//                // Handles move with grinding sound
//                engine.messenger.turnHandle(item: targetItem.withDefiniteArticle)
//            } else if targetItem.hasFlag(.isTakable) {
//                // Regular takable objects can be turned in hands
//                engine.messenger.turnRegularObject(item: targetItem.withDefiniteArticle)
//            } else {
//                // Fixed objects can't be turned
//                engine.messenger.turnFixedObject(item: targetItem.withDefiniteArticle)
//            }

        return ActionResult(
            message,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }
}
