import Foundation

/// Represents universal concepts that are implicitly present in interactive fiction
/// but don't need to be explicitly modeled as Item objects.
///
/// Universal objects handle common nouns that players might reference across
/// different locations without requiring game developers to create explicit
/// items for every possible interaction. Examples include "ground", "sky",
/// "ceiling", "walls", etc.
///
/// ## Integration with Action Handlers
///
/// Action handlers can declare which universals they support by implementing
/// the `handlesUniversal` check. When the parser cannot find a regular object
/// matching the player's input, it falls back to checking universals.
///
/// ## Localization Support
///
/// Universal objects work seamlessly with the existing localization system.
/// Games can provide language-specific mappings through the Vocabulary system,
/// and action handlers can use the MessageProvider for localized responses.
///
/// ## Example Usage
///
/// ```swift
/// // In an action handler:
/// func handlesUniversal(_ universal: UniversalObject) -> Bool {
///     switch universal {
///     case .ground, .earth, .soil:
///         return true
///     default:
///         return false
///     }
/// }
/// ```
public enum UniversalObject: String, CaseIterable, Sendable, Codable {
    // MARK: - Ground and Earth

    /// The ground, earth, or floor surface
    case ground = "ground"

    /// Earth, dirt, or soil
    case earth = "earth"

    /// Soil for digging or planting
    case soil = "soil"

    /// Dirt or earth material
    case dirt = "dirt"

    /// The floor surface
    case floor = "floor"

    // MARK: - Sky and Atmosphere

    /// The sky or heavens above
    case sky = "sky"

    /// The heavens or celestial sphere
    case heavens = "heavens"

    /// Air or atmosphere
    case air = "air"

    /// Clouds in the sky
    case clouds = "clouds"

    /// The sun
    case sun = "sun"

    /// The moon
    case moon = "moon"

    /// Stars in the sky
    case stars = "stars"

    // MARK: - Architectural Elements

    /// The ceiling above
    case ceiling = "ceiling"

    /// Walls around the location
    case walls = "walls"

    /// A wall (singular)
    case wall = "wall"

    /// The roof above
    case roof = "roof"

    // MARK: - Water Features

    /// Water in general
    case water = "water"

    /// A river or stream
    case river = "river"

    /// A stream of water
    case stream = "stream"

    /// A lake or pond
    case lake = "lake"

    /// A pond of water
    case pond = "pond"

    /// An ocean or sea
    case ocean = "ocean"

    /// The sea
    case sea = "sea"

    // MARK: - Natural Elements

    /// Wind or breeze
    case wind = "wind"

    /// Fire or flames
    case fire = "fire"

    /// Flames
    case flames = "flames"

    /// Smoke
    case smoke = "smoke"

    /// Dust particles
    case dust = "dust"

    /// Mud or muddy ground
    case mud = "mud"

    /// Sand
    case sand = "sand"

    /// Rock or stone
    case rock = "rock"

    /// Stone material
    case stone = "stone"

    // MARK: - Abstract Concepts

    /// Darkness or shadows
    case darkness = "darkness"

    /// Shadows
    case shadows = "shadows"

    /// Light in general
    case light = "light"

    /// Silence or quiet
    case silence = "silence"

    /// Sound or noise
    case sound = "sound"

    /// Noise
    case noise = "noise"

    // MARK: - Properties

    /// The canonical identifier for this universal object
    public var id: String {
        return rawValue
    }

    /// A human-readable name for this universal object
    public var displayName: String {
        return rawValue.capitalized
    }

    /// Related universal objects that share similar properties or behaviors
    public var relatedUniversals: Set<UniversalObject> {
        switch self {
        case .ground, .floor:
            return [.ground, .floor, .earth, .soil, .dirt]
        case .earth, .soil, .dirt:
            return [.ground, .earth, .soil, .dirt]
        case .sky, .heavens:
            return [.sky, .heavens, .air, .clouds]
        case .air, .clouds:
            return [.sky, .air, .clouds]
        case .sun, .moon, .stars:
            return [.sun, .moon, .stars, .sky, .heavens]
        case .walls, .wall:
            return [.walls, .wall, .ceiling, .floor]
        case .ceiling, .roof:
            return [.ceiling, .roof]
        case .water, .river, .stream, .lake, .pond, .ocean, .sea:
            return [.water, .river, .stream, .lake, .pond, .ocean, .sea]
        case .wind:
            return [.wind, .air]
        case .fire, .flames:
            return [.fire, .flames, .smoke, .light]
        case .smoke:
            return [.smoke, .fire, .air]
        case .dust, .mud, .sand:
            return [.dust, .mud, .sand, .dirt, .earth]
        case .rock, .stone:
            return [.rock, .stone, .earth]
        case .darkness, .shadows:
            return [.darkness, .shadows]
        case .light:
            return [.light, .fire, .flames, .sun]
        case .silence, .sound, .noise:
            return [.silence, .sound, .noise]
        }
    }

    /// Whether this universal is typically present in outdoor locations
    public var isOutdoorElement: Bool {
        switch self {
        case .sky, .heavens, .clouds, .sun, .moon, .stars, .wind, .earth, .soil, .dirt:
            return true
        case .ceiling, .roof, .floor:
            return false
        default:
            return false
        }
    }

    /// Whether this universal is typically present in indoor locations
    public var isIndoorElement: Bool {
        switch self {
        case .ceiling, .walls, .wall, .floor, .roof:
            return true
        case .sky, .heavens, .sun, .moon, .stars:
            return false
        default:
            return true
        }
    }

    /// Whether this universal represents something that can be physically interacted with
    public var isPhysical: Bool {
        switch self {
        case .ground, .floor, .earth, .soil, .dirt, .walls, .wall, .ceiling, .roof,
            .water, .river, .stream, .lake, .pond, .ocean, .sea, .mud, .sand, .rock, .stone:
            return true
        case .sky, .heavens, .air, .clouds, .sun, .moon, .stars, .wind, .fire, .flames,
            .smoke, .dust, .darkness, .shadows, .light, .silence, .sound, .noise:
            return false
        }
    }
}

/// Extension providing common universal object collections for convenience
extension UniversalObject {
    /// Universal objects commonly found in outdoor environments
    public static let outdoorUniversals: Set<UniversalObject> = [
        .ground, .earth, .soil, .dirt, .sky, .heavens, .air, .clouds,
        .sun, .moon, .stars, .wind, .water, .river, .stream, .lake,
        .pond, .ocean, .sea, .fire, .flames, .smoke, .dust, .mud,
        .sand, .rock, .stone, .darkness, .shadows, .light,
    ]

    /// Universal objects commonly found in indoor environments
    public static let indoorUniversals: Set<UniversalObject> = [
        .floor, .walls, .wall, .ceiling, .roof, .air, .water, .fire,
        .flames, .smoke, .dust, .darkness, .shadows, .light, .silence,
        .sound, .noise,
    ]

    /// Universal objects that represent diggable surfaces
    public static let diggableUniversals: Set<UniversalObject> = [
        .ground, .earth, .soil, .dirt, .mud, .sand,
    ]

    /// Universal objects that represent water sources
    public static let waterUniversals: Set<UniversalObject> = [
        .water, .river, .stream, .lake, .pond, .ocean, .sea,
    ]

    /// Universal objects that represent architectural features
    public static let architecturalUniversals: Set<UniversalObject> = [
        .floor, .walls, .wall, .ceiling, .roof,
    ]
}

extension UniversalObject: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}
