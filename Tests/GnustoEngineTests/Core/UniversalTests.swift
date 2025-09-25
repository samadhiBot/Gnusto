import CustomDump
import Foundation
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("Universal Tests")
struct UniversalTests {

    // MARK: - Basic Property Tests

    @Test("Universal id property returns raw value")
    func testIdProperty() {
        #expect(Universal.ground.id == "ground")
        #expect(Universal.sky.id == "sky")
        #expect(Universal.water.id == "water")
        #expect(Universal.walls.id == "walls")
    }

    @Test("Universal displayName property returns capitalized raw value")
    func testDisplayNameProperty() {
        #expect(Universal.ground.displayName == "Ground")
        #expect(Universal.sky.displayName == "Sky")
        #expect(Universal.water.displayName == "Water")
        #expect(Universal.walls.displayName == "Walls")
    }

    @Test("Universal withDefiniteArticle property formats correctly")
    func testWithDefiniteArticleProperty() {
        #expect(Universal.ground.withDefiniteArticle == "the ground")
        #expect(Universal.sky.withDefiniteArticle == "the sky")
        #expect(Universal.water.withDefiniteArticle == "the water")
        #expect(Universal.walls.withDefiniteArticle == "the walls")
    }

    // MARK: - CaseIterable Tests

    @Test("Universal conforms to CaseIterable")
    func testCaseIterable() {
        let allCases = Universal.allCases

        #expect(!allCases.isEmpty)
        #expect(allCases.contains(.ground))
        #expect(allCases.contains(.sky))
        #expect(allCases.contains(.water))
        #expect(allCases.contains(.walls))

        // Verify no duplicates
        let uniqueCases = Set(allCases)
        #expect(uniqueCases.count == allCases.count)
    }

    @Test("Universal contains expected cases")
    func testExpectedCases() {
        let allCases = Universal.allCases

        // Ground and Earth
        #expect(allCases.contains(.ground))
        #expect(allCases.contains(.earth))
        #expect(allCases.contains(.soil))
        #expect(allCases.contains(.dirt))
        #expect(allCases.contains(.floor))

        // Sky and Atmosphere
        #expect(allCases.contains(.sky))
        #expect(allCases.contains(.heavens))
        #expect(allCases.contains(.air))
        #expect(allCases.contains(.clouds))
        #expect(allCases.contains(.sun))
        #expect(allCases.contains(.moon))
        #expect(allCases.contains(.stars))

        // Architectural Elements
        #expect(allCases.contains(.ceiling))
        #expect(allCases.contains(.walls))
        #expect(allCases.contains(.wall))
        #expect(allCases.contains(.roof))

        // Water Features
        #expect(allCases.contains(.water))
        #expect(allCases.contains(.river))
        #expect(allCases.contains(.stream))
        #expect(allCases.contains(.lake))
        #expect(allCases.contains(.pond))
        #expect(allCases.contains(.ocean))
        #expect(allCases.contains(.sea))

        // Natural Elements
        #expect(allCases.contains(.wind))
        #expect(allCases.contains(.fire))
        #expect(allCases.contains(.flames))
        #expect(allCases.contains(.smoke))
        #expect(allCases.contains(.dust))
        #expect(allCases.contains(.mud))
        #expect(allCases.contains(.sand))
        #expect(allCases.contains(.rock))
        #expect(allCases.contains(.stone))

        // Abstract Concepts
        #expect(allCases.contains(.darkness))
        #expect(allCases.contains(.shadows))
        #expect(allCases.contains(.light))
        #expect(allCases.contains(.silence))
        #expect(allCases.contains(.sound))
        #expect(allCases.contains(.noise))
    }

    // MARK: - Codable Tests

    @Test("Universal encodes and decodes correctly")
    func testCodable() throws {
        let encoder = JSONEncoder.sorted()
        let decoder = JSONDecoder()

        for universalObject in Universal.allCases {
            let encoded = try encoder.encode(universalObject)
            let decoded = try decoder.decode(Universal.self, from: encoded)
            #expect(decoded == universalObject)
        }
    }

