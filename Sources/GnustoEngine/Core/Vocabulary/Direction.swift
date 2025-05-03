import Foundation

/// Represents cardinal and other directions used for navigation and spatial representation.
public enum Direction: String, CaseIterable, Codable, Hashable, Sendable {
    case north = "n"
    case northeast = "ne"
    case east = "e"
    case southeast = "se"
    case south = "s"
    case southwest = "sw"
    case west = "w"
    case northwest = "nw"
    case up = "u"
    case down = "d"
    case inside = "in"
    case outside = "out"
}

// MARK: - Comparable
extension Direction: Comparable {
    // Provide a stable sort order, e.g., clockwise from North then other directions
    private var sortOrder: Int {
        switch self {
        case .north: 0
        case .northeast: 1
        case .east: 2
        case .southeast: 3
        case .south: 4
        case .southwest: 5
        case .west: 6
        case .northwest: 7
        case .up: 8
        case .down: 9
        case .inside: 10
        case .outside: 11
        }
    }

    public static func < (lhs: Direction, rhs: Direction) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
