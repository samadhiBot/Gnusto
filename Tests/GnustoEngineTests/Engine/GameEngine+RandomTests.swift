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
            values,
            [
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

    // MARK: - Random Int Tests

    @Test("randomInt returns value in correct range")
    func testRandomIntRange() async throws {
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Test different ranges
        for _ in 0..<100 {
            let value1 = await engine.randomInt(in: 1...10)
            #expect(value1 >= 1 && value1 <= 10)

            let value2 = await engine.randomInt(in: -5...5)
            #expect(value2 >= -5 && value2 <= 5)

            let value3 = await engine.randomInt(in: 100...200)
            #expect(value3 >= 100 && value3 <= 200)
        }
    }

    @Test("randomInt handles single-value range")
    func testRandomIntSingleValue() async throws {
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Single value range should always return that value
        for _ in 0..<10 {
            let value = await engine.randomInt(in: 42...42)
            #expect(value == 42)
        }
    }

    @Test("randomInt can produce deterministic values for testing")
    func testRandomIntDeterministic() async throws {
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        var values = [Int]()

        for _ in 0..<20 {
            let value = await engine.randomInt(in: 1...6)
            values.append(value)
        }

        expectNoDifference(
            values,
            [
                3, 2, 5, 3, 1, 6, 6, 6, 4, 1, 3, 4, 6, 1, 1, 2, 2, 6, 1, 5,
            ]
        )
    }

    @Test("randomInt distributes values across range")
    func testRandomIntDistribution() async throws {
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        let range = 1...5
        var counts: [Int: Int] = [:]

        // Generate many values
        for _ in 0..<1_000 {
            let value = await engine.randomInt(in: range)
            counts[value, default: 0] += 1
        }

        // Each value in range should appear at least once
        for expectedValue in range {
            #expect(counts[expectedValue] ?? 0 > 0, "Value \(expectedValue) was never generated")
        }

        // No value should completely dominate
        let maxCount = counts.values.max() ?? 0
        #expect(maxCount < 900, "Distribution seems too skewed: \(counts)")
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

    @Test("randomPercentage handles edge cases")
    func testRandomPercentageEdgeCases() async throws {
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        // 0% should never succeed
        for _ in 0..<20 {
            let result = await engine.randomPercentage(chance: 0)
            #expect(result == false)
        }

        // 100% should always succeed
        for _ in 0..<20 {
            let result = await engine.randomPercentage(chance: 100)
            #expect(result == true)
        }
    }

    @Test("randomPercentage can produce deterministic values for testing")
    func testRandomPercentageDeterministic() async throws {
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        var results = [Bool]()

        for _ in 0..<15 {
            let result = await engine.randomPercentage(chance: 50)
            results.append(result)
        }

        expectNoDifference(
            results,
            [
                true, true, false, true, true, false, false, false, false, true, true, false,
                false, true, true,
            ]
        )
    }

    @Test("randomPercentage works with various percentages")
    func testRandomPercentageVariousChances() async throws {
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Test 25% chance over many iterations
        var successes25 = 0
        for _ in 0..<1_000 {
            if await engine.randomPercentage(chance: 25) {
                successes25 += 1
            }
        }

        // Should be roughly 25% (allow for variance)
        #expect(
            successes25 > 200 && successes25 < 300,
            "25% chance resulted in \(successes25)/1000 successes")

        // Test 75% chance over many iterations
        var successes75 = 0
        for _ in 0..<1_000 {
            if await engine.randomPercentage(chance: 75) {
                successes75 += 1
            }
        }

        // Should be roughly 75% (allow for variance)
        #expect(
            successes75 > 700 && successes75 < 800,
            "75% chance resulted in \(successes75)/1000 successes")
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
            values,
            [
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

    // MARK: - Roll D10 Tests

    @Test("rollD10 returns correct results for thresholds")
    func testRollD10Thresholds() async throws {
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Test threshold 1 (should always succeed since die shows 1-10)
        var successes = 0
        for _ in 0..<100 {
            if await engine.rollD10(rollsAtLeast: 1) {
                successes += 1
            }
        }
        #expect(successes == 100, "Threshold 1 should always succeed")

        // Test threshold 11 (should never succeed since die shows 1-10)
        successes = 0
        for _ in 0..<100 {
            if await engine.rollD10(rollsAtLeast: 11) {
                successes += 1
            }
        }
        #expect(successes == 0, "Threshold 11 should never succeed")
    }

    @Test("rollD10 can produce deterministic values for testing")
    func testRollD10Deterministic() async throws {
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        var results = [Bool]()

        for _ in 0..<15 {
            let result = await engine.rollD10(rollsAtLeast: 5)
            results.append(result)
        }

        expectNoDifference(
            results,
            [
                true, false, true, true, false, true, true, true, true, false, true, true, true,
                false, false,
            ]
        )
    }

    @Test("rollD10 distributes results appropriately")
    func testRollD10Distribution() async throws {
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Test threshold 5 (should succeed roughly 60% of time: rolls 5,6,7,8,9,10)
        var successes = 0
        for _ in 0..<1_000 {
            if await engine.rollD10(rollsAtLeast: 5) {
                successes += 1
            }
        }

        // Should be roughly 60% (6 out of 10 possible outcomes)
        #expect(
            successes > 500 && successes < 700,
            "Threshold 5 resulted in \(successes)/1000 successes")
    }

    // MARK: - Roll D20 Tests

    @Test("rollD20 returns correct results for thresholds")
    func testRollD20Thresholds() async throws {
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Test threshold 1 (should always succeed since die shows 1-20)
        var successes = 0
        for _ in 0..<100 {
            if await engine.rollD20(rollsAtLeast: 1) {
                successes += 1
            }
        }
        #expect(successes == 100, "Threshold 1 should always succeed")

        // Test threshold 21 (should never succeed since die shows 1-20)
        successes = 0
        for _ in 0..<100 {
            if await engine.rollD20(rollsAtLeast: 21) {
                successes += 1
            }
        }
        #expect(successes == 0, "Threshold 21 should never succeed")
    }

    @Test("rollD20 can produce deterministic values for testing")
    func testRollD20Deterministic() async throws {
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        var results = [Bool]()

        for _ in 0..<15 {
            let result = await engine.rollD20(rollsAtLeast: 10)
            results.append(result)
        }

        expectNoDifference(
            results,
            [
                true, false, true, true, false, true, true, true, true, false, false, true, true,
                false, false,
            ]
        )
    }

    @Test("rollD20 distributes results appropriately")
    func testRollD20Distribution() async throws {
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Test threshold 11 (should succeed roughly 50% of time: rolls 11-20)
        var successes = 0
        for _ in 0..<1_000 {
            if await engine.rollD20(rollsAtLeast: 11) {
                successes += 1
            }
        }

        // Should be roughly 50% (10 out of 20 possible outcomes)
        #expect(
            successes > 400 && successes < 600,
            "Threshold 11 resulted in \(successes)/1000 successes")
    }

    // MARK: - Integration Tests

    @Test("all random methods work together consistently")
    func testRandomMethodsIntegration() async throws {
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Use all random methods in sequence
        let double1 = await engine.randomDouble()
        let percentage1 = await engine.randomPercentage(chance: 10)
        let element1 = await engine.randomElement(in: ["X", "Y", "Z"])
        let int1 = await engine.randomInt(in: 1...100)
        let d10_1 = await engine.rollD10(rollsAtLeast: 5)
        let d20_1 = await engine.rollD20(rollsAtLeast: 15)

        let double2 = await engine.randomDouble()
        let percentage2 = await engine.randomPercentage(chance: 99)
        let element2 = await engine.randomElement(in: ["X", "Y", "Z"])
        let int2 = await engine.randomInt(in: 1...100)
        let d10_2 = await engine.rollD10(rollsAtLeast: 5)
        let d20_2 = await engine.rollD20(rollsAtLeast: 15)

        // Values should be valid
        #expect(double1 >= 0.0 && double1 < 1.0)
        #expect(percentage1 == false)
        #expect(["X", "Y", "Z"].contains(element1))
        #expect(int1 >= 1 && int1 <= 100)
        #expect([true, false].contains(d10_1))
        #expect([true, false].contains(d20_1))

        #expect(double2 >= 0.0 && double2 < 1.0)
        #expect(percentage2 == true)
        #expect(["X", "Y", "Z"].contains(element2))
        #expect(int2 >= 1 && int2 <= 100)
        #expect([true, false].contains(d10_2))
        #expect([true, false].contains(d20_2))

        // With a seeded generator, the sequence should be deterministic
        // Verify they produce expected results
        expectNoDifference(double1, 0.8350297165326732)
        expectNoDifference(percentage1, false)
        expectNoDifference(element1, "Z")
        expectNoDifference(int1, 50)
        expectNoDifference(d10_1, false)
        expectNoDifference(d20_1, true)

        expectNoDifference(double2, 0.2728560420208541)
        expectNoDifference(percentage2, true)
        expectNoDifference(element2, "Y")
        expectNoDifference(int2, 6)
        expectNoDifference(d10_2, true)
        expectNoDifference(d20_2, false)
    }
}
