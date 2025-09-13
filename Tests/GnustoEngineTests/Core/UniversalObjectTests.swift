import CustomDump
import Foundation
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("UniversalObject Tests")
struct UniversalObjectTests {

    // MARK: - Basic Property Tests

    @Test("UniversalObject id property returns raw value")
    func testIdProperty() {
        #expect(UniversalObject.ground.id == "ground")
        #expect(UniversalObject.sky.id == "sky")
        #expect(UniversalObject.water.id == "water")
        #expect(UniversalObject.walls.id == "walls")
    }

    @Test("UniversalObject displayName property returns capitalized raw value")
    func testDisplayNameProperty() {
        #expect(UniversalObject.ground.displayName == "Ground")
        #expect(UniversalObject.sky.displayName == "Sky")
        #expect(UniversalObject.water.displayName == "Water")
        #expect(UniversalObject.walls.displayName == "Walls")
    }

    @Test("UniversalObject withDefiniteArticle property formats correctly")
    func testWithDefiniteArticleProperty() {
        #expect(UniversalObject.ground.withDefiniteArticle == "the ground")
        #expect(UniversalObject.sky.withDefiniteArticle == "the sky")
        #expect(UniversalObject.water.withDefiniteArticle == "the water")
        #expect(UniversalObject.walls.withDefiniteArticle == "the walls")
    }

    // MARK: - CaseIterable Tests

    @Test("UniversalObject conforms to CaseIterable")
    func testCaseIterable() {
        let allCases = UniversalObject.allCases

        #expect(allCases.count > 0)
        #expect(allCases.contains(.ground))
        #expect(allCases.contains(.sky))
        #expect(allCases.contains(.water))
        #expect(allCases.contains(.walls))

        // Verify no duplicates
        let uniqueCases = Set(allCases)
        #expect(uniqueCases.count == allCases.count)
    }

    @Test("UniversalObject contains expected cases")
    func testExpectedCases() {
        let allCases = UniversalObject.allCases

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

    @Test("UniversalObject encodes and decodes correctly")
    func testCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for universalObject in UniversalObject.allCases {
            let encoded = try encoder.encode(universalObject)
            let decoded = try decoder.decode(UniversalObject.self, from: encoded)
            #expect(decoded == universalObject)
        }
    }

    @Test("UniversalObject encodes to expected JSON string")
    func testEncodesToString() throws {
        let encoder = JSONEncoder()

        let groundData = try encoder.encode(UniversalObject.ground)
        let groundString = String(data: groundData, encoding: .utf8)
        #expect(groundString == "\"ground\"")

        let skyData = try encoder.encode(UniversalObject.sky)
        let skyString = String(data: skyData, encoding: .utf8)
        #expect(skyString == "\"sky\"")
    }

    // MARK: - Matches Method Tests

    @Test("UniversalObject matches method works with related objects")
    func testMatchesMethod() {
        // Ground-related objects should match each other
        #expect(UniversalObject.ground.matches(.floor))
        #expect(UniversalObject.ground.matches(.earth))
        #expect(UniversalObject.floor.matches(.ground))

        // Sky-related objects should match each other
        #expect(UniversalObject.sky.matches(.heavens))
        #expect(UniversalObject.heavens.matches(.sky))
        #expect(UniversalObject.sky.matches(.air))

        // Water-related objects should match each other
        #expect(UniversalObject.water.matches(.river))
        #expect(UniversalObject.river.matches(.water))
        #expect(UniversalObject.lake.matches(.ocean))

        // Unrelated objects should not match
        #expect(!UniversalObject.ground.matches(.sky))
        #expect(!UniversalObject.water.matches(.fire))
        #expect(!UniversalObject.walls.matches(.river))
    }

    @Test("UniversalObject matches itself through relatedUniversals")
    func testMatchesSelf() {
        for universalObject in UniversalObject.allCases {
            #expect(universalObject.relatedUniversals.contains(universalObject))
        }
    }

    // MARK: - Related Universals Tests

    @Test("Ground and floor related universals are correct")
    func testGroundRelatedUniversals() {
        let groundRelated = UniversalObject.ground.relatedUniversals
        let expectedGroundRelated: Set<UniversalObject> = [.ground, .floor, .earth, .soil, .dirt]
        expectNoDifference(groundRelated, expectedGroundRelated)

        let floorRelated = UniversalObject.floor.relatedUniversals
        expectNoDifference(floorRelated, expectedGroundRelated)
    }

