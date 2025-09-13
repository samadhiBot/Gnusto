import CustomDump
import Foundation

/// A lightweight proxy that provides dynamic property access for items through the GameEngine.
///
/// `ItemProxy` wraps an `Item` and `GameEngine` reference, ensuring all property access
/// goes through the engine's `fetchStateValue()` methods. This guarantees that both static
/// properties and dynamic computed values are properly resolved.
///
/// Use `ItemProxy` in action handlers and game logic instead of raw `Item` structs to ensure
/// consistent behavior when properties may be dynamically computed.
public struct ItemProxy: Sendable, Identifiable {
    /// The item this proxy represents.
    let item: Item

    /// The game engine used for dynamic property resolution.
    let engine: GameEngine

    init(item: Item, engine: GameEngine) {
        self.item = item
        self.engine = engine
    }

    /// The unique identifier of the item this proxy represents.
    ///
    /// This provides direct access to the underlying item's ID for use in
    /// comparisons, lookups, and debugging. The ID is immutable and serves
    /// as the primary key for the item in the game state.
    public var id: ItemID {
        item.id
    }

    /// Retrieves the value of a specific property for this item.
    ///
    /// This method first checks if there's a dynamic computer registered for this item
    /// that can provide a computed value for the property. If no computer exists or
    /// the computer doesn't handle this property, it falls back to the static value
    /// stored in the item's properties dictionary.
    ///
    /// This ensures that both static properties (defined at item creation) and dynamic
    /// properties (computed based on game state) are handled transparently.
    ///
    /// The method includes circular dependency detection to prevent infinite recursion
    /// when item properties depend on each other's computed values.
    ///
    /// - Parameter propertyID: The identifier of the property to retrieve.
    /// - Returns: The property value as a `StateValue`, or `nil` if the property is not set.
    /// - Throws: `ActionResponse.circularDependency` if a computation cycle is detected.
    /// - Throws: An error if there's an issue accessing the computed value.
    public func property(_ propertyID: ItemPropertyID) async throws -> StateValue? {
        // Create a unique computation key
        let computationKey = PropertyComputationTracker.key(for: id, property: propertyID)

        // Check for circular dependency
        if PropertyComputationTracker.isActive(computationKey) {
            // Circular dependency detected - fall back to static value
            return await engine.gameState.items[id]?.properties[propertyID]
        }

        // Check if we have a computer for this item
        guard let computer = await engine.itemComputers[id] else {
            return await engine.gameState.items[id]?.properties[propertyID]
        }

        // Compute with tracking
        return try await PropertyComputationTracker.withTracking(computationKey) {
            guard
                let computedValue = try await computer.compute(
                    ItemComputeContext(
                        propertyID: propertyID,
                        item: item,
                        engine: engine
                    )
                )
            else {
                return await engine.gameState.items[id]?.properties[propertyID]
            }

            return computedValue
        }
    }
}

// MARK: - Convenience Extensions

extension GameEngine {
    /// Creates an `ItemProxy` for the specified item ID.
    ///
    /// - Parameter itemID: The unique identifier of the item.
    /// - Returns: An `ItemProxy` instance for dynamic property access.
    public func item(_ itemID: ItemID) async throws -> ItemProxy {
        guard let item = gameState.items[itemID] else {
            throw ActionResponse.unknownItem(itemID)
        }
        return ItemProxy(item: item, engine: self)
    }
}

// MARK: - Conformances

extension ItemProxy: Comparable {
    public static func < (lhs: ItemProxy, rhs: ItemProxy) -> Bool {
        lhs.id < rhs.id
    }
}

extension ItemProxy: CustomDumpStringConvertible {
    public var customDumpDescription: String {
        var target = ""
        customDump(item, to: &target)
        return target
    }
}

extension ItemProxy: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(item)
    }

    public static func == (lhs: ItemProxy, rhs: ItemProxy) -> Bool {
        lhs.item == rhs.item
    }
}
