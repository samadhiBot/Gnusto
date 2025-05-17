import Foundation

/// Stores definitions for various game elements like Fuses, Daemons, and custom action handlers.
/// This registry allows the engine to look up definitions by their IDs.
public struct DefinitionRegistry: Sendable {
    /// Dictionary mapping Fuse IDs to their definitions.
    let fuseDefinitions: [FuseID: FuseDefinition]

    /// Dictionary mapping Daemon IDs to their definitions.
    let daemonDefinitions: [DaemonID: DaemonDefinition]

    /// Initializes the registry with definitions and handlers.
    /// - Parameters:
    ///   - fuseDefinitions: An array of `FuseDefinition`s.
    ///   - daemonDefinitions: An array of `DaemonDefinition`s.
    public init(
        fuseDefinitions: [FuseDefinition] = [],
        daemonDefinitions: [DaemonDefinition] = []
    ) {
        self.fuseDefinitions = Dictionary(
            uniqueKeysWithValues: fuseDefinitions.map { ($0.id, $0) }
        )
        self.daemonDefinitions = Dictionary(
            uniqueKeysWithValues: daemonDefinitions.map { ($0.id, $0) }
        )
    }
}
