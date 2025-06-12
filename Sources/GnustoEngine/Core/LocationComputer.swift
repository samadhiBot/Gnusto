/// A sendable compute handler for dynamic location attributes.
///
/// `LocationComputer` encapsulates the logic for computing dynamic values for location attributes.
/// It provides a single compute function that handles multiple attributes through switching.
///
/// Example usage:
/// ```swift
/// static let enchantedForestComputer = LocationComputer { attributeID, gameState in
///     switch attributeID {
///     case .description:
///         let timeOfDay = try gameState.value(of: .timeOfDay) ?? "day"
///         return .string(timeOfDay == "night" ? "Dark woods loom." : "Sunlight filters through trees.")
///     default:
///         return nil
///     }
/// }
/// ```
public struct LocationComputer: Sendable {
    public let compute: @Sendable (LocationAttributeID, GameState) async throws -> StateValue?

    /// Creates a new LocationComputer with the given compute function.
    ///
    /// - Parameter compute: The function that computes attribute values for a location.
    ///   Returns `nil` if the attribute is not handled by this computer.
    public init(
        compute: @escaping @Sendable (LocationAttributeID, GameState) async throws -> StateValue?
    ) {
        self.compute = compute
    }
}