    @Test("Universal encodes to expected JSON string")
    func testEncodesToString() throws {
        let encoder = JSONEncoder.sorted()

        let groundData = try encoder.encode(Universal.ground)
        let groundString = String(data: groundData, encoding: .utf8)
        #expect(groundString == "\"ground\"")

        let skyData = try encoder.encode(Universal.sky)
        let skyString = String(data: skyData, encoding: .utf8)
        #expect(skyString == "\"sky\"")
    }

    // MARK: - Matches Method Tests

    @Test("Universal matches method works with related objects")
    func testMatchesMethod() {
        // Ground-related objects should match each other
        #expect(Universal.ground.matches(.floor))
        #expect(Universal.ground.matches(.earth))
        #expect(Universal.floor.matches(.ground))

        // Sky-related objects should match each other
        #expect(Universal.sky.matches(.heavens))
        #expect(Universal.heavens.matches(.sky))
        #expect(Universal.sky.matches(.air))

        // Water-related objects should match each other
        #expect(Universal.water.matches(.river))
        #expect(Universal.river.matches(.water))
        #expect(Universal.lake.matches(.ocean))

        // Unrelated objects should not match
        #expect(!Universal.ground.matches(.sky))
        #expect(!Universal.water.matches(.fire))
        #expect(!Universal.walls.matches(.river))
    }

    @Test("Universal matches itself through relatedUniversals")
    func testMatchesSelf() {
        for universalObject in Universal.allCases {
            #expect(universalObject.relatedUniversals.contains(universalObject))
        }
    }

    // MARK: - Related Universals Tests

    @Test("Ground and floor related universals are correct")
    func testGroundRelatedUniversals() {
        let groundRelated = Universal.ground.relatedUniversals
        let expectedGroundRelated: Set<Universal> = [.ground, .floor, .earth, .soil, .dirt]
        expectNoDifference(groundRelated, expectedGroundRelated)

        let floorRelated = Universal.floor.relatedUniversals
        expectNoDifference(floorRelated, expectedGroundRelated)
    }

    @Test("Earth, soil, dirt related universals are correct")
    func testEarthRelatedUniversals() {
        let earthRelated = Universal.earth.relatedUniversals
        let expectedEarthRelated: Set<Universal> = [.ground, .earth, .soil, .dirt]
        expectNoDifference(earthRelated, expectedEarthRelated)

        let soilRelated = Universal.soil.relatedUniversals
        expectNoDifference(soilRelated, expectedEarthRelated)

        let dirtRelated = Universal.dirt.relatedUniversals
        expectNoDifference(dirtRelated, expectedEarthRelated)
    }

    @Test("Sky and heavens related universals are correct")
    func testSkyRelatedUniversals() {
        let skyRelated = Universal.sky.relatedUniversals
        let expectedSkyRelated: Set<Universal> = [.sky, .heavens, .air, .clouds]
        expectNoDifference(skyRelated, expectedSkyRelated)

        let heavensRelated = Universal.heavens.relatedUniversals
        expectNoDifference(heavensRelated, expectedSkyRelated)
    }

    @Test("Air and clouds related universals are correct")
    func testAirRelatedUniversals() {
        let airRelated = Universal.air.relatedUniversals
        let expectedAirRelated: Set<Universal> = [.sky, .air, .clouds]
        expectNoDifference(airRelated, expectedAirRelated)

        let cloudsRelated = Universal.clouds.relatedUniversals
        expectNoDifference(cloudsRelated, expectedAirRelated)
    }

    @Test("Celestial objects related universals are correct")
    func testCelestialRelatedUniversals() {
        let expectedCelestialRelated: Set<Universal> = [.sun, .moon, .stars, .sky, .heavens]

        let sunRelated = Universal.sun.relatedUniversals
        expectNoDifference(sunRelated, expectedCelestialRelated)

        let moonRelated = Universal.moon.relatedUniversals
        expectNoDifference(moonRelated, expectedCelestialRelated)

        let starsRelated = Universal.stars.relatedUniversals
        expectNoDifference(starsRelated, expectedCelestialRelated)
    }

