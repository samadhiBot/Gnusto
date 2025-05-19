import Foundation

/// A central repository for game-specific definitions, such as timed events
/// (`FuseDefinition`, `DaemonDefinition`) and potentially other extensible game elements.
///
/// The `GameEngine` uses the `TimeRegistry` to look up the behavior of fuses
/// and daemons when they are activated or triggered. This registry is typically populated
/// once when the game is initialized, often as part of constructing a `GameBlueprint`.
///
/// While game developers provide the definitions, they usually don't interact with the
/// `TimeRegistry` directly after the game has started. However, its structure
/// clarifies how these definitions are stored and accessed by the engine.
public struct TimeRegistry: Sendable {
    /// A dictionary mapping `FuseID`s to their corresponding `FuseDefinition`s.
    /// These define timed events that can be triggered in the game.
    public let fuseDefinitions: [FuseID: FuseDefinition]

    /// A dictionary mapping `DaemonID`s to their corresponding `DaemonDefinition`s.
    /// These define background tasks or routines that run periodically.
    public let daemonDefinitions: [DaemonID: DaemonDefinition]

    /// Initializes a new `TimeRegistry` with the provided collections of
    /// fuse and daemon definitions.
    ///
    /// Game developers typically provide arrays of these definitions when creating a
    /// `GameBlueprint`, which then constructs the `TimeRegistry`.
    ///
    /// - Parameters:
    ///   - fuseDefinitions: An array of `FuseDefinition`s to be registered.
    ///                    Defaults to an empty array.
    ///   - daemonDefinitions: An array of `DaemonDefinition`s to be registered.
    ///                      Defaults to an empty array.
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
