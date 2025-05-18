/// Represents conditions that a noun phrase (representing a direct or indirect object)
/// must meet to successfully match a `SyntaxRule` during command parsing.
///
/// `ObjectCondition` is an `OptionSet`, allowing multiple conditions to be combined.
/// For example, a rule might require an object to be both `.held` by the player
/// and be a `.container`.
///
/// These conditions are typically checked by the parser after it tentatively identifies
/// an item based on the player's input. If the conditions are not met, that syntax
/// rule will not match, and the parser may try other rules or report a `ParseError`.
public struct ObjectCondition: OptionSet, Sendable {
    public let rawValue: Int

    /// Creates an `ObjectCondition` with the given raw integer value.
    ///
    /// This initializer is primarily used by the `OptionSet` protocol itself.
    /// You typically create conditions using the static members like `.held` or `.inRoom`,
    /// or by combining them (e.g., `[.held, .container]`).
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// No specific conditions.
    public static let none = ObjectCondition([])
    /// The resolved item must be held by the player.
    public static let held = ObjectCondition(rawValue: 1 << 0)
    /// The resolved item must be in the current room (directly or globally).
    public static let inRoom = ObjectCondition(rawValue: 1 << 1)
    /// The resolved item must be on the ground (directly in the room, not in inventory or container).
    public static let onGround = ObjectCondition(rawValue: 1 << 2)
    /// The resolved item must have a specific property (e.g., TAKEBIT).
    // We can't store the associated value directly in OptionSet, handle separately or use enum later.
    // For now, handlers might check properties after resolution based on verb.
    // public static let requiresProperty = ObjectCondition(rawValue: 1 << 3)
    /// The syntax allows multiple objects (e.g., TAKE ALL).
    public static let allowsMultiple = ObjectCondition(rawValue: 1 << 4)
    /// The resolved item must be an NPC/Person.
    public static let person = ObjectCondition(rawValue: 1 << 5)
    /// The resolved item must be a container.
    public static let container = ObjectCondition(rawValue: 1 << 6)
    /// The resolved item must currently be worn by the player.
    public static let worn = ObjectCondition(rawValue: 1 << 7)

    // Add more conditions as needed (e.g., VILLAIN, WEAPONBIT from Zork)
}
