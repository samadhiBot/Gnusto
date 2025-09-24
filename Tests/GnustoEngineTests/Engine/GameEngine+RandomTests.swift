import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("GameEngine Random Tests")
struct GameEngineRandomTests {

    // MARK: - Random Double Tests

    @Test("randomDouble returns value in correct range")
    func testRandomDoubleRange() async throws {
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        // Test multiple values to ensure they're in range
        for _ in 0..<100 {
            let value = await engine.randomDouble()
            #expect(value >= 0.0)
            #expect(value < 1.0)
        }
    }

    @Test("randomDouble can produce deterministic values for testing")
    func testRandomDoubleDeterministic() async throws {
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        var values = [Double]()

        for _ in 0..<25 {
            let value = await engine.randomDouble()
            values.append(value)
        }

        expectNoDifference(
            values, [
                0.8350297165326732,
                0.6651743565360789,
                0.33749983916303106,
                0.04045289403475072,
                0.3062399736298653,
                0.3781552213687195,
                0.2728560420208541,
                0.5956885600965335,
                0.14110790513557925,
                0.10104497572235316,
                0.1355074094972546,
                0.8610598104646948,
                0.9616321872854634,
                0.5213575019048059,
                0.8807643188239724,
                0.06178615631326678,
                0.11200620628122726,
                0.0038094609012869762,
                0.5939165213727684,
                0.6374286009446507,
                0.6472069572862997,
                0.6222853597225991,
                0.8783525360038851,
                0.30749223707537776,
                0.7789377230019316,
            ]
        )
        expectNoDifference(
            values.reduce(0, +) / 25,
            0.4670716988447969
        )
    }

    // MARK: - Random Percentage Tests

    @Test("randomPercentage returns value in correct range")
    func testRandomPercentageRange() async throws {
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        var heads = 0
        var tails = 0

        // Test multiple values to ensure they're in range
        for _ in 0..<100 {
            if await engine.randomPercentage(chance: 50) {
                heads += 1
            } else {
                tails += 1
            }
        }

        expectNoDifference(heads, 50)
        expectNoDifference(tails, 50)
    }

    // MARK: - Random Element Tests

    @Test("randomElement returns element from collection")
    func testRandomElementFromArray() async throws {
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        let collection = ["apple", "banana", "cherry", "date"]

        // Test multiple selections
        for _ in 0..<20 {
            if let element = await engine.randomElement(in: collection) {
                #expect(collection.contains(element))
            }
        }
    }

    @Test("randomElement works with different collection types")
    func testRandomElementDifferentCollectionTypes() async throws {
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        // Test with Set
        let stringSet: Set<String> = ["red", "green", "blue"]
        if let setElement = await engine.randomElement(in: stringSet) {
            #expect(stringSet.contains(setElement))
        }

        // Test with Range
        let range = 1...5
        if let rangeElement = await engine.randomElement(in: range) {
            #expect(range.contains(rangeElement))
        }

        // Test with Dictionary values
        let dictionary = ["a": 1, "b": 2, "c": 3]
        if let dictElement = await engine.randomElement(in: dictionary.values) {
            #expect(dictionary.values.contains(dictElement))
        }
    }

    @Test("randomElement returns nil for empty collection")
    func testRandomElementEmptyCollection() async throws {
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        let emptyArray: [String] = []

        let element = await engine.randomElement(in: emptyArray)
        #expect(element == nil)
    }

    @Test("randomElement distributes selections across collection")
    func testRandomElementDistribution() async throws {
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        let collection = ["A", "B", "C", "D"]
        var counts: [String: Int] = [:]

        // Generate many selections
        for _ in 0..<1_000 {
            guard let element = await engine.randomElement(in: collection) else {
                Issue.record("Unexpectedly returned nil")
                break
            }
            counts[element, default: 0] += 1
        }

        // Each element should be selected at least once in 1000 tries
        for element in collection {
            #expect(counts[element] ?? 0 > 0, "Element \(element) was never selected")
        }

        // No single element should dominate completely (should be somewhat distributed)
        let maxCount = counts.values.max() ?? 0
        #expect(maxCount < 900, "Distribution seems too skewed: \(counts)")
    }

    @Test("randomElement handles single-element collection")
    func testRandomElementSingleElement() async throws {
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        let singleElementArray = ["onlyChoice"]

        // Should always return the single element
        for _ in 0..<10 {
            let element = await engine.randomElement(in: singleElementArray)
            #expect(element == "onlyChoice")
        }
    }

    @Test("randomElement can produce deterministic values for testing")
    func testRandomElementDeterministic() async throws {
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        var values = [String]()
        let collection = ["apple", "banana", "cherry", "date"]

        // Test multiple selections
        for _ in 0..<12 {
            if let element = await engine.randomElement(in: collection) {
                values.append(element)
            }
        }

        expectNoDifference(
            values, [
                "banana",
                "banana",
                "date",
                "banana",
                "apple",
                "date",
                "date",
                "date",
                "cherry",
                "apple",
                "banana",
                "cherry",
            ]
        )
    }

    // MARK: - Integration Tests

    @Test("all random methods work together consistently")
    func testRandomMethodsIntegration() async throws {
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        // Use all three random methods in sequence
        let double1 = await engine.randomDouble()
        let percentage1 = await engine.randomPercentage(chance: 10)
        let element1 = await engine.randomElement(in: ["X", "Y", "Z"])

        let double2 = await engine.randomDouble()
        let percentage2 = await engine.randomPercentage(chance: 90)
        let element2 = await engine.randomElement(in: ["X", "Y", "Z"])

        // Values should be valid
        #expect(double1 >= 0.0 && double1 < 1.0)
        #expect(percentage1 == false)
        #expect(["X", "Y", "Z"].contains(element1))

        #expect(double2 >= 0.0 && double2 < 1.0)
        #expect(percentage2 == true)
        #expect(["X", "Y", "Z"].contains(element2))

        // With a seeded generator, the sequence should be deterministic
        // but we can't predict exact values, so just verify they're different
        // (very unlikely to be identical with good RNG)
        #expect(double1 != double2 || percentage1 != percentage2 || element1 != element2)
    }
}
