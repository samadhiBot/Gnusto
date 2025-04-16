import Foundation

/// Type alias for Fuse identifiers.
public typealias FuseID = String

/// Stores definitions for various game elements like Fuses and Daemons.
/// This registry allows the engine to look up definitions by their IDs.
public struct GameDefinitionRegistry {
    /// Dictionary mapping Fuse IDs to their definitions.
    private let fuseDefinitions: [FuseID: FuseDefinition]

    /// Dictionary mapping Daemon IDs to their definitions.
    private let daemonDefinitions: [DaemonID: DaemonDefinition]

    /// Initializes the registry with fuse and daemon definitions.
    /// - Parameters:
    ///   - fuseDefinitions: An array of `FuseDefinition`s.
    ///   - daemonDefinitions: An array of `DaemonDefinition`s. Defaults to empty.
    public init(
        fuseDefinitions: [FuseDefinition] = [],
        daemonDefinitions: [DaemonDefinition] = []
    ) {
        // Build dictionaries from arrays for efficient lookup
        self.fuseDefinitions = Dictionary(uniqueKeysWithValues: fuseDefinitions.map { ($0.id, $0) })
        self.daemonDefinitions = Dictionary(uniqueKeysWithValues: daemonDefinitions.map { ($0.id, $0) })
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
}