    @Test("Earth, soil, dirt related universals are correct")
    func testEarthRelatedUniversals() {
        let earthRelated = UniversalObject.earth.relatedUniversals
        let expectedEarthRelated: Set<UniversalObject> = [.ground, .earth, .soil, .dirt]
        expectNoDifference(earthRelated, expectedEarthRelated)

        let soilRelated = UniversalObject.soil.relatedUniversals
        expectNoDifference(soilRelated, expectedEarthRelated)

        let dirtRelated = UniversalObject.dirt.relatedUniversals
        expectNoDifference(dirtRelated, expectedEarthRelated)
    }

    @Test("Sky and heavens related universals are correct")
    func testSkyRelatedUniversals() {
        let skyRelated = UniversalObject.sky.relatedUniversals
        let expectedSkyRelated: Set<UniversalObject> = [.sky, .heavens, .air, .clouds]
        expectNoDifference(skyRelated, expectedSkyRelated)

        let heavensRelated = UniversalObject.heavens.relatedUniversals
        expectNoDifference(heavensRelated, expectedSkyRelated)
    }

    @Test("Air and clouds related universals are correct")
    func testAirRelatedUniversals() {
        let airRelated = UniversalObject.air.relatedUniversals
        let expectedAirRelated: Set<UniversalObject> = [.sky, .air, .clouds]
        expectNoDifference(airRelated, expectedAirRelated)

        let cloudsRelated = UniversalObject.clouds.relatedUniversals
        expectNoDifference(cloudsRelated, expectedAirRelated)
    }

    @Test("Celestial objects related universals are correct")
    func testCelestialRelatedUniversals() {
        let expectedCelestialRelated: Set<UniversalObject> = [.sun, .moon, .stars, .sky, .heavens]

        let sunRelated = UniversalObject.sun.relatedUniversals
        expectNoDifference(sunRelated, expectedCelestialRelated)

        let moonRelated = UniversalObject.moon.relatedUniversals
        expectNoDifference(moonRelated, expectedCelestialRelated)

        let starsRelated = UniversalObject.stars.relatedUniversals
        expectNoDifference(starsRelated, expectedCelestialRelated)
    }

    @Test("Wall related universals are correct")
    func testWallRelatedUniversals() {
        let wallsRelated = UniversalObject.walls.relatedUniversals
        let expectedWallRelated: Set<UniversalObject> = [.walls, .wall, .ceiling, .floor]
        expectNoDifference(wallsRelated, expectedWallRelated)

        let wallRelated = UniversalObject.wall.relatedUniversals
        expectNoDifference(wallRelated, expectedWallRelated)
    }

    @Test("Ceiling and roof related universals are correct")
    func testCeilingRelatedUniversals() {
        let ceilingRelated = UniversalObject.ceiling.relatedUniversals
        let expectedCeilingRelated: Set<UniversalObject> = [.ceiling, .roof]
        expectNoDifference(ceilingRelated, expectedCeilingRelated)

        let roofRelated = UniversalObject.roof.relatedUniversals
        expectNoDifference(roofRelated, expectedCeilingRelated)
    }

    @Test("Water related universals are correct")
    func testWaterRelatedUniversals() {
        let expectedWaterRelated: Set<UniversalObject> = [
            .water, .river, .stream, .lake, .pond, .ocean, .sea,
        ]

        for waterObject in [UniversalObject.water, .river, .stream, .lake, .pond, .ocean, .sea] {
            let related = waterObject.relatedUniversals
            expectNoDifference(related, expectedWaterRelated)
        }
    }

    @Test("Fire related universals are correct")
    func testFireRelatedUniversals() {
        let fireRelated = UniversalObject.fire.relatedUniversals
        let expectedFireRelated: Set<UniversalObject> = [.fire, .flames, .smoke, .light]
        expectNoDifference(fireRelated, expectedFireRelated)

        let flamesRelated = UniversalObject.flames.relatedUniversals
        expectNoDifference(flamesRelated, expectedFireRelated)
    }

