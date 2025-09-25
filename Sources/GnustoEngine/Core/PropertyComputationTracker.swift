/// Unified property computation tracking using task-local storage.
///
/// `PropertyComputationTracker` uses Swift's `@TaskLocal` storage to track active property
/// computations. This eliminates the need for explicit begin/end tracking and async cleanup,
/// as the task-local storage automatically manages the computation scope.
///
/// The tracker creates unique computation keys for both item and location properties,
/// allowing unified tracking across the entire computation chain. When a circular
/// dependency is detected, the system gracefully falls back to static values.
///
/// Example usage:
/// ```swift
/// // In ItemProxy.property(_:)
/// let computationKey = PropertyComputationTracker.key(for: id, property: propertyID)
/// guard !PropertyComputationTracker.isActive(computationKey) else {
///     return staticValue // Circular dependency - use fallback
/// }
///
/// return try await PropertyComputationTracker.$activeComputations.withValue(
///     PropertyComputationTracker.activeComputations.union([computationKey])
/// ) {
///     // Perform computation within tracked scope
///     return try await computer.compute(context)
/// }
/// ```
enum PropertyComputationTracker {
    /// Task-local storage for tracking active property computations across the call chain.
    ///
    /// This set contains unique computation keys for all currently active property
    /// computations, automatically managing scope through Swift's task-local storage.
    @TaskLocal static var activeComputations: Set<String> = []

    /// Creates a unique computation key for an item property.
    ///
    /// The key format ensures no conflicts between item and location properties
    /// while remaining human-readable for debugging.
    ///
    /// - Parameters:
    ///   - itemID: The item whose property is being computed
    ///   - propertyID: The specific property being computed
    /// - Returns: A unique string key for this computation
    static func key(for itemID: ItemID, property propertyID: ItemPropertyID) -> String {
        "item:\(itemID.rawValue):\(propertyID.rawValue)"
    }

    /// Creates a unique computation key for a location property.
    ///
    /// The key format ensures no conflicts between item and location properties
    /// while remaining human-readable for debugging.
    ///
    /// - Parameters:
    ///   - locationID: The location whose property is being computed
    ///   - propertyID: The specific property being computed
    /// - Returns: A unique string key for this computation
    static func key(for locationID: LocationID, property propertyID: LocationPropertyID) -> String {
        "location:\(locationID.rawValue):\(propertyID.rawValue)"
    }

    /// Checks if a computation is currently active.
    ///
    /// - Parameter computationKey: The computation key to check
    /// - Returns: `true` if this computation is already in progress, indicating a circular dependency
    static func isActive(_ computationKey: String) -> Bool {
        activeComputations.contains(computationKey)
    }

    /// Executes a computation within a tracked scope.
    ///
    /// This method adds the computation key to the active set, executes the computation,
    /// and automatically removes the key when the computation completes (success or failure).
    ///
    /// - Parameters:
    ///   - computationKey: The unique key for this computation
    ///   - computation: The async computation to perform
    /// - Returns: The result of the computation
    /// - Throws: Any error thrown by the computation
    static func withTracking<T>(
        _ computationKey: String,
        perform computation: () async throws -> T
    ) async rethrows -> T {
        try await $activeComputations.withValue(
            activeComputations.union([computationKey])
        ) {
            try await computation()
        }
    }
}
