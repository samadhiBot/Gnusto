import Foundation

/// Type alias for Fuse identifiers.
public typealias FuseID = String

/// Stores definitions for various game elements like Fuses, Daemons, and custom action handlers.
/// This registry allows the engine to look up definitions by their IDs.
public struct GameDefinitionRegistry {
    /// Dictionary mapping Fuse IDs to their definitions.
    private let fuseDefinitions: [FuseID: FuseDefinition]

    /// Dictionary mapping Daemon IDs to their definitions.
    private let daemonDefinitions: [DaemonID: DaemonDefinition]

    /// Handlers triggered when an action targets a specific item ID.
    /// Public access needed for game setup to register handlers.
    public let objectActionHandlers: [ItemID: ObjectActionHandler]

    /// Handlers triggered by events occurring within a specific location ID.
    public let roomActionHandlers: [LocationID: RoomActionHandler]

    /// Initializes the registry with definitions and handlers.
    /// - Parameters:
    ///   - fuseDefinitions: An array of `FuseDefinition`s. Defaults to empty.
    ///   - daemonDefinitions: An array of `DaemonDefinition`s. Defaults to empty.
    ///   - objectActionHandlers: A dictionary of item-specific action handlers. Defaults to empty.
    ///   - roomActionHandlers: A dictionary of location-specific action handlers. Defaults to empty.
    public init(
        fuseDefinitions: [FuseDefinition] = [],
        daemonDefinitions: [DaemonDefinition] = [],
        objectActionHandlers: [ItemID: ObjectActionHandler] = [:],
        roomActionHandlers: [LocationID: RoomActionHandler] = [:]
    ) {
        // Build dictionaries from arrays for efficient lookup
        self.fuseDefinitions = Dictionary(uniqueKeysWithValues: fuseDefinitions.map { ($0.id, $0) })
        self.daemonDefinitions = Dictionary(uniqueKeysWithValues: daemonDefinitions.map { ($0.id, $0) })
        self.objectActionHandlers = objectActionHandlers
        self.roomActionHandlers = roomActionHandlers
    }

    /// Retrieves a `FuseDefinition` by its ID.
    /// - Parameter id: The `FuseID` to look up.
    /// - Returns: The `FuseDefinition` if found, otherwise `nil`.
    internal func fuseDefinition(for id: FuseID) -> FuseDefinition? {
        fuseDefinitions[id]
    }

    /// Retrieves a `DaemonDefinition` by its ID.
    /// - Parameter id: The `DaemonID` to look up.
    /// - Returns: The `DaemonDefinition` if found, otherwise `nil`.
    internal func daemonDefinition(for id: DaemonID) -> DaemonDefinition? {
        daemonDefinitions[id]
    }

    /// Retrieves a `RoomActionHandler` by its ID.
    /// - Parameter id: The `LocationID` to look up.
    /// - Returns: The `RoomActionHandler` if found, otherwise `nil`.
    internal func roomActionHandler(for id: LocationID) -> RoomActionHandler? {
        roomActionHandlers[id]
    }
}
