import Foundation

/// A seeded random number generator that implements a linear congruential generator (LCG) algorithm.
///
/// This generator produces deterministic pseudo-random sequences based on an initial seed value,
/// making it useful for reproducible random number generation in testing and simulations.
public struct SeededRandomNumberGenerator: RandomNumberGenerator, Sendable {
    /// The internal state of the random number generator
    private var state: UInt64

    /// Initializes a new seeded random number generator with the specified seed value.
    ///
    /// - Parameter seed: The initial seed value for the generator.
    public init(seed: UInt64 = 71) {
        self.state = seed
    }

    /// Generates the next random UInt64 value in the sequence.
    ///
    /// Uses a linear congruential generator formula: state = (a * state + c) mod 2^64
    /// where a = 6364136223846793005 and c = 1 (constants from Numerical Recipes).
    ///
    /// - Returns: A pseudo-random UInt64 value
    public mutating func next() -> UInt64 {
        state = 6_364_136_223_846_793_005 &* state &+ 1
        return state
    }
}