    @Test("Wall related universals are correct")
    func testWallRelatedUniversals() {
        let wallsRelated = Universal.walls.relatedUniversals
        let expectedWallRelated: Set<Universal> = [.walls, .wall, .ceiling, .floor]
        expectNoDifference(wallsRelated, expectedWallRelated)

        let wallRelated = Universal.wall.relatedUniversals
        expectNoDifference(wallRelated, expectedWallRelated)
    }

    @Test("Ceiling and roof related universals are correct")
    func testCeilingRelatedUniversals() {
        let ceilingRelated = Universal.ceiling.relatedUniversals
        let expectedCeilingRelated: Set<Universal> = [.ceiling, .roof]
        expectNoDifference(ceilingRelated, expectedCeilingRelated)

        let roofRelated = Universal.roof.relatedUniversals
        expectNoDifference(roofRelated, expectedCeilingRelated)
    }

    @Test("Water related universals are correct")
    func testWaterRelatedUniversals() {
        let expectedWaterRelated: Set<Universal> = [
            .water, .river, .stream, .lake, .pond, .ocean, .sea,
        ]

        for waterObject in [Universal.water, .river, .stream, .lake, .pond, .ocean, .sea] {
            let related = waterObject.relatedUniversals
            expectNoDifference(related, expectedWaterRelated)
        }
    }

    @Test("Fire related universals are correct")
    func testFireRelatedUniversals() {
        let fireRelated = Universal.fire.relatedUniversals
        let expectedFireRelated: Set<Universal> = [.fire, .flames, .smoke, .light]
        expectNoDifference(fireRelated, expectedFireRelated)

        let flamesRelated = Universal.flames.relatedUniversals
        expectNoDifference(flamesRelated, expectedFireRelated)
    }

    @Test("Remaining related universals are correct")
    func testRemainingRelatedUniversals() {
        // Wind
        let windRelated = Universal.wind.relatedUniversals
        expectNoDifference(windRelated, [.wind, .air])

        // Smoke
        let smokeRelated = Universal.smoke.relatedUniversals
        expectNoDifference(smokeRelated, [.smoke, .fire, .air])

        // Dust, mud, sand
        let dustRelated = Universal.dust.relatedUniversals
        let expectedDustRelated: Set<Universal> = [.dust, .mud, .sand, .dirt, .earth]
        expectNoDifference(dustRelated, expectedDustRelated)

        let mudRelated = Universal.mud.relatedUniversals
        expectNoDifference(mudRelated, expectedDustRelated)

        let sandRelated = Universal.sand.relatedUniversals
        expectNoDifference(sandRelated, expectedDustRelated)

        // Rock and stone
        let rockRelated = Universal.rock.relatedUniversals
        let expectedRockRelated: Set<Universal> = [.rock, .stone, .earth]
        expectNoDifference(rockRelated, expectedRockRelated)

        let stoneRelated = Universal.stone.relatedUniversals
        expectNoDifference(stoneRelated, expectedRockRelated)

        // Darkness and shadows
        let darknessRelated = Universal.darkness.relatedUniversals
        let expectedDarknessRelated: Set<Universal> = [.darkness, .shadows]
        expectNoDifference(darknessRelated, expectedDarknessRelated)

        let shadowsRelated = Universal.shadows.relatedUniversals
        expectNoDifference(shadowsRelated, expectedDarknessRelated)

        // Light
        let lightRelated = Universal.light.relatedUniversals
        expectNoDifference(lightRelated, [.light, .fire, .flames, .sun])

        // Sound related
        let silenceRelated = Universal.silence.relatedUniversals
        let expectedSoundRelated: Set<Universal> = [.silence, .sound, .noise]
        expectNoDifference(silenceRelated, expectedSoundRelated)

        let soundRelated = Universal.sound.relatedUniversals
        expectNoDifference(soundRelated, expectedSoundRelated)

        let noiseRelated = Universal.noise.relatedUniversals
        expectNoDifference(noiseRelated, expectedSoundRelated)
    }

