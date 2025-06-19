import Foundation

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64 = 71) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        // Constants from Numerical Recipes
        state = 6364136223846793005 &* state &+ 1
        return state
    }
}
