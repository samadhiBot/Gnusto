import Foundation

/// Stores definitions for various game elements like Fuses, Daemons, and custom action handlers.
/// This registry allows the engine to look up definitions by their IDs.
public struct DefinitionRegistry {
    /// Dictionary mapping Fuse IDs to their definitions.
    private let fuseDefinitions: [FuseID: FuseDefinition]

    /// Dictionary mapping Daemon IDs to their definitions.
    private let daemonDefinitions: [DaemonID: DaemonDefinition]

    /// Optional closures to provide custom action handlers for specific verbs,
    /// overriding the default engine handlers.
    public let customActionHandlers: [VerbID: EnhancedActionHandler]

    /// Handlers triggered when an action targets a specific item ID.
    public let objectActionHandlers: [ItemID: ObjectActionHandler]

    /// Handlers triggered by events occurring within a specific location ID.
    public let roomActionHandlers: [LocationID: RoomActionHandler]

    /// Initializes the registry with definitions and handlers.
    /// - Parameters:
    ///   - fuseDefinitions: An array of `FuseDefinition`s.
    ///   - daemonDefinitions: An array of `DaemonDefinition`s.
    ///   - customActionHandlers: A dictionary of verb-specific custom action handlers.
    ///   - objectActionHandlers: A dictionary of item-specific action handlers.
    ///   - roomActionHandlers: A dictionary of location-specific action handlers.
    public init(
        fuseDefinitions: [FuseDefinition] = [],
        daemonDefinitions: [DaemonDefinition] = [],
        customActionHandlers: [VerbID: EnhancedActionHandler] = [:],
        objectActionHandlers: [ItemID: ObjectActionHandler] = [:],
        roomActionHandlers: [LocationID: RoomActionHandler] = [:]
    ) {
        // Build dictionaries from arrays for efficient lookup
        self.fuseDefinitions = Dictionary(
            uniqueKeysWithValues: fuseDefinitions.map { ($0.id, $0) }
        )
        self.daemonDefinitions = Dictionary(
            uniqueKeysWithValues: daemonDefinitions.map { ($0.id, $0) }
        )
        self.customActionHandlers = customActionHandlers
        self.objectActionHandlers = objectActionHandlers
        self.roomActionHandlers = roomActionHandlers
    }

    /// Fetches a `DaemonDefinition` by its ID.
    ///
    /// - Parameter id: The `DaemonID` to look up.
    /// - Returns: The `DaemonDefinition` if found, otherwise `nil`.
    internal func daemonDefinition(for id: DaemonID) -> DaemonDefinition? {
        daemonDefinitions[id]
    }

    /// Fetches a `FuseDefinition` by its ID.
    ///
    /// - Parameter id: The `FuseID` to look up.
    /// - Returns: The `FuseDefinition` if found, otherwise `nil`.
    internal func fuseDefinition(for id: FuseID) -> FuseDefinition? {
        fuseDefinitions[id]
    }

    /// Fetches a `RoomActionHandler` by its ID.
    ///
    /// - Parameter id: The `LocationID` to look up.
    /// - Returns: The `RoomActionHandler` if found, otherwise `nil`.
    internal func roomActionHandler(for id: LocationID) -> RoomActionHandler? {
        roomActionHandlers[id]
    }
}
