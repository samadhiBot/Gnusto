import Foundation
import Testing

@testable import GnustoEngine
@testable import GnustoTestSupport

@Suite("SeededRandomNumberGenerator Tests")
struct SeededRandomNumberGeneratorTests {

    @Test("Generator produces deterministic sequence with same seed")
    func testDeterministicSequence() {
        let generator1 = SeededRandomNumberGenerator(seed: 42)
        let generator2 = SeededRandomNumberGenerator(seed: 42)

        // Generate several numbers and verify they match
        for _ in 0..<10 {
            let value1 = generator1.next()
            let value2 = generator2.next()
            #expect(value1 == value2)
        }
    }

    @Test("Generator produces different sequence with different seeds")
    func testDifferentSeeds() {
        let generator1 = SeededRandomNumberGenerator(seed: 42)
        let generator2 = SeededRandomNumberGenerator(seed: 123)

        let value1 = generator1.next()
        let value2 = generator2.next()

        #expect(value1 != value2)
    }

    @Test("Generator produces expected sequence for default seed")
    func testDefaultSeedSequence() {
        let generator = SeededRandomNumberGenerator()

        // Test first few values with default seed (71)
        let expected: [UInt64] = [
            9_131_814_124_093_064_572,
            5_392_296_512_303_577_805,
            14_909_954_694_896_126_218,
        ]

        for expectedValue in expected {
            #expect(generator.next() == expectedValue)
        }
    }

    @Test("Thread safety - concurrent access does not crash")
    func testThreadSafety() async {
        let generator = SeededRandomNumberGenerator(seed: 100)
        let numThreads = 10
        let numIterations = 1000

        await withTaskGroup(of: [UInt64].self) { group in
            // Launch multiple concurrent tasks
            for _ in 0..<numThreads {
                group.addTask {
                    var results: [UInt64] = []
                    for _ in 0..<numIterations {
                        let value = generator.next()
                        results.append(value)
                    }
                    return results
                }
            }

            var allResults: [UInt64] = []
            for await results in group {
                allResults.append(contentsOf: results)
            }

            // Verify we got the expected number of results
            #expect(allResults.count == numThreads * numIterations)

            // Verify all results are non-zero (extremely unlikely to be zero with LCG)
            let nonZeroCount = allResults.filter { $0 != 0 }.count
            #expect(nonZeroCount == allResults.count)
        }
    }

    @Test("Thread safety - deterministic behavior with synchronous access")
    func testThreadSafetyDeterministic() async {
        // Test that when accessed sequentially (even across tasks),
        // the generator produces the same sequence as a single-threaded version
        let seed: UInt64 = 42

        // Generate reference sequence single-threaded
        let referenceGenerator = SeededRandomNumberGenerator(seed: seed)
        let referenceSequence = (0..<100).map { _ in referenceGenerator.next() }

        // Generate test sequence using async tasks but in sequential order
        let testGenerator = SeededRandomNumberGenerator(seed: seed)
        var testSequence: [UInt64] = []

        for _ in 0..<100 {
            let value: UInt64 = await withCheckedContinuation { continuation in
                Task {
                    let value = testGenerator.next()
                    continuation.resume(returning: value)
                }
            }
            testSequence.append(value)
        }

        // Both sequences should be identical
        #expect(testSequence.count == referenceSequence.count)
        for (test, reference) in zip(testSequence, referenceSequence) {
            #expect(test == reference)
        }
    }

    @Test("Generator implements RandomNumberGenerator correctly")
    func testRandomNumberGeneratorConformance() {
        let generator = SeededRandomNumberGenerator(seed: 999)

        // Test that we can use it as a RandomNumberGenerator
        var mutableGenerator = generator
        let randomInt = Int.random(in: 1...100, using: &mutableGenerator)
        #expect(randomInt >= 1 && randomInt <= 100)

        let randomBool = Bool.random(using: &mutableGenerator)
        #expect(randomBool == true || randomBool == false)

        let randomDouble = Double.random(in: 0.0...1.0, using: &mutableGenerator)
        #expect(randomDouble >= 0.0 && randomDouble <= 1.0)
    }

    @Test("Generator state advances correctly")
    func testStateProgression() {
        let generator = SeededRandomNumberGenerator(seed: 1)

        let values = (0..<5).map { _ in generator.next() }

        // Verify all values are different (extremely unlikely to repeat with LCG)
        let uniqueValues = Set(values)
        #expect(uniqueValues.count == values.count)
    }

    @Test("Multiple generators with same seed produce same sequence")
    func testMultipleGenerators() {
        let seed: UInt64 = 12345
        let generator1 = SeededRandomNumberGenerator(seed: seed)
        let generator2 = SeededRandomNumberGenerator(seed: seed)
        let generator3 = SeededRandomNumberGenerator(seed: seed)

        for _ in 0..<50 {
            let value1 = generator1.next()
            let value2 = generator2.next()
            let value3 = generator3.next()

            #expect(value1 == value2)
            #expect(value2 == value3)
        }
    }
}
