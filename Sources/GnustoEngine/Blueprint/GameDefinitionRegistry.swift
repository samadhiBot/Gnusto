import Foundation

/// A registry holding static game definitions, such as fuse and daemon behaviors.
///
/// This registry provides the `GameEngine` with the necessary blueprints to
/// reconstruct dynamic game elements (like active fuses) when loading a game state.
public struct GameDefinitionRegistry {
    /// A dictionary mapping fuse IDs to their static definitions.
    private let fuseDefinitions: [Fuse.ID: FuseDefinition]

    /// Initializes a new game definition registry.
    ///
    /// - Parameter fuseDefinitions: An array of `FuseDefinition` objects for the game.
    public init(fuseDefinitions: [FuseDefinition] = []) {
        // Create a dictionary for efficient lookup by ID.
        self.fuseDefinitions = Dictionary(uniqueKeysWithValues: fuseDefinitions.map { ($0.id, $0) })
    }

    /// Retrieves the fuse definition for a given fuse ID.
    ///
    /// - Parameter id: The unique identifier of the fuse.
    /// - Returns: The `FuseDefinition` if found, otherwise `nil`.
    internal func fuseDefinition(for id: Fuse.ID) -> FuseDefinition? {
        fuseDefinitions[id]
    }

    // TODO: Add daemon definitions, handler mappings, etc. as needed.
}
