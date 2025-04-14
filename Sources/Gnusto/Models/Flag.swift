import Foundation

/// Represents various boolean properties or states of an object.
/// Raw values are used for saving/loading and potentially debugging.
public enum Flag: String, Hashable, Sendable, Codable {
    // Basic Physical Properties

    /// Can hold other objects (requires ContainerComponent).
    case container

    /// Can be turned on/off (requires LightSourceComponent or similar).
    case device

    /// Can be eaten.
    case edible

    /// Large, usually unmovable item.
    case furniture

    /// Provides light when on (requires LightSourceComponent).
    case lightSource

    /// Can be locked and unlocked (usually with a key).
    case lockable

    /// Can be opened and closed (requires ContainerComponent or DoorComponent).
    case openable

    /// Cannot be taken, often part of the room description.
    case scenery

    /// Can have objects placed on it (requires ContainerComponent with isSurface=true).
    case surface

    /// Alias for device.
    case switchable

    /// Can be picked up by the player.
    case takeable

    /// Is  transparent.
    case transparent

    /// Can be entered or ridden.
    case vehicle

    /// Can be worn by the player.
    case wearable

    /// Can be read (requires ReadableComponent or text property).
    case readable

    // State Flags

    /// Is a door (likely implies openable, may imply lockable).
    case door

    /// Is inside a container or vehicle.
    case inside

    /// Is currently emitting light (usually requires .lightSource).
    case light

    /// Is currently locked (requires .lockable).
    case locked

    /// Is currently switched on (requires .device/.switchable).
    case on

    /// Is currently open (requires .openable).
    case open

    /// Contents are not visible even when open (e.g., a cloth sack).
    case opaque

    /// Currently being worn by the player (requires .wearable).
    case worn

    // Gameplay/Meta Flags

    /// The room has been visited by the player.
    case visited

    /// The NPC has been talked to.
    case talkedTo

    // Note: The `custom` case is removed as String raw values cover this.
    // If truly distinct custom flags are needed beyond simple strings,
    // consider a different mechanism or a dedicated component.
}
