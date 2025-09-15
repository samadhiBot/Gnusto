/// A sendable compute handler for dynamic location properties.
///
/// `LocationComputer` encapsulates the logic for computing dynamic values for location properties
/// using a declarative result builder approach.
///
/// Example:
/// ```swift
/// static let enchantedForestComputer = LocationComputer(for: .enchantedForest) {
///     locationProperty(.description) { context in
///         let timeOfDay = try await context.gameState.value(of: .timeOfDay) ?? "day"
///         let weather = context.location.properties[.weather]?.stringValue ?? "clear"
///         return .string(timeOfDay == "night" ? "Dark woods loom." : "Sunlight filters through trees.")
///     }
///     
///     locationProperty(.isLit) { context in
///         let timeOfDay = try await context.gameState.value(of: .timeOfDay) ?? "day"
///         return .bool(timeOfDay == "day")
///     }
/// }
/// ```
public struct LocationComputer: Sendable {
    public let compute: @Sendable (LocationComputeContext) async throws -> StateValue?

    /// Creates a new LocationComputer with a compute closure.
    ///
    /// - Parameter compute: The function that computes property values for a location.
    ///   Returns `nil` if the property is not handled by this computer.
    public init(
        compute: @escaping @Sendable (LocationComputeContext) async throws -> StateValue?
    ) {
        self.compute = compute
    }

    /// Initializes a `LocationComputer` with a result builder that provides declarative property matching.
    ///
    /// This is the recommended approach that eliminates the need for switch statements.
    ///
    /// - Parameters:
    ///   - locationID: The ID of the location this computer is for
    ///   - matchers: A result builder that creates a list of property matchers
    ///
    /// Example usage:
    /// ```swift
    /// static let enchantedForestComputer = LocationComputer(for: .enchantedForest) {
    ///     locationProperty(.description) { context in
    ///         let timeOfDay = try await context.gameState.value(of: .timeOfDay) ?? "day"
    ///         return .string(timeOfDay == "night" ? "Dark woods loom." : "Sunlight filters through trees.")
    ///     }
    ///     
    ///     locationProperty(.isLit) { context in
    ///         let timeOfDay = try await context.gameState.value(of: .timeOfDay) ?? "day"
    ///         return .bool(timeOfDay == "day")
    ///     }
    /// }
    /// ```
    public init(
        for locationID: LocationID,
        @LocationComputeMatcherBuilder _ matchers: @Sendable @escaping () async throws -> [LocationComputeMatcher]
    ) {
        self.compute = { context in
            let matcherList = try await matchers()
            for matcher in matcherList {
                if let result = try await matcher(context) {
                    return result
                }
            }
            return nil
        }
    }
}

// MARK: - Property Matching Result Builder

/// A type alias for context-aware location property matcher functions.
public typealias LocationComputeMatcher = (LocationComputeContext) async throws -> StateValue?

/// Result builder for creating clean, declarative location property computing.
///
/// This builder allows you to write location computers in a declarative way:
/// ```swift
/// static let enchantedForestComputer = LocationComputer(for: .enchantedForest) {
///     locationProperty(.description) { context in
///         let timeOfDay = try await context.gameState.value(of: .timeOfDay) ?? "day"
///         return .string(timeOfDay == "night" ? "Dark woods loom." : "Sunlight filters through trees.")
///     }
///     
///     locationProperty(.isLit) { context in
///         let timeOfDay = try await context.gameState.value(of: .timeOfDay) ?? "day"
///         return .bool(timeOfDay == "day")
///     }
/// }
/// ```
@resultBuilder
public struct LocationComputeMatcherBuilder {
    public static func buildBlock(_ matchers: LocationComputeMatcher...) -> [LocationComputeMatcher] {
        Array(matchers)
    }
}

// MARK: - Location Compute Matcher Builder Functions

/// Creates a location property matcher for the specified properties.
///
/// - Parameters:
///   - properties: The properties to match against
///   - result: The closure to execute if any property matches, receiving the context
/// - Returns: A LocationComputeMatcher that can be used in the result builder
public func locationProperty(
    _ properties: LocationPropertyID...,
    result: @escaping (LocationComputeContext) async throws -> StateValue?
) -> LocationComputeMatcher {
    { context in
        if properties.contains(context.propertyID) {
            try await result(context)
        } else {
            nil
        }
    }
}
