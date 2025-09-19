import CustomDump
import Foundation

/// A lightweight proxy that provides dynamic property access for locations through the GameEngine.
///
/// `LocationProxy` wraps a `Location` and `GameEngine` reference, ensuring all property access
/// goes through the engine's `fetchStateValue()` methods. This guarantees that both static
/// properties and dynamic computed values are properly resolved.
///
/// Use `LocationProxy` in action handlers and game logic instead of raw `Location` structs to ensure
/// consistent behavior when properties may be dynamically computed.
public struct LocationProxy: Sendable, Identifiable {
    /// The location this proxy represents.
    let location: Location

    /// The game engine used for dynamic property resolution.
    let engine: GameEngine

    init(location: Location, engine: GameEngine) {
        self.location = location
        self.engine = engine
    }

    /// The unique identifier of the location this proxy represents.
    ///
    /// This provides direct access to the underlying location's ID for use in
    /// comparisons, lookups, and debugging. The ID is immutable and serves
    /// as the primary key for the location in the game state.
    public var id: LocationID {
        location.id
    }

    /// Retrieves the value of a specific property for this location.
    ///
    /// This method first checks if there's a dynamic computer registered for this location
    /// that can provide a computed value for the property. If no computer exists or
    /// the computer doesn't handle this property, it falls back to the static value
    /// stored in the location's properties dictionary.
    ///
    /// This ensures that both static properties (defined at location creation) and dynamic
    /// properties (computed based on game state) are handled transparently.
    ///
    /// The method includes circular dependency detection to prevent infinite recursion
    /// when location properties depend on each other's computed values.
    ///
    /// - Parameter propertyID: The identifier of the property to retrieve.
    /// - Returns: The property value as a `StateValue`, or `nil` if the property is not set.
    public func property(_ propertyID: LocationPropertyID) async -> StateValue? {
        // Create a unique computation key
        let computationKey = PropertyComputationTracker.key(for: id, property: propertyID)

        // Check for circular dependency
        if PropertyComputationTracker.isActive(computationKey) {
            // Circular dependency detected - fall back to static value
            return await engine.gameState.locations[id]?.properties[propertyID]
        }

        // Check if we have a computer for this location
        guard let computer = await engine.locationComputers[id] else {
            return await engine.gameState.locations[id]?.properties[propertyID]
        }

        // Compute with tracking
        return await PropertyComputationTracker.withTracking(computationKey) {
            guard
                let computedValue = await computer.compute(
                    LocationComputeContext(
                        propertyID: propertyID,
                        location: location,
                        engine: engine
                    )
                )
            else {
                return await engine.gameState.locations[id]?.properties[propertyID]
            }

            return computedValue
        }
    }
}

// MARK: - Convenience Extensions

extension GameEngine {
    /// Creates an `LocationProxy` for the `Location` with the specified ID.
    ///
    /// If the location is not found in the game state, this method will trigger an assertion failure
    /// in debug builds and return a placeholder `LocationProxy` with an empty location. This allows
    /// the game to continue running in release builds while alerting developers to missing location
    /// references during development.
    ///
    /// - Parameter locationID: The unique identifier of the location.
    /// - Returns: An `LocationProxy` instance for dynamic property access.
    public func location(_ locationID: LocationID) -> LocationProxy {
        guard let location = gameState.locations[locationID] else {
            assertionFailure("GameEngine.location(\(locationID)): Location not found")
            return LocationProxy(location: Location(id: locationID), engine: self)
        }
        return LocationProxy(location: location, engine: self)
    }
}

// MARK: - Conformances

extension LocationProxy: Comparable {
    public static func < (lhs: LocationProxy, rhs: LocationProxy) -> Bool {
        lhs.id < rhs.id
    }
}

extension LocationProxy: CustomDumpStringConvertible {
    public var customDumpDescription: String {
        var target = ""
        customDump(location, to: &target)
        return target
    }
}

extension LocationProxy: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: LocationProxy, rhs: LocationProxy) -> Bool {
        lhs.id == rhs.id
    }
}
