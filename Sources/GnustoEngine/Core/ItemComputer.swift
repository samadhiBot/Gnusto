/// A sendable compute handler for dynamic item attributes.
///
/// `ItemComputer` encapsulates the logic for computing dynamic values for item attributes.
/// It provides a single compute function that handles multiple attributes through switching.
///
/// Example usage:
/// ```swift
/// static let magicSwordComputer = ItemComputer { attributeID, gameState in
///     switch attributeID {
///     case .description:
///         let enchantment = try gameState.value(of: .enchantmentLevel, on: .magicSword) ?? 0
///         return .string(enchantment > 5 ? "Blazing sword!" : "Glowing blade")
///     default:
///         return nil
///     }
/// }
/// ```
public struct ItemComputer: Sendable {
    public let compute: @Sendable (AttributeID, GameState) async throws -> StateValue?

    /// Creates a new ItemComputer with the given compute function.
    ///
    /// - Parameter compute: The function that computes attribute values for an item.
    ///   Returns `nil` if the attribute is not handled by this computer.
    public init(compute: @escaping @Sendable (AttributeID, GameState) async throws -> StateValue?) {
        self.compute = compute
    }
}
