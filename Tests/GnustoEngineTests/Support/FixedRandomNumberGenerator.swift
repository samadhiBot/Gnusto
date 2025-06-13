import Foundation

/// A deterministic random number generator for testing purposes.
///
/// This generator provides predictable, repeatable sequences of random values by cycling
/// through a predetermined set of `UInt64` values. It implements the `RandomNumberGenerator`
/// protocol, making it compatible with Swift's standard library random functions.
///
/// The generator maintains internal state and is therefore `mutating`. When used with
/// actor-isolated properties (like in `GameEngine`), prefer direct calls to `next()`
/// over passing inout references to avoid concurrency issues.
///
/// ## Usage
///
/// ```swift
/// // Create a generator that always returns the same value (50% probability)
/// var generator = FixedRandomNumberGenerator(value: 0.5)
///
/// // Create a generator that cycles through multiple values
/// var cyclingGenerator = FixedRandomNumberGenerator(values: [0.1, 0.5, 0.9])
///
/// // Use with GameEngine for deterministic testing
/// let engine = GameEngine(
///     blueprint: gameBlueprint,
///     randomNumberGenerator: generator,
///     // ... other parameters
/// )
/// ```
///
/// ## Thread Safety
///
/// While marked as `Sendable`, this generator maintains mutable state (`currentIndex`).
/// In concurrent contexts, ensure proper synchronization or use separate instances
/// per execution context.
public struct FixedRandomNumberGenerator: RandomNumberGenerator, Sendable {
    private var values: [UInt64]
    private var currentIndex: Int = 0

    /// Creates a generator that always returns the same value.
    ///
    /// The provided value is converted from the 0.0-1.0 range to the full `UInt64` range
    /// that the `RandomNumberGenerator` protocol expects.
    ///
    /// - Parameter value: The fixed probability value to return (0.0 to 1.0, defaults to 0.5).
    public init(value: Double = 0.5) {
        // Convert the double to UInt64 for the RandomNumberGenerator protocol
        // We scale the 0.0-1.0 range to the full UInt64 range
        let scaled = UInt64(value * Double(UInt64.max))
        self.values = [scaled]
    }

    /// Creates a generator that cycles through a sequence of values.
    ///
    /// The generator will return each value in order, then restart from the beginning
    /// when it reaches the end of the sequence. Each value is converted from the
    /// 0.0-1.0 range to the full `UInt64` range.
    ///
    /// - Parameter values: The sequence of probability values to cycle through (each 0.0 to 1.0).
    public init(values: [Double]) {
        self.values = values.map { UInt64($0 * Double(UInt64.max)) }
    }

    /// Returns the next `UInt64` value in the predetermined sequence.
    ///
    /// This method implements the `RandomNumberGenerator` protocol requirement.
    /// It cycles through the internal `values` array, wrapping back to the beginning
    /// when it reaches the end.
    ///
    /// - Returns: The next `UInt64` value in the sequence.
    public mutating func next() -> UInt64 {
        let value = values[currentIndex]
        currentIndex = (currentIndex + 1) % values.count
        return value
    }
}
