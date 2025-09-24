import Foundation

extension GameEngine {
    /// Generates a random Double value between 0.0 and 1.0.
    ///
    /// This is a convenience method that provides the same interface as the original
    /// randomizer closure, making it easy to migrate existing code that expects
    /// a 0.0-1.0 range Double value.
    ///
    /// - Returns: A random Double between 0.0 and 1.0 (inclusive of 0.0, exclusive of 1.0).
    public func randomDouble() -> Double {
        Double.random(in: 0.0..<1.0, using: &randomNumberGenerator)
    }

    /// Generates a random Boolean value based on the specified percentage chance.
    ///
    /// This method provides a convenient way to perform percentage-based probability checks.
    /// For example, passing 75 as the chance parameter gives a 75% probability of returning true.
    ///
    /// - Parameter chance: The percentage chance (0-100) of returning true.
    ///   0 means never true, 100 means always true.
    /// - Returns: True if the random roll succeeds based on the given percentage, false otherwise.
    /// - Precondition: chance must be between 0 and 100 (inclusive).
    public func randomPercentage(chance: Int) -> Bool {
        assert(chance >= 0 && chance <= 100, "Chance must be between 0 and 100")
        return Int.random(in: 0...100, using: &randomNumberGenerator) <= chance
    }

    /// Generates a random integer within the specified range.
    ///
    /// Uses the game's seeded random number generator for deterministic results.
    ///
    /// - Parameter range: The range to generate a random number within.
    /// - Returns: A random integer within the specified range.
    public func randomInt(in range: ClosedRange<Int>) -> Int {
        Int.random(in: range, using: &randomNumberGenerator)
    }

    /// Returns a random element from the given collection.
    ///
    /// This method provides a convenient way to select a random element from any collection
    /// using the engine's seeded random number generator, ensuring reproducible randomness
    /// across game sessions.
    ///
    /// The implementation uses direct calls to `randomNumberGenerator.next()` and modulo
    /// arithmetic to avoid actor isolation issues with inout references.
    ///
    /// - Parameter collection: The collection to select a random element from.
    /// - Returns: A random element from the collection.
    /// - Throws: `ActionResponse.internalEngineError` if the collection is empty.
    public func randomElement<T>(in collection: some Collection<T>) -> T? {
        guard collection.isNotEmpty else { return nil }
        return collection[
            collection.index(
                collection.startIndex,
                offsetBy: randomInt(in: 0...collection.count - 1)
            )
        ]
    }

    /// Rolls a 10-sided die and checks if it meets or exceeds the threshold.
    ///
    /// This method simulates rolling a D10 (1-10) and returns true if the result
    /// is greater than or equal to the specified threshold value.
    ///
    /// - Parameter threshold: The minimum value needed for success (1-10).
    /// - Returns: True if the roll meets or exceeds the threshold, false otherwise.
    public func rollD10(rollsAtLeast threshold: Int) -> Bool {
        randomInt(in: 1...10) >= threshold
    }

    /// Rolls a 20-sided die and checks if it meets or exceeds the threshold.
    ///
    /// This method simulates rolling a D20 (1-20) and returns true if the result
    /// is greater than or equal to the specified threshold value.
    ///
    /// - Parameter threshold: The minimum value needed for success (1-20).
    /// - Returns: True if the roll meets or exceeds the threshold, false otherwise.
    public func rollD20(rollsAtLeast threshold: Int) -> Bool {
        randomInt(in: 1...20) >= threshold
    }
}
