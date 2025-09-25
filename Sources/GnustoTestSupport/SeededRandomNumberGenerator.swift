import Foundation

/// A thread-safe seeded random number generator that implements a linear congruential generator
/// (LCG) algorithm.
///
/// This generator produces deterministic pseudo-random sequences based on an initial seed value,
/// making it useful for reproducible random number generation in testing and simulations.
/// The implementation is thread-safe and can be used concurrently from multiple threads.
///
/// ## Thread Safety Example
///
/// ```swift
/// let generator = SeededRandomNumberGenerator(seed: 42)
///
/// // Safe to call from multiple concurrent tasks
/// await withTaskGroup(of: UInt64.self) { group in
///     for _ in 0..<10 {
///         group.addTask {
///             return generator.next()
///         }
///     }
///
///     for await value in group {
///         print("Generated: \(value)")
///     }
/// }
/// ```
public struct SeededRandomNumberGenerator: RandomNumberGenerator, Sendable {

    // MARK: - Private Types

    /// Thread-safe wrapper for the internal state
    private final class StateContainer: @unchecked Sendable {
        private let lock = NSLock()
        private var value: UInt64

        init(_ initialValue: UInt64) {
            self.value = initialValue
        }

        func withLock<T>(_ operation: (inout UInt64) -> T) -> T {
            lock.lock()
            defer { lock.unlock() }
            return operation(&value)
        }
    }

    // MARK: - Properties

    /// The internal state container, protected by a lock for thread safety
    private let stateContainer: StateContainer

    // MARK: - Initialization

    /// Initializes a new seeded random number generator with the specified seed value.
    ///
    /// - Parameter seed: The initial seed value for the generator.
    public init(seed: UInt64 = 71) {
        self.stateContainer = StateContainer(seed)
    }

    // MARK: - Public Methods

    /// Generates the next random UInt64 value in the sequence.
    ///
    /// Uses a linear congruential generator formula: state = (a * state + c) mod 2^64
    /// where a = 6364136223846793005 and c = 1 (constants from Numerical Recipes).
    ///
    /// This method is thread-safe and can be called concurrently from multiple threads.
    ///
    /// - Returns: A pseudo-random UInt64 value
    public func next() -> UInt64 {
        stateContainer.withLock { state in
            state = 6_364_136_223_846_793_005 &* state &+ 1
            return state
        }
    }
}
