import Foundation
import IssueReporting

/// A unified random number generator that automatically selects the appropriate
/// underlying generator based on the execution environment.
///
/// In test environments (Swift Testing or XCTest), `UnifiedRNG` uses a deterministic
/// seeded generator to ensure reproducible results. In production environments, it uses
/// the system's random number generator for true randomness.
///
/// ## Automatic Test Detection
///
/// The test environment is detected automatically by checking for the presence of
/// Swift Testing or XCTest frameworks at runtime. No configuration is required.
///
/// ## Usage
///
/// ```swift
/// // Automatically uses SeededRNG in tests, SystemRandomNumberGenerator in production
/// let rng = UnifiedRNG()
///
/// // Generate a random number
/// let value = rng.next()
///
/// // Use with standard library random APIs
/// let randomElement = [1, 2, 3, 4, 5].randomElement(using: &rng)
/// ```
///
/// ## Parent Ownership Validation
///
/// Each `UnifiedRNG` instance tracks its parent owner. If an attempt is made to use
/// the same instance from multiple parents, the generator will trigger a fatal error
/// to prevent subtle bugs from shared mutable state.
///
/// ```swift
/// let rng = UnifiedRNG()
///
/// // First parent claims ownership
/// rng.claimOwnership(parent: "MessengerA")  // ✅ OK
///
/// // Different parent tries to use the same instance
/// rng.claimOwnership(parent: "MessengerB")  // ❌ Fatal error
/// ```
public struct UnifiedRNG: RandomNumberGenerator, Sendable {

    // MARK: - Private Types

    /// Thread-safe container for the underlying generator and ownership tracking
    private final class GeneratorContainer: @unchecked Sendable {
        private let lock = NSLock()
        private var generator: any RandomNumberGenerator
        private var owner: String?

        init(generator: any RandomNumberGenerator) {
            self.generator = generator
        }

        func next() -> UInt64 {
            lock.lock()
            defer { lock.unlock() }
            return generator.next()
        }

        func claimOwnership(parent: String) {
            lock.lock()
            defer { lock.unlock() }

            if let existingOwner = owner {
                if existingOwner != parent {
                    fatalError(
                        """
                        UnifiedRNG ownership violation:
                        - Current owner: \(existingOwner)
                        - Attempted new owner: \(parent)

                        Each UnifiedRNG instance must have exactly one parent owner.
                        Create a new UnifiedRNG() instance for each parent instead of sharing.
                        """)
                }
                // Same owner claiming again is OK (idempotent)
            } else {
                owner = parent
            }
        }
    }

    // MARK: - Properties

    /// The underlying generator container
    private let container: GeneratorContainer

    // MARK: - Initialization

    /// Creates a new unified random number generator.
    ///
    /// The appropriate underlying generator is selected automatically based on the
    /// execution environment:
    /// - Test environment: Uses `SeededRNG` for deterministic results
    /// - Production environment: Uses `SystemRandomNumberGenerator` for true randomness
    ///
    /// - Parameter seed: Optional seed value for test environments. Ignored in production.
    ///                   Defaults to 71 to match `SeededRNG` default.
    public init(seed: UInt64 = 71) {
        container = GeneratorContainer(
            generator: isTesting ? SeededRNG(seed: seed) : SystemRandomNumberGenerator()
        )
    }

    // MARK: - Public Methods

    /// Generates the next random value.
    ///
    /// This method is thread-safe and can be called concurrently from multiple threads.
    ///
    /// - Returns: A random UInt64 value
    public func next() -> UInt64 {
        container.next()
    }

    /// Claims ownership of this RNG instance for the specified parent.
    ///
    /// This method enforces single-parent ownership to prevent subtle bugs from shared
    /// mutable state. If a different parent has already claimed ownership, this method
    /// will trigger a fatal error.
    ///
    /// - Parameter parent: A string identifying the parent owner (e.g., "StandardMessenger",
    ///                     "CombatMessenger", "CombatMiddleware")
    public func claimOwnership(parent: String) {
        container.claimOwnership(parent: parent)
    }
}

// MARK: - SeededRNG

/// A thread-safe seeded random number generator that implements a linear congruential
/// generator (LCG) algorithm.
///
/// This generator produces deterministic pseudo-random sequences based on an initial seed
/// value, making it useful for reproducible random number generation in testing and simulations.
/// The implementation is thread-safe and can be used concurrently from multiple threads.
///
/// Note: In most cases, you should use `UnifiedRNG` instead, which automatically selects
/// this generator in test environments.
public struct SeededRNG: RandomNumberGenerator, Sendable {

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
    /// - Parameter seed: The initial seed value for the generator. Defaults to 71.
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
