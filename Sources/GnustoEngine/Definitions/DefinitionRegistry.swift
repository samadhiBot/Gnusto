import Foundation

/// Stores definitions for various game elements like Fuses, Daemons, and custom action handlers.
/// This registry allows the engine to look up definitions by their IDs.
public struct DefinitionRegistry: Sendable {
    /// Dictionary mapping Fuse IDs to their definitions.
    let fuseDefinitions: [FuseID: FuseDefinition]

    /// Dictionary mapping Daemon IDs to their definitions.
    let daemonDefinitions: [DaemonID: DaemonDefinition]

    /// Optional closures to provide custom action handlers for specific verbs,
    /// overriding the default engine handlers.
    let customActionHandlers: [VerbID: ActionHandler]

    /// Handlers triggered when an action targets a specific item ID.
    let itemActionHandlers: [ItemID: ItemActionHandler]

    /// Handlers triggered by events occurring within a specific location ID.
    let locationActionHandlers: [LocationID: LocationActionHandler]

    /// Initializes the registry with definitions and handlers.
    /// - Parameters:
    ///   - fuseDefinitions: An array of `FuseDefinition`s.
    ///   - daemonDefinitions: An array of `DaemonDefinition`s.
    ///   - customActionHandlers: A dictionary of verb-specific custom action handlers.
    ///   - itemActionHandlers: A dictionary of item-specific action handlers.
    ///   - locationActionHandlers: A dictionary of location-specific action handlers.
    public init(
        fuseDefinitions: [FuseDefinition] = [],
        daemonDefinitions: [DaemonDefinition] = [],
        customActionHandlers: [VerbID: ActionHandler] = [:],
        itemActionHandlers: [ItemID: ItemActionHandler] = [:],
        locationActionHandlers: [LocationID: LocationActionHandler] = [:]
    ) {
        self.fuseDefinitions = Dictionary(
            uniqueKeysWithValues: fuseDefinitions.map { ($0.id, $0) }
        )
        self.daemonDefinitions = Dictionary(
            uniqueKeysWithValues: daemonDefinitions.map { ($0.id, $0) }
        )
        self.customActionHandlers = customActionHandlers
        self.itemActionHandlers = itemActionHandlers
        self.locationActionHandlers = locationActionHandlers
    }
}
