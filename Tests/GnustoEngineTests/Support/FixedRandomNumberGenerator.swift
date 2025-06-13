import Foundation

/// A deterministic random number generator for testing purposes.
///
/// This generator always returns the same sequence of values, making tests predictable
/// and repeatable. By default, it returns a fixed value, but it can be configured to
/// cycle through a sequence of predetermined values.
public struct FixedRandomNumberGenerator: RandomNumberGenerator, Sendable {
    private var values: [UInt64]
    private var currentIndex: Int = 0

    /// Creates a generator that always returns the same value.
    /// - Parameter value: The fixed value to return (0.0 to 1.0)
    public init(value: Double = 0.5) {
        // Convert the double to UInt64 for the RandomNumberGenerator protocol
        // We scale the 0.0-1.0 range to the full UInt64 range
        let scaled = UInt64(value * Double(UInt64.max))
        self.values = [scaled]
    }

    /// Creates a generator that cycles through a sequence of values.
    /// - Parameter values: The sequence of values to cycle through (0.0 to 1.0)
    public init(values: [Double]) {
        self.values = values.map { UInt64($0 * Double(UInt64.max)) }
    }

    public mutating func next() -> UInt64 {
        let value = values[currentIndex]
        currentIndex = (currentIndex + 1) % values.count
        return value
    }
}
