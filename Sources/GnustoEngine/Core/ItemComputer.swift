/// A sendable compute handler for dynamic item properties.
///
/// `ItemComputer` encapsulates the logic for computing dynamic values for item properties
/// using a declarative result builder approach.
///
/// Example:
/// ```swift
/// static let magicSwordComputer = ItemComputer(for: .magicSword) {
///     itemProperty(.description) { context in
///         let enchantment = context.item.properties[.enchantmentLevel]?.intValue ?? 0
///         let playerLevel = await context.gameState.value(of: .playerLevel) ?? 1
///         return .string(enchantment > playerLevel ? "Blazing sword!" : "Glowing blade")
///     }
///
///     itemProperty(.weight) { context in
///         let enchantment = context.item.properties[.enchantmentLevel]?.intValue ?? 0
///         return .int(10 + enchantment) // Enchanted weapons are heavier
///     }
/// }
/// ```
public struct ItemComputer: Sendable {
    public let compute: @Sendable (ItemComputeContext) async -> StateValue?

    /// Creates a new ItemComputer with a compute closure.
    ///
    /// - Parameter compute: The function that computes property values for an item.
    ///   Returns `nil` if the property is not handled by this computer.
    public init(compute: @escaping @Sendable (ItemComputeContext) async -> StateValue?) {
        self.compute = compute
    }

    /// Initializes an `ItemComputer` with a result builder that provides declarative property matching.
    ///
    /// This is the recommended approach that eliminates the need for switch statements.
    ///
    /// - Parameters:
    ///   - itemID: The ID of the item this computer is for
    ///   - matchers: A result builder that creates a list of property matchers
    ///
    /// Example usage:
    /// ```swift
    /// static let magicSwordComputer = ItemComputer(for: .magicSword) {
    ///     itemProperty(.description) { context in
    ///         let enchantment = await context.item.enchantmentLevel
    ///         return .string(enchantment > 5 ? "Blazing sword!" : "Glowing blade")
    ///     }
    ///
    ///     itemProperty(.weight, .size) { context in
    ///         let enchantment = await context.item.enchantmentLevel
    ///         return .int(10 + enchantment)
    ///     }
    /// }
    /// ```
    public init(
        for itemID: ItemID,
        @ItemComputeMatcherBuilder _ matchers: @Sendable @escaping () async -> [ItemComputeMatcher]
    ) {
        self.compute = { context in
            let matcherList = await matchers()
            for matcher in matcherList {
                if let result = await matcher(context) {
                    return result
                }
            }
            return nil
        }
    }
}

// MARK: - Property Matching Result Builder

/// A type alias for context-aware item property matcher functions.
public typealias ItemComputeMatcher = (ItemComputeContext) async -> StateValue?

/// Result builder for creating clean, declarative item property computing.
///
/// This builder allows you to write item computers in a declarative way:
/// ```swift
/// static let magicSwordComputer = ItemComputer(for: .magicSword) {
///     itemProperty(.description) { context in
///         let enchantment = await context.item.enchantmentLevel
///         return .string(enchantment > 5 ? "Blazing sword!" : "Glowing blade")
///     }
///
///     itemProperty(.weight, .size) { context in
///         let enchantment = await context.item.enchantmentLevel
///         return .int(10 + enchantment)
///     }
/// }
/// ```
@resultBuilder
public struct ItemComputeMatcherBuilder {
    /// Builds a block of item compute matchers into an array.
    ///
    /// This is the core building block of the result builder that combines multiple
    /// `ItemComputeMatcher` functions into a single array for processing.
    ///
    /// - Parameter matchers: Variable number of matcher functions
    /// - Returns: An array containing all the provided matchers
    public static func buildBlock(_ matchers: ItemComputeMatcher...) -> [ItemComputeMatcher] {
        Array(matchers)
    }
}

// MARK: - Item Compute Matcher Builder Functions

/// Creates an item property matcher for the specified properties.
///
/// - Parameters:
///   - properties: The properties to match against
///   - result: The closure to execute if any property matches, receiving the context
/// - Returns: An ItemComputeMatcher that can be used in the result builder
public func itemProperty(
    _ properties: ItemPropertyID...,
    result: @escaping (ItemComputeContext) async -> StateValue?
) -> ItemComputeMatcher {
    { context in
        if properties.contains(context.propertyID) {
            await result(context)
        } else {
            nil
        }
    }
}
