import Foundation

/// Represents universal concepts that are implicitly present in interactive fiction
/// but don't need to be explicitly modeled as Item objects.
///
/// Whether this universal represents something handle common nouns that players might reference. across
/// different locations without requiring game developers to create explicit
/// items for every possible interaction. Examples include "ground", "sky",
/// "ceiling", "walls", etc.
///
/// Action Handlers are the main place where universal objects come into play. During
/// command processing, a handler can support one or more universals when switching on
/// direct object references.
///
/// ## Example Usage
///
/// ```swift
/// // In a `DIG` action handler:
/// public func process(context: ActionContext) async throws -> ActionResult {
///     switch command.directObject {
///     case .item(let targetItemID): ...
///     case .universal(let universal):
///         if Universal.diggableUniversals.contains(universal) {
///             ActionResult(
///                 engine.messenger.digUniversalIneffective()
///             )
///         } else {
///             throw await ActionResponse.feedback(
///                 engine.messenger.cannotDoThat("dig")
///             )
///         }
///     default: ...
///     }
/// }
/// ```
public enum Universal: String, CaseIterable, Sendable, Codable {
    // MARK: - Ground and Earth

    /// The ground, earth, or floor surface
    case ground

    /// Earth, dirt, or soil
    case earth

    /// Soil for digging or planting
    case soil

    /// Dirt or earth material
    case dirt

    /// The floor surface
    case floor

    // MARK: - Sky and Atmosphere

    /// The sky or heavens above
    case sky

    /// The heavens or celestial sphere
    case heavens

    /// Air or atmosphere
    case air

    /// Clouds in the sky
    case clouds

    /// The sun
    case sun

    /// The moon
    case moon

    /// Stars in the sky
    case stars

    // MARK: - Architectural Elements

    /// The ceiling above
    case ceiling

    /// Walls around the location
    case walls

    /// A wall (singular)
    case wall

    /// The roof above
    case roof

    // MARK: - Water Features

    /// Water in general
    case water

    /// A river or stream
    case river

    /// A stream of water
    case stream

    /// A lake or pond
    case lake

    /// A pond of water
    case pond

    /// An ocean or sea
    case ocean

    /// The sea
    case sea

    // MARK: - Natural Elements

    /// Wind or breeze
    case wind

    /// Fire or flames
    case fire

    /// Flames
    case flames

    /// Smoke
    case smoke

    /// Dust particles
    case dust

    /// Mud or muddy ground
    case mud

    /// Sand
    case sand

    /// Rock or stone
    case rock

    /// Stone material
    case stone

    // MARK: - Abstract Concepts

    /// Darkness or shadows
    case darkness

    /// Shadows
    case shadows

    /// Light in general
    case light

    /// Silence or quiet
    case silence

    /// Sound or noise
    case sound

    /// Noise
    case noise

    // MARK: - Properties

    /// The canonical identifier for this universal object
    public var id: String {
        rawValue
    }

    /// A human-readable name for this universal object
    public var displayName: String {
        rawValue.capitalized
    }

    public var withDefiniteArticle: String {
        "the \(rawValue)"
    }
}

extension Universal {
    public func matches(_ other: Universal) -> Bool {
        self.relatedUniversals.contains(other)
    }

    /// Related universal objects that share similar properties or behaviors
    public var relatedUniversals: Set<Universal> {
        switch self {
        case .ground, .floor:
            [.ground, .floor, .earth, .soil, .dirt]
        case .earth, .soil, .dirt:
            [.ground, .earth, .soil, .dirt]
        case .sky, .heavens:
            [.sky, .heavens, .air, .clouds]
        case .air, .clouds:
            [.sky, .air, .clouds]
        case .sun, .moon, .stars:
            [.sun, .moon, .stars, .sky, .heavens]
        case .walls, .wall:
            [.walls, .wall, .ceiling, .floor]
        case .ceiling, .roof:
            [.ceiling, .roof]
        case .water, .river, .stream, .lake, .pond, .ocean, .sea:
            [.water, .river, .stream, .lake, .pond, .ocean, .sea]
        case .wind:
            [.wind, .air]
        case .fire, .flames:
            [.fire, .flames, .smoke, .light]
        case .smoke:
            [.smoke, .fire, .air]
        case .dust, .mud, .sand:
            [.dust, .mud, .sand, .dirt, .earth]
        case .rock, .stone:
            [.rock, .stone, .earth]
        case .darkness, .shadows:
            [.darkness, .shadows]
        case .light:
            [.light, .fire, .flames, .sun]
        case .silence, .sound, .noise:
            [.silence, .sound, .noise]
        }
    }

