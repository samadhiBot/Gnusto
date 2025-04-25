/// Represents conditions that a noun phrase must meet to match a syntax pattern.
/// Using an OptionSet allows combining multiple conditions.
public struct ObjectCondition: OptionSet, Sendable {
    public let rawValue: Int

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
