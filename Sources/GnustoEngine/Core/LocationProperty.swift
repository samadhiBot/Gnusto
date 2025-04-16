/// Represents various properties or flags that a location can possess.
public enum LocationProperty: String, Codable, CaseIterable, Sendable {
    // Alphabetized cases based on common IF needs and ZIL flags

    /// The location is inherently lit (like outdoors, or a room with windows).
    /// Corresponds to ZIL's RLIGHTBIT.
    /// Rooms without this property are dark unless a light source is present.
    case inherentlyLit

    /// Magic does not function in this location.
    case noMagic

    /// The location is considered outdoors.
    case outside

    /// Profanity is discouraged or disallowed here.
    case sacred

    /// The player has visited this location previously.
    case visited

    /// The location contains or is primarily composed of water.
    case water
}
