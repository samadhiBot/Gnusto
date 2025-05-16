import Foundation

/// Result of an action execution with enhanced information.
public struct ActionResult: Sendable {
    /// Message to display to the player.
    ///
    /// When a message is provided, the engine outputs the message and stops further processing.
    /// When no message is provided, it applies the state changes, but then proceeds with the
    /// command's normal messaging.
    public let message: String?

    /// Any state changes that occurred.
    public let stateChanges: [StateChange]

    /// Any side effects that need to be processed.
    public let sideEffects: [SideEffect]

    /// Creates a new action result.
    ///
    /// - Parameters:
    ///   - message: Any message to display to the player.
    ///   - stateChanges: Any state changes that occurred.
    ///   - sideEffects: Any side effects to be processed.
    public init(
        message: String? = nil,
        stateChanges: [StateChange] = [],
        sideEffects: [SideEffect] = []
    ) {
        assert(
            message != nil || !stateChanges.isEmpty || !sideEffects.isEmpty,
            "ActionResults must contain at least one of message, stateChanges, or sideEffects"
        )
        self.message = message
        self.stateChanges = stateChanges
        self.sideEffects = sideEffects
    }
    
    /// Creates a new action result.
    ///
    /// - Parameters:
    ///   - message: Any message to display to the player.
    ///   - stateChange: A state change that occurred.
    ///   - sideEffect: A side effect to be processed.
    public init(
        message: String? = nil,
        stateChange: StateChange? = nil,
        sideEffect: SideEffect? = nil
    ) {
        assert(
            message != nil || stateChange != nil || sideEffect != nil,
            "ActionResults must contain at least one of message, stateChanges, or sideEffects"
        )
        self.message = message
        self.stateChanges = if let stateChange { [stateChange] } else { [] }
        self.sideEffects = if let sideEffect { [sideEffect] } else { [] }
    }

    /// Creates a new action result with no state changes or side effects.
    ///
    /// - Parameter message: A message to display to the player.
    public init(_ message: String) {
        self.message = message
        self.stateChanges = []
        self.sideEffects = []
    }
}
