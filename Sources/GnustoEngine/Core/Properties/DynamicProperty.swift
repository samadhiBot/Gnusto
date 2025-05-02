import Foundation

/// Represents a property whose value might be computed dynamically based on game state
/// or validated before changes, using `StateValue` for type safety and `Sendable` conformance.
public struct DynamicProperty: Sendable, Codable, Equatable {

    /// The underlying storage for the property's value.
    public var storedValue: StateValue

    /// A closure that computes the property's value dynamically based on the owning entity and game state.
    /// If `nil`, the `storedValue` is used directly.
    /// The closure *must* return a `StateValue` matching the type implied by `storedValue`.
    public let computeHandler: (@MainActor @Sendable (Any, GameState) -> StateValue)?

    /// A closure that validates a potential new value before it's assigned.
    /// Returns `true` if the new value is valid (including matching the expected type), `false` otherwise.
    /// If `nil`, only type validation is performed.
    public let validateHandler: (@MainActor @Sendable (StateValue) -> Bool)?

    /// Initializes a new dynamic property.
    ///
    /// - Parameters:
    ///   - initialValue: The initial value of the property, determining its expected type.
    ///   - compute: An optional closure to compute the value dynamically.
    ///   - validate: An optional closure to validate new values.
    public init(
        initialValue: StateValue,
        compute: (@MainActor @Sendable (Any, GameState) -> StateValue)? = nil,
        validate: (@MainActor @Sendable (StateValue) -> Bool)? = nil
    ) {
        self.storedValue = initialValue
        self.computeHandler = compute
        self.validateHandler = validate
    }

    /// Gets the current value of the property, computing it if necessary.
    ///
    /// - Parameters:
    ///   - owner: The entity (e.g., `Item`, `Location`) that owns this property.
    ///   - gameState: The current game state.
    /// - Returns: The current, potentially computed, `StateValue`.
    /// - Throws: `ActionError.internalEngineError` if the compute handler returns the wrong `StateValue` type.
    @MainActor
    public func currentValue(
        owner: Any,
        gameState: GameState
    ) throws -> StateValue {
        guard let computeHandler else {
            return storedValue
        }

        let computedValue = computeHandler(owner, gameState)
        // Verify the computed value has the same underlying type as the stored value.
        guard type(of: storedValue) == type(of: computedValue) else {
            throw ActionError.internalEngineError(
                "DynamicProperty compute handler returned mismatching StateValue type. Expected type similar to \(storedValue), got \(computedValue)."
            )
        }
        return computedValue
    }

    /// Attempts to set a new value for the property, performing type and custom validation.
    ///
    /// - Parameter newValue: The proposed new `StateValue`.
    /// - Throws: `ActionError.invalidValue` if type validation or custom validation fails.
    /// - Note: This method only validates and updates the `storedValue` within this struct.
    ///   The owning entity or `GameEngine` must create and apply the corresponding `StateChange`.
    @MainActor
    public mutating func setValue(_ newValue: StateValue) throws {
        // 1. Type Validation: Ensure the new value's type matches the original type.
        guard type(of: newValue) == type(of: storedValue) else {
            throw ActionError.invalidValue(
                "Type mismatch for dynamic property. Expected type similar to \(storedValue), got \(newValue)."
            )
        }

        // 2. Custom Validation: Use the provided handler if it exists.
        if let validateHandler, !validateHandler(newValue) {
            throw ActionError.invalidValue("Custom validation failed for new dynamic property value: \(newValue)")
        }

        // 3. Update Stored Value
        self.storedValue = newValue
    }

    // MARK: - Codable Conformance

    enum CodingKeys: String, CodingKey {
        case storedValue
        // Handlers are not encoded
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        storedValue = try container.decode(StateValue.self, forKey: .storedValue)
        // Handlers are initialized to nil when decoding; runtime setup is needed.
        computeHandler = nil
        validateHandler = nil
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(storedValue, forKey: .storedValue)
        // Handlers are not encoded
    }

    // MARK: - Equatable Conformance

    public static func == (lhs: DynamicProperty, rhs: DynamicProperty) -> Bool {
        // Only compare stored values. Handlers represent behavior logic,
        // not state equality in this context.
        lhs.storedValue == rhs.storedValue
    }
}

/// Protocol for entities (like `Item` or `Location`) that can manage dynamic properties.
///
/// This allows a unified way to access and potentially modify properties that might be
/// simple stored values or dynamically computed/validated ones.
public protocol DynamicPropertyContainer: Sendable {
    /// A dictionary holding the dynamic properties, keyed by a property identifier.
    var dynamicProperties: [PropertyID: DynamicProperty] { get set }

    /// Retrieves a dynamic property instance by its key.
    ///
    /// - Parameter key: The property identifier.
    /// - Returns: The `DynamicProperty` instance if found, otherwise `nil`.
    func getDynamicProperty(
        _ key: PropertyID
    ) -> DynamicProperty?

    /// Attempts to set the `storedValue` of a dynamic property after validation.
    ///
    /// This method should typically:
    /// 1. Retrieve the `DynamicProperty` instance using `getDynamicProperty`.
    /// 2. Call `setValue` on the `DynamicProperty` instance (handles validation).
    /// 3. If successful, update the `dynamicProperties` dictionary with the modified `DynamicProperty`.
    /// 4. **Crucially**, the caller (e.g., `GameEngine`) must then create the appropriate `StateChange`
    ///    (using the *validated* `newValue` from the `DynamicProperty`'s `storedValue`)
    ///    and use `GameState.apply` to persist the change in `GameState`.
    ///
    /// - Parameters:
    ///   - key: The property identifier.
    ///   - value: The new `StateValue` to set.
    /// - Throws: An error if the property doesn't exist, or validation fails.
    @MainActor
    mutating func setDynamicPropertyValue(
        _ key: PropertyID,
        value: StateValue
    ) throws
}

// MARK: - Convenience Accessors for DynamicPropertyContainer
// Provides type-safe getters/setters for common StateValue types.

extension DynamicPropertyContainer {

    /// Retrieves the current value of a boolean dynamic property.
    ///
    /// - Parameters:
    ///   - key: The property key.
    ///   - owner: The owning entity (Self).
    ///   - gameState: The current game state.
    /// - Returns: The boolean value, or `nil` if the property doesn't exist, isn't a bool, or computation fails.
    @MainActor
    public func dynamicBoolValue(
        forKey key: PropertyID,
        owner: Any, // Pass self here
        gameState: GameState
    ) -> Bool? {
        guard let property = getDynamicProperty(key) else { return nil }
        guard case .bool = property.storedValue else { return nil } // Check initial type
        return try? property.currentValue(owner: owner, gameState: gameState).toBool
    }

    /// Retrieves the current value of an integer dynamic property.
    /// (Similar implementations for other types: String, ItemID, etc.)
    @MainActor
    public func dynamicIntValue(
        forKey key: PropertyID,
        owner: Any,
        gameState: GameState
    ) -> Int? {
        guard let property = getDynamicProperty(key) else { return nil }
        guard case .int = property.storedValue else { return nil } // Check initial type
        return try? property.currentValue(owner: owner, gameState: gameState).toInt
    }

    // TODO: Add similar convenience accessors for other common StateValue types (String, ItemID, etc.)

    // Note: Setting requires the @MainActor mutating func setDynamicPropertyValue directly,
    // as we need the mutation and error handling.
}
