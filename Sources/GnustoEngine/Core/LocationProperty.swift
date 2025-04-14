/// Represents various properties or flags that a location can possess.
public enum LocationProperty: String, Codable, CaseIterable, Sendable {
    // Alphabetized cases based on common IF needs and ZIL flags

    /// The location is currently illuminated.
    case lit = "lit"

    /// Magic does not function in this location.
    case noMagic = "noMagic"

    /// The location is considered outdoors.
    case outside = "outside"

    /// Profanity is discouraged or disallowed here.
    case sacred = "sacred"

    /// The player has visited this location previously.
    case visited = "visited"

    /// The location contains or is primarily composed of water.
    case water = "water"

    /// The location is dark unless player has light.
    case dark = "dark"
}