    @Test("Remaining related universals are correct")
    func testRemainingRelatedUniversals() {
        // Wind
        let windRelated = UniversalObject.wind.relatedUniversals
        expectNoDifference(windRelated, [.wind, .air])

        // Smoke
        let smokeRelated = UniversalObject.smoke.relatedUniversals
        expectNoDifference(smokeRelated, [.smoke, .fire, .air])

        // Dust, mud, sand
        let dustRelated = UniversalObject.dust.relatedUniversals
        let expectedDustRelated: Set<UniversalObject> = [.dust, .mud, .sand, .dirt, .earth]
        expectNoDifference(dustRelated, expectedDustRelated)

        let mudRelated = UniversalObject.mud.relatedUniversals
        expectNoDifference(mudRelated, expectedDustRelated)

        let sandRelated = UniversalObject.sand.relatedUniversals
        expectNoDifference(sandRelated, expectedDustRelated)

        // Rock and stone
        let rockRelated = UniversalObject.rock.relatedUniversals
        let expectedRockRelated: Set<UniversalObject> = [.rock, .stone, .earth]
        expectNoDifference(rockRelated, expectedRockRelated)

        let stoneRelated = UniversalObject.stone.relatedUniversals
        expectNoDifference(stoneRelated, expectedRockRelated)

        // Darkness and shadows
        let darknessRelated = UniversalObject.darkness.relatedUniversals
        let expectedDarknessRelated: Set<UniversalObject> = [.darkness, .shadows]
        expectNoDifference(darknessRelated, expectedDarknessRelated)

        let shadowsRelated = UniversalObject.shadows.relatedUniversals
        expectNoDifference(shadowsRelated, expectedDarknessRelated)

        // Light
        let lightRelated = UniversalObject.light.relatedUniversals
        expectNoDifference(lightRelated, [.light, .fire, .flames, .sun])

        // Sound related
        let silenceRelated = UniversalObject.silence.relatedUniversals
        let expectedSoundRelated: Set<UniversalObject> = [.silence, .sound, .noise]
        expectNoDifference(silenceRelated, expectedSoundRelated)

        let soundRelated = UniversalObject.sound.relatedUniversals
        expectNoDifference(soundRelated, expectedSoundRelated)

        let noiseRelated = UniversalObject.noise.relatedUniversals
        expectNoDifference(noiseRelated, expectedSoundRelated)
    }

    // MARK: - Boolean Property Tests