    /// Whether this universal is typically present in outdoor locations
    public var isOutdoorElement: Bool {
        switch self {
        case .clouds, .dirt, .earth, .heavens, .moon, .sky, .soil, .stars, .sun, .wind:
            true
        case .ceiling, .floor, .roof:
            false
        default:
            false
        }
    }

    /// Whether this universal is typically present in indoor locations
    public var isIndoorElement: Bool {
        switch self {
        case .ceiling, .floor, .roof, .wall, .walls:
            true
        case .heavens, .moon, .sky, .stars, .sun:
            false
        default:
            true
        }
    }

    /// Whether this universal represents something that can be physically interacted with
    public var isPhysical: Bool {
        switch self {
        case .ceiling, .dirt, .earth, .floor, .ground, .lake, .mud, .ocean, .pond, .river,
            .rock, .roof, .sand, .sea, .soil, .stone, .stream, .wall, .walls, .water:
            true
        case .air, .clouds, .darkness, .dust, .fire, .flames, .heavens, .light, .moon, .noise,
            .shadows, .silence, .sky, .smoke, .sound, .stars, .sun, .wind:
            false
        }
    }

    /// Whether this universal represents something commonly found in outdoor environments.
    public var isOutdoors: Bool {
        [
            .air, .clouds, .darkness, .dirt, .dust, .earth, .fire, .flames, .ground, .heavens,
            .lake, .light, .moon, .mud, .ocean, .pond, .river, .rock, .sand, .sea, .shadows,
            .sky, .smoke, .soil, .stars, .stone, .stream, .sun, .water, .wind,
        ]
        .contains(self)
    }

    /// Whether this universal represents something commonly found in indoor environments.
    public var isIndoors: Bool {
        [
            .air, .ceiling, .darkness, .dust, .fire, .flames, .floor, .light, .noise, .roof,
            .shadows, .silence, .smoke, .sound, .wall, .walls, .water,
        ]
        .contains(self)
    }

    /// Whether this universal represents something that represent diggable surfaces.
    public var isDiggable: Bool {
        [
            .dirt, .earth, .ground, .mud, .sand, .soil,
        ]
        .contains(self)
    }

    /// Whether this universal represents something that represent water sources.
    public var isWater: Bool {
        [
            .lake, .ocean, .pond, .river, .sea, .stream, .water,
        ]
        .contains(self)
    }

    /// Whether this universal represents something that represent architectural features.
    public var isArchitectural: Bool {
        [
            .ceiling, .floor, .roof, .wall, .walls,
        ]
        .contains(self)
    }
}

// MARK: - Conformances

extension Universal: Comparable {
    public static func < (lhs: Universal, rhs: Universal) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension Universal: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

// MARK: - Set helpers

extension Set where Element == Universal {
    /// Finds the closest matching Universal to the given raw input string.
    ///
    /// This method first attempts to find an exact match by comparing the raw input
    /// to the raw values of Universals in the set. If no exact match is found,
    /// it returns the first element when the set is sorted alphabetically.
    ///
    /// - Parameter rawInput: The raw string input to match against Universal raw values
    /// - Returns: The matching Universal if found, or the first sorted element as a fallback,
    ///           or nil if the set is empty
    ///
    /// ## Example Usage
    ///
    /// ```swift
    /// let universals: Set<Universal> = [.ground, .sky, .water]
    /// let match = universals.closestMatch(to: "ground") // Returns .ground
    /// let fallback = universals.closestMatch(to: "invalid") // Returns .ground (first sorted)
    /// ```
    public func closestMatch(to rawInput: String) -> Universal? {
        if let exactMatch = first(where: { $0 == Universal(rawValue: rawInput) }) {
            return exactMatch
        }
        return sorted().first
    }
}
