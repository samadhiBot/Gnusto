import Foundation

/// Provides context for an action being performed.
public struct ActionContext: Equatable {
    /// The parsed user input that led to this action.
    public let command: UserInput

    /// The actor performing the action (usually the player).
    public let actor: Object.ID

    /// The location where the action is taking place.
    public let location: Object.ID

    /// Any additional data needed for the action.
    public let additionalData: [String: AnyValue]

    public init(
        command: UserInput,
        actor: Object.ID,
        location: Object.ID,
        additionalData: [String: AnyValue] = [:]
    ) {
        self.command = command
        self.actor = actor
        self.location = location
        self.additionalData = additionalData
    }
}

extension ActionContext {
    /// Create an action context for updating a light source.
    public static func updateLightSource(
        objectID: Object.ID,
        isOn: Bool,
        actor: Object.ID,
        location: Object.ID
    ) -> ActionContext {
        let turnVerb: VerbID = isOn ? "turn on" : "turn off"
        let userInput = UserInput(
            verb: turnVerb,
            directObject: objectID.rawValue,
            rawInput: "\(turnVerb) \(objectID.rawValue)"
        )
        return ActionContext(
            command: userInput,
            actor: actor,
            location: location,
            additionalData: [
                "action": AnyValue("updateLightSource"),
                "isOn": AnyValue(isOn)
            ]
        )
    }

    /// Check if this context is for a specific custom action type.
    public func isAction(_ actionType: String) -> Bool {
        guard let storedAction: String = additionalData["action"]?.get() else {
            return false
        }
        return storedAction == actionType
    }

    /// Convenience accessors for command properties.
    public var verb: VerbID? { command.verb }
    public var directObject: String? { command.directObject }
    public var indirectObject: String? { command.indirectObject }
    public var prepositions: [String] { command.prepositions }
    public var direction: Direction? { nil }
}