    @Test("isOutdoorElement property is correct")
    func testIsOutdoorElement() {
        // Should be outdoor elements
        let outdoorElements: [UniversalObject] = [
            .clouds, .dirt, .earth, .heavens, .moon, .sky, .soil, .stars, .sun, .wind,
        ]
        for element in outdoorElements {
            #expect(element.isOutdoorElement, "\(element) should be an outdoor element")
        }

        // Should not be outdoor elements
        let notOutdoorElements: [UniversalObject] = [.ceiling, .floor, .roof]
        for element in notOutdoorElements {
            #expect(!element.isOutdoorElement, "\(element) should not be an outdoor element")
        }

        // All others should be false (default case)
        let allOutdoorAndIndoorSpecific = Set(outdoorElements + notOutdoorElements)
        for element in UniversalObject.allCases {
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
        let indoorElements: [UniversalObject] = [.ceiling, .floor, .roof, .wall, .walls]
        for element in indoorElements {
            #expect(element.isIndoorElement, "\(element) should be an indoor element")
        }

        // Should not be indoor elements
        let notIndoorElements: [UniversalObject] = [.heavens, .moon, .sky, .stars, .sun]
        for element in notIndoorElements {
            #expect(!element.isIndoorElement, "\(element) should not be an indoor element")
        }

        // All others should be true (default case)
        let allSpecified = Set(indoorElements + notIndoorElements)
        for element in UniversalObject.allCases {
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
        let physicalElements: [UniversalObject] = [
            .ceiling, .dirt, .earth, .floor, .ground, .lake, .mud, .ocean, .pond, .river,
            .rock, .roof, .sand, .sea, .soil, .stone, .stream, .wall, .walls, .water,
        ]
        for element in physicalElements {
            #expect(element.isPhysical, "\(element) should be physical")
        }

        // Should not be physical
        let nonPhysicalElements: [UniversalObject] = [
            .air, .clouds, .darkness, .dust, .fire, .flames, .heavens, .light, .moon, .noise,
            .shadows, .silence, .sky, .smoke, .sound, .stars, .sun, .wind,
        ]
        for element in nonPhysicalElements {
            #expect(!element.isPhysical, "\(element) should not be physical")
        }

        // Verify we've covered all cases
        let allSpecified = Set(physicalElements + nonPhysicalElements)
        #expect(
            allSpecified.count == UniversalObject.allCases.count,
            "Should have specified physical property for all cases")
    }

    @Test("isOutdoors property is correct")
    func testIsOutdoors() {
        let outdoorsElements: [UniversalObject] = [
            .air, .clouds, .darkness, .dirt, .dust, .earth, .fire, .flames, .ground, .heavens,
            .lake, .light, .moon, .mud, .ocean, .pond, .river, .rock, .sand, .sea, .shadows,
            .sky, .smoke, .soil, .stars, .stone, .stream, .sun, .water, .wind,
        ]

        for element in outdoorsElements {
            #expect(element.isOutdoors, "\(element) should be found outdoors")
        }

        // All others should be false
        let outdoorsSet = Set(outdoorsElements)
        for element in UniversalObject.allCases {
            if !outdoorsSet.contains(element) {
                #expect(!element.isOutdoors, "\(element) should not be found outdoors")
            }
        }
    }

    @Test("isIndoors property is correct")
    func testIsIndoors() {
        let indoorsElements: [UniversalObject] = [
            .air, .ceiling, .darkness, .dust, .fire, .flames, .floor, .light, .noise, .roof,
            .shadows, .silence, .smoke, .sound, .wall, .walls, .water,
        ]

        for element in indoorsElements {
            #expect(element.isIndoors, "\(element) should be found indoors")
        }

        // All others should be false
        let indoorsSet = Set(indoorsElements)
        for element in UniversalObject.allCases {
            if !indoorsSet.contains(element) {
                #expect(!element.isIndoors, "\(element) should not be found indoors")
            }
        }
    }

    @Test("isDiggable property is correct")
    func testIsDiggable() {
        let diggableElements: [UniversalObject] = [.dirt, .earth, .ground, .mud, .sand, .soil]

        for element in diggableElements {
            #expect(element.isDiggable, "\(element) should be diggable")
        }

        // All others should be false
        let diggableSet = Set(diggableElements)
        for element in UniversalObject.allCases {
            if !diggableSet.contains(element) {
                #expect(!element.isDiggable, "\(element) should not be diggable")
            }
        }
    }

    @Test("isWater property is correct")
    func testIsWater() {
        let waterElements: [UniversalObject] = [
            .lake, .ocean, .pond, .river, .sea, .stream, .water,
        ]

        for element in waterElements {
            #expect(element.isWater, "\(element) should be water")
        }

        // All others should be false
        let waterSet = Set(waterElements)
        for element in UniversalObject.allCases {
            if !waterSet.contains(element) {
                #expect(!element.isWater, "\(element) should not be water")
            }
        }
    }

    @Test("isArchitectural property is correct")
    func testIsArchitectural() {
        let architecturalElements: [UniversalObject] = [.ceiling, .floor, .roof, .wall, .walls]

        for element in architecturalElements {
            #expect(element.isArchitectural, "\(element) should be architectural")
        }

        // All others should be false
        let architecturalSet = Set(architecturalElements)
        for element in UniversalObject.allCases {
            if !architecturalSet.contains(element) {
                #expect(!element.isArchitectural, "\(element) should not be architectural")
            }
        }
    }

    // MARK: - CustomStringConvertible Tests

    @Test("CustomStringConvertible description returns raw value")
    func testCustomStringConvertible() {
        for universalObject in UniversalObject.allCases {
            #expect(universalObject.description == universalObject.rawValue)
        }
    }

    @Test("String interpolation uses description")
    func testStringInterpolation() {
        let ground = UniversalObject.ground
        let interpolated = "The universal object is \(ground)"
        #expect(interpolated == "The universal object is ground")

        let sky = UniversalObject.sky
        let skyInterpolated = "Look at \(sky)"
        #expect(skyInterpolated == "Look at sky")
    }

    // MARK: - Integration and Edge Case Tests

    @Test("All universal objects have non-empty related universals")
    func testAllHaveRelatedUniversals() {
        for universalObject in UniversalObject.allCases {
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
        let symmetricPairs: [(UniversalObject, UniversalObject)] = [
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
        #expect(UniversalObject.ceiling.isIndoorElement)
        #expect(!UniversalObject.ceiling.isOutdoorElement)

        // Sky should be outdoor only
        #expect(UniversalObject.sky.isOutdoorElement)
        #expect(!UniversalObject.sky.isIndoorElement)

        // Floor should be indoor only
        #expect(UniversalObject.floor.isIndoorElement)
        #expect(!UniversalObject.floor.isOutdoorElement)
    }

    @Test("Logical property relationships")
    func testLogicalPropertyRelationships() {
        // All architectural elements should be physical
        for element in UniversalObject.allCases where element.isArchitectural {
            #expect(element.isPhysical, "Architectural element \(element) should be physical")
        }

        // All water elements should be physical
        for element in UniversalObject.allCases where element.isWater {
            #expect(element.isPhysical, "Water element \(element) should be physical")
        }

        // All diggable elements should be physical
        for element in UniversalObject.allCases where element.isDiggable {
            #expect(element.isPhysical, "Diggable element \(element) should be physical")
        }
    }

    @Test("Raw value uniqueness")
    func testRawValueUniqueness() {
        let rawValues = UniversalObject.allCases.map(\.rawValue)
        let uniqueRawValues = Set(rawValues)
        #expect(rawValues.count == uniqueRawValues.count, "All raw values should be unique")
    }

    @Test("Case count verification")
    func testCaseCount() {
        // This test will need to be updated if new cases are added
        // It serves as a reminder to update tests when the enum changes
        let expectedMinimumCount = 36  // Based on the cases visible in the enum
        #expect(
            UniversalObject.allCases.count >= expectedMinimumCount,
            "Should have at least \(expectedMinimumCount) cases")
    }
}