    // MARK: - Boolean Property Tests

    @Test("isOutdoorElement property is correct")
    func testIsOutdoorElement() {
        // Should be outdoor elements
        let outdoorElements: [Universal] = [
            .clouds, .dirt, .earth, .heavens, .moon, .sky, .soil, .stars, .sun, .wind,
        ]
        for element in outdoorElements {
            #expect(element.isOutdoorElement, "\(element) should be an outdoor element")
        }

        // Should not be outdoor elements
        let notOutdoorElements: [Universal] = [.ceiling, .floor, .roof]
        for element in notOutdoorElements {
            #expect(!element.isOutdoorElement, "\(element) should not be an outdoor element")
        }

        // All others should be false (default case)
        let allOutdoorAndIndoorSpecific = Set(outdoorElements + notOutdoorElements)
        for element in Universal.allCases {
            if !allOutdoorAndIndoorSpecific.contains(element) {
                #expect(
                    !element.isOutdoorElement,
                    "\(element) should not be an outdoor element (default case)")
            }
        }
    }

    @Test("isIndoorElement property is correct")
    func testIsIndoorElement() {
        // Should be indoor elements
        let indoorElements: [Universal] = [.ceiling, .floor, .roof, .wall, .walls]
        for element in indoorElements {
            #expect(element.isIndoorElement, "\(element) should be an indoor element")
        }

        // Should not be indoor elements
        let notIndoorElements: [Universal] = [.heavens, .moon, .sky, .stars, .sun]
        for element in notIndoorElements {
            #expect(!element.isIndoorElement, "\(element) should not be an indoor element")
        }

        // All others should be true (default case)
        let allSpecified = Set(indoorElements + notIndoorElements)
        for element in Universal.allCases {
            if !allSpecified.contains(element) {
                #expect(
                    element.isIndoorElement, "\(element) should be an indoor element (default case)"
                )
            }
        }
    }

    @Test("isPhysical property is correct")
    func testIsPhysical() {
        // Should be physical
        let physicalElements: [Universal] = [
            .ceiling, .dirt, .earth, .floor, .ground, .lake, .mud, .ocean, .pond, .river,
            .rock, .roof, .sand, .sea, .soil, .stone, .stream, .wall, .walls, .water,
        ]
        for element in physicalElements {
            #expect(element.isPhysical, "\(element) should be physical")
        }

        // Should not be physical
        let nonPhysicalElements: [Universal] = [
            .air, .clouds, .darkness, .dust, .fire, .flames, .heavens, .light, .moon, .noise,
            .shadows, .silence, .sky, .smoke, .sound, .stars, .sun, .wind,
        ]
        for element in nonPhysicalElements {
            #expect(!element.isPhysical, "\(element) should not be physical")
        }

        // Verify we've covered all cases
        let allSpecified = Set(physicalElements + nonPhysicalElements)
        #expect(
            allSpecified.count == Universal.allCases.count,
            "Should have specified physical property for all cases")
    }

    @Test("isOutdoors property is correct")
    func testIsOutdoors() {
        let outdoorsElements: [Universal] = [
            .air, .clouds, .darkness, .dirt, .dust, .earth, .fire, .flames, .ground, .heavens,
            .lake, .light, .moon, .mud, .ocean, .pond, .river, .rock, .sand, .sea, .shadows,
            .sky, .smoke, .soil, .stars, .stone, .stream, .sun, .water, .wind,
        ]

        for element in outdoorsElements {
            #expect(element.isOutdoors, "\(element) should be found outdoors")
        }

        // All others should be false
        let outdoorsSet = Set(outdoorsElements)
        for element in Universal.allCases {
            if !outdoorsSet.contains(element) {
                #expect(!element.isOutdoors, "\(element) should not be found outdoors")
            }
        }
    }

    @Test("isIndoors property is correct")
    func testIsIndoors() {
        let indoorsElements: [Universal] = [
            .air, .ceiling, .darkness, .dust, .fire, .flames, .floor, .light, .noise, .roof,
            .shadows, .silence, .smoke, .sound, .wall, .walls, .water,
        ]

        for element in indoorsElements {
            #expect(element.isIndoors, "\(element) should be found indoors")
        }

        // All others should be false
        let indoorsSet = Set(indoorsElements)
        for element in Universal.allCases {
            if !indoorsSet.contains(element) {
                #expect(!element.isIndoors, "\(element) should not be found indoors")
            }
        }
    }

    @Test("isDiggable property is correct")
    func testIsDiggable() {
        let diggableElements: [Universal] = [.dirt, .earth, .ground, .mud, .sand, .soil]

        for element in diggableElements {
            #expect(element.isDiggable, "\(element) should be diggable")
        }

        // All others should be false
        let diggableSet = Set(diggableElements)
        for element in Universal.allCases {
            if !diggableSet.contains(element) {
                #expect(!element.isDiggable, "\(element) should not be diggable")
            }
        }
    }

    @Test("isWater property is correct")
    func testIsWater() {
        let waterElements: [Universal] = [
            .lake, .ocean, .pond, .river, .sea, .stream, .water,
        ]

        for element in waterElements {
            #expect(element.isWater, "\(element) should be water")
        }

        // All others should be false
        let waterSet = Set(waterElements)
        for element in Universal.allCases {
            if !waterSet.contains(element) {
                #expect(!element.isWater, "\(element) should not be water")
            }
        }
    }

    @Test("isArchitectural property is correct")
    func testIsArchitectural() {
        let architecturalElements: [Universal] = [.ceiling, .floor, .roof, .wall, .walls]

        for element in architecturalElements {
            #expect(element.isArchitectural, "\(element) should be architectural")
        }

        // All others should be false
        let architecturalSet = Set(architecturalElements)
        for element in Universal.allCases {
            if !architecturalSet.contains(element) {
                #expect(!element.isArchitectural, "\(element) should not be architectural")
            }
        }
    }

    // MARK: - CustomStringConvertible Tests

    @Test("CustomStringConvertible description returns raw value")
    func testCustomStringConvertible() {
        for universalObject in Universal.allCases {
            #expect(universalObject.description == universalObject.rawValue)
        }
    }

    @Test("String interpolation uses description")
    func testStringInterpolation() {
        let ground = Universal.ground
        let interpolated = "The universal object is \(ground)"
        #expect(interpolated == "The universal object is ground")

        let sky = Universal.sky
        let skyInterpolated = "Look at \(sky)"
        #expect(skyInterpolated == "Look at sky")
    }

    // MARK: - Integration and Edge Case Tests

    @Test("All universal objects have non-empty related universals")
    func testAllHaveRelatedUniversals() {
        for universalObject in Universal.allCases {
            #expect(
                !universalObject.relatedUniversals.isEmpty,
                "\(universalObject) should have related universals")
            #expect(
                universalObject.relatedUniversals.contains(universalObject),
                "\(universalObject) should be related to itself")
        }
    }

    @Test("Related universals are symmetric where expected")
    func testRelatedUniversalsSymmetry() {
        // Test specific symmetric relationships
        let symmetricPairs: [(Universal, Universal)] = [
            (.ground, .floor),
            (.sky, .heavens),
            (.walls, .wall),
            (.ceiling, .roof),
            (.fire, .flames),
            (.rock, .stone),
            (.darkness, .shadows),
        ]

        for (first, second) in symmetricPairs {
            #expect(first.matches(second), "\(first) should match \(second)")
            #expect(second.matches(first), "\(second) should match \(first)")
        }
    }

    @Test("Boolean properties are mutually exclusive where appropriate")
    func testBooleanPropertyConsistency() {
        // Some elements can be both indoors and outdoors (like air, water, etc.)
        // but some are exclusive (like ceiling vs sky)

        // Ceiling should be indoor only
        #expect(Universal.ceiling.isIndoorElement)
        #expect(!Universal.ceiling.isOutdoorElement)

        // Sky should be outdoor only
        #expect(Universal.sky.isOutdoorElement)
        #expect(!Universal.sky.isIndoorElement)

        // Floor should be indoor only
        #expect(Universal.floor.isIndoorElement)
        #expect(!Universal.floor.isOutdoorElement)
    }

    @Test("Logical property relationships")
    func testLogicalPropertyRelationships() {
        // All architectural elements should be physical
        for element in Universal.allCases where element.isArchitectural {
            #expect(element.isPhysical, "Architectural element \(element) should be physical")
        }

        // All water elements should be physical
        for element in Universal.allCases where element.isWater {
            #expect(element.isPhysical, "Water element \(element) should be physical")
        }

        // All diggable elements should be physical
        for element in Universal.allCases where element.isDiggable {
            #expect(element.isPhysical, "Diggable element \(element) should be physical")
        }
    }

    @Test("Raw value uniqueness")
    func testRawValueUniqueness() {
        let rawValues = Universal.allCases.map(\.rawValue)
        let uniqueRawValues = Set(rawValues)
        #expect(rawValues.count == uniqueRawValues.count, "All raw values should be unique")
    }

    @Test("Case count verification")
    func testCaseCount() {
        // This test will need to be updated if new cases are added
        // It serves as a reminder to update tests when the enum changes
        let expectedMinimumCount = 36  // Based on the cases visible in the enum
        #expect(
            Universal.allCases.count >= expectedMinimumCount,
            "Should have at least \(expectedMinimumCount) cases")
    }

    // MARK: - Set<Universal>.closestMatch Tests

    @Test("Set closestMatch returns exact match when found")
    func testClosestMatchExactMatch() {
        let universals: Set<Universal> = [.ground, .sky, .water, .fire]

        #expect(universals.closestMatch(to: "ground") == .ground)
        #expect(universals.closestMatch(to: "sky") == .sky)
        #expect(universals.closestMatch(to: "water") == .water)
        #expect(universals.closestMatch(to: "fire") == .fire)
    }

    @Test("Set closestMatch returns first sorted element when no exact match")
    func testClosestMatchFallback() {
        // When sorted: [.fire, .ground, .sky, .water]
        let universals: Set<Universal> = [.water, .ground, .sky, .fire]

        #expect(universals.closestMatch(to: "invalid") == .fire)
        #expect(universals.closestMatch(to: "nonexistent") == .fire)
        #expect(universals.closestMatch(to: "xyz") == .fire)
    }

    @Test("Set closestMatch deterministic fallback ordering")
    func testClosestMatchDeterministicFallback() {
        // Test that the fallback is deterministic by using same set multiple times
        let universals: Set<Universal> = [.walls, .air, .moon, .dust]

        let results = (1...10).map { _ in
            universals.closestMatch(to: "invalid")
        }

        // All results should be the same (deterministic)
        let firstResult = results[0]
        for result in results {
            #expect(result == firstResult)
        }

        // Should be the first alphabetically: [.air, .dust, .moon, .walls]
        #expect(firstResult == .air)
    }

    @Test("Set closestMatch with single element")
    func testClosestMatchSingleElement() {
        let universals: Set<Universal> = [.ground]

        // Exact match
        #expect(universals.closestMatch(to: "ground") == .ground)

        // No match - should return the single element
        #expect(universals.closestMatch(to: "invalid") == .ground)
    }

    @Test("Set closestMatch with empty set")
    func testClosestMatchEmptySet() {
        let universals: Set<Universal> = []

        #expect(universals.closestMatch(to: "ground") == nil)
        #expect(universals.closestMatch(to: "invalid") == nil)
        #expect(universals.closestMatch(to: "") == nil)
    }

    @Test("Set closestMatch is case sensitive")
    func testClosestMatchCaseSensitive() {
        let universals: Set<Universal> = [.ground, .sky, .water]

        // Exact case matches
        #expect(universals.closestMatch(to: "ground") == .ground)
        #expect(universals.closestMatch(to: "sky") == .sky)

        // Different case should not match - should fall back to first sorted
        #expect(universals.closestMatch(to: "Ground") == .ground)  // fallback: sorted = [.ground, .sky, .water]
        #expect(universals.closestMatch(to: "SKY") == .ground)  // fallback: sorted = [.ground, .sky, .water]
        #expect(universals.closestMatch(to: "WATER") == .ground)  // fallback: sorted = [.ground, .sky, .water]
    }

    @Test("Set closestMatch with edge case inputs")
    func testClosestMatchEdgeCases() {
        let universals: Set<Universal> = [.ground, .sky]

        // Empty string should not match - falls back to first sorted
        #expect(universals.closestMatch(to: "") == .ground)  // sorted = [.ground, .sky]

        // Whitespace should not match - falls back to first sorted
        #expect(universals.closestMatch(to: " ") == .ground)
        #expect(universals.closestMatch(to: "  ground  ") == .ground)  // not exact match due to whitespace

        // Special characters should not match - falls back to first sorted
        #expect(universals.closestMatch(to: "ground!") == .ground)
        #expect(universals.closestMatch(to: "sky?") == .ground)
    }

    @Test("Set closestMatch with all universal objects")
    func testClosestMatchWithAllObjects() {
        let universals = Set(Universal.allCases)

        // Test a few exact matches
        #expect(universals.closestMatch(to: "ground") == .ground)
        #expect(universals.closestMatch(to: "water") == .water)
        #expect(universals.closestMatch(to: "fire") == .fire)

        // Test fallback with invalid input - should return first alphabetically
        let sortedAll = Universal.allCases.sorted { $0.rawValue < $1.rawValue }
        let expectedFirst = sortedAll.first!
        #expect(universals.closestMatch(to: "invalid") == expectedFirst)
    }

    @Test("Set closestMatch preserves order independence")
    func testClosestMatchOrderIndependence() {
        // Same elements in different orders should produce same results
        let set1: Set<Universal> = [.water, .fire, .air, .earth]
        let set2: Set<Universal> = [.earth, .air, .fire, .water]
        let set3: Set<Universal> = [.fire, .earth, .water, .air]

        // Exact matches should be same regardless of set creation order
        #expect(set1.closestMatch(to: "water") == set2.closestMatch(to: "water"))
        #expect(set2.closestMatch(to: "fire") == set3.closestMatch(to: "fire"))

        // Fallbacks should be same regardless of set creation order
        #expect(set1.closestMatch(to: "invalid") == set2.closestMatch(to: "invalid"))
        #expect(set2.closestMatch(to: "invalid") == set3.closestMatch(to: "invalid"))
    }

    @Test("Set closestMatch with related universals")
    func testClosestMatchWithRelatedUniversals() {
        // Test with ground-related universals
        let groundRelated: Set<Universal> = [.ground, .floor, .earth, .soil, .dirt]

        // Exact matches work
        #expect(groundRelated.closestMatch(to: "ground") == .ground)
        #expect(groundRelated.closestMatch(to: "floor") == .floor)
        #expect(groundRelated.closestMatch(to: "earth") == .earth)

        // Fallback should be first sorted: [.dirt, .earth, .floor, .ground, .soil]
        #expect(groundRelated.closestMatch(to: "invalid") == .dirt)

        // Test with water-related universals
        let waterRelated: Set<Universal> = [.water, .river, .lake, .ocean, .sea]

        // Exact matches work
        #expect(waterRelated.closestMatch(to: "ocean") == .ocean)
        #expect(waterRelated.closestMatch(to: "river") == .river)

        // Fallback should be first sorted: [.lake, .ocean, .river, .sea, .water]
        #expect(waterRelated.closestMatch(to: "invalid") == .lake)
    }
}
