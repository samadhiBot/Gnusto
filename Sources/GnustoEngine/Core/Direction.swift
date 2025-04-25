/// Represents possible directions of movement or connection between locations.
public enum Direction: String, CaseIterable, Codable, Hashable, Sendable {
    case north
    case south
    case east
    case west
    case northeast
    case northwest
    case southeast
    case southwest
    case up
    case down
    case `in`
    case out

    // TODO: Consider adding LAND if needed for flying/swimming contexts?
}
