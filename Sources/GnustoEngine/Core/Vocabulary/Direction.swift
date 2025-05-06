import Foundation

/// Represents cardinal and other directions used for navigation and spatial representation.
public enum Direction: String, CaseIterable, Codable, Hashable, Sendable {
    case down = "down" 
    case east = "east" 
    case inside = "in" 
    case north = "north" 
    case northeast = "northeast" 
    case northwest = "northwest" 
    case outside = "out" 
    case south = "south" 
    case southeast = "southeast" 
    case southwest = "southwest" 
    case up = "up" 
    case west = "west" 
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
