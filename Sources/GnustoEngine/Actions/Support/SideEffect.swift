/// Represents a side effect of an action (e.g., starting a fuse, running a daemon).
public struct SideEffect: Sendable, Equatable {
    /// The type of side effect.
    public let type: SideEffectType

    /// The entity targeted by or associated with the effect.
    public let targetID: EntityID

    /// Any additional parameters specific to the side effect type.
    public let parameters: [String: StateValue]

    /// Creates a new side effect record.
    /// - Parameters:
    ///   - type: The type of side effect.
    ///   - targetID: The EntityID targeted by or associated with the side effect.
    ///   - parameters: Additional data required for the side effect.
    public init(
        type: SideEffectType,
        targetID: EntityID,
        parameters: [String: StateValue] = [:]
    ) {
        self.type = type
        self.targetID = targetID
        self.parameters = parameters
    }
}

/// Enumerates the types of possible side effects.
public enum SideEffectType: String, Codable, Sendable, Equatable {
    case startFuse
    case stopFuse
    case runDaemon
    case stopDaemon
    case scheduleEvent // e.g., for delayed messages or actions
    // Add more as needed
}
