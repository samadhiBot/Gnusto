import Foundation

/// Defines the foundational structure and core components of a Gnusto-powered game.
///
/// With the macro system, creating a game is now incredibly simple - just specify
/// your game's metadata and let the macros discover everything else automatically.
///
/// ## Traditional Implementation
/// ```swift
/// struct MyGame: GameBlueprint {
///     var constants: GameConstants { ... }
///     var areas: [any AreaBlueprint.Type] { [Act1Area.self, Act2Area.self] }
///     var player: Player { Player(in: .startingRoom) }
/// }
/// ```
///
/// ## Macro-Based Implementation (Recommended)
/// ```swift
/// @GameBlueprint(
///     title: "My Adventure",
///     introduction: "Welcome to my game...",
///     maxScore: 100,
///     startingLocation: .startingRoom
/// )
/// struct MyGame {
///     // Everything else discovered automatically!
/// }
/// ```
public protocol GameBlueprint: Sendable {
    /// The core metadata constants for the game.
    ///
    /// Provide an instance of `GameConstants` here, which includes details like
    /// the story title, introduction, release information, and maximum score.
    /// This information is often displayed to the player at the start of the game.
    var constants: GameConstants { get }
    
    /// The game areas that define your world.
    /// 
    /// With the `@GameBlueprint` macro, this is automatically populated by
    /// convention-based discovery of all `*Area` types in your module.
    var areas: [any AreaBlueprint.Type] { get }
    
    /// The initial player state.
    var player: Player { get }
    
    /// Optional: Custom action handlers to override engine defaults.
    var customActionHandlers: [VerbID: ActionHandler] { get }
    
    /// Optional: Global state values to initialize the game with.
    var globalState: [GlobalID: StateValue] { get }
}

// MARK: - Automatic Generation

extension GameBlueprint {
    /// Default implementation for custom action handlers.
    public var customActionHandlers: [VerbID: ActionHandler] { [:] }
    
    /// Default implementation for global state.
    public var globalState: [GlobalID: StateValue] { [:] }
    
    /// Automatically generated GameState from the specified areas and player.
    public var state: GameState {
        GameState(
            areas: areas,
            player: player,
            globalState: globalState
        )
    }
    
    /// Automatically aggregated item event handlers from all areas.
    public var itemEventHandlers: [ItemID: ItemEventHandler] {
        areas.reduce(into: [:]) { result, areaType in
            result.merge(areaType.itemEventHandlers) { _, new in new }
        }
    }
    
    /// Automatically aggregated location event handlers from all areas.
    public var locationEventHandlers: [LocationID: LocationEventHandler] {
        areas.reduce(into: [:]) { result, areaType in
            result.merge(areaType.locationEventHandlers) { _, new in new }
        }
    }
    
    /// Automatically aggregated time registry from all areas.
    public var timeRegistry: TimeRegistry {
        let allFuses = areas.reduce(into: [:]) { result, areaType in
            result.merge(areaType.fuseDefinitions) { _, new in new }
        }
        
        let allDaemons = areas.reduce(into: [:]) { result, areaType in
            result.merge(areaType.daemonDefinitions) { _, new in new }
        }
        
        return TimeRegistry(
            fuseDefinitions: allFuses,
            daemonDefinitions: allDaemons
        )
    }
    
    /// Automatically aggregated dynamic attribute registry from all areas.
    public var dynamicAttributeRegistry: DynamicAttributeRegistry {
        areas.reduce(into: DynamicAttributeRegistry()) { result, areaType in
            result.merge(areaType.dynamicAttributeRegistry)
        }
    }
}
