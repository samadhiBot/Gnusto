import Foundation

/// Represents a direction of movement or a connection between locations.
public enum Direction: String, CaseIterable, Equatable, Sendable {
    /// North direction.
    case north

    /// Northeast direction.
    case northeast

    /// East direction.
    case east

    /// Southeast direction.
    case southeast

    /// South direction.
    case south

    /// Southwest direction.
    case southwest

    /// West direction.
    case west

    /// Northwest direction.
    case northwest

    /// Upward direction.
    case up

    /// Downward direction.
    case down

    /// Direction indicating movement into something.
    case `in`

    /// Direction indicating movement out of something.
    case out

    /// Creates a `Direction` from a string, handling common names, abbreviations,
    /// and case variations. Returns `nil` if the string doesn't match a known direction.
    ///
    /// This initializer is more robust than using the raw value initializer directly,
    /// as it checks both full names and standard abbreviations.
    ///
    /// - Parameter string: The input string representing a direction (e.g., "north", "ne", "UP").
    /// - Returns: The corresponding `Direction` case, or `nil` if no match is found.
    public init?(_ string: String) {
        let normalizedString = string.lowercased()

        // Check full names first (using raw values)
        if let direction = Direction(rawValue: normalizedString) {
            self = direction
            return
        }

        // Check standard abbreviations
        switch normalizedString {
        case "n": self = .north
        case "ne": self = .northeast
        case "e": self = .east
        case "se": self = .southeast
        case "s": self = .south
        case "sw": self = .southwest
        case "w": self = .west
        case "nw": self = .northwest
        case "u": self = .up
        case "d": self = .down
        default: return nil
        }
    }

    /// Provides the common abbreviation for the direction.
    ///
    /// For standard directions, this returns the lowercase abbreviation (e.g., "n", "ne").
    /// For `.in` and `.out`, it returns the full name.
//    public var abbreviation: String {
//        switch self {
//        case .north: "n"
//        case .northeast: "ne"
//        case .east: "e"
//        case .southeast: "se"
//        case .south: "s"
//        case .southwest: "sw"
//        case .west: "w"
//        case .northwest: "nw"
//        case .up: "u"
//        case .down: "d"
//        case .in: "in"
//        case .out: "out"
//        }
//    }

    /// Returns the direction directly opposite to this one.
    /// For example, the opposite of `.north` is `.south`.
    public var opposite: Direction {
        switch self {
        case .north: .south
        case .northeast: .southwest
        case .east: .west
        case .southeast: .northwest
        case .south: .north
        case .southwest: .northeast
        case .west: .east
        case .northwest: .southeast
        case .up: .down
        case .down: .up
        case .in: .out
        case .out: .in
        }
    }
}
