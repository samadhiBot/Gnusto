/// Represents possible directions of movement or connection between locations.
public enum Direction: String, CaseIterable, Codable, Hashable, Sendable {
    case north = "north"
    case south = "south"
    case east = "east"
    case west = "west"
    case northeast = "northeast"
    case northwest = "northwest"
    case southeast = "southeast"
    case southwest = "southwest"
    case up = "up"
    case down = "down"
    case `in` = "in" // Use backticks as 'in' is a keyword
    case out = "out"

    // TODO: Consider adding LAND if needed for flying/swimming contexts?
}
