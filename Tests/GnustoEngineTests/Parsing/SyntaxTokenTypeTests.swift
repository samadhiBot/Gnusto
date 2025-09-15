import Foundation
import GnustoTestSupport
import Testing

@testable import GnustoEngine

/// Comprehensive tests for the `SyntaxTokenType` enum.
///
/// Tests all enum cases, conformances, static properties, and associated values.
struct SyntaxTokenTypeTests {

    // MARK: - Basic Enum Case Tests

    @Test("All basic enum cases can be created")
    func testBasicEnumCases() throws {
        let basicCases: [SyntaxTokenType] = [
            .verb,
            .specificVerb(.take),
            .directObject,
            .directObjects,
            .indirectObject,
            .indirectObjects,
            .direction,
            .particle("test"),
        ]

        #expect(basicCases.count == 8)
    }

    @Test("Verb case can be created")
    func testVerbCase() throws {
        let verbToken = SyntaxTokenType.verb

        if case .verb = verbToken {
            // Test passes
        } else {
            #expect(Bool(false), "Token should be .verb")
        }
    }

    @Test("SpecificVerb case with associated value can be created")
    func testSpecificVerbCase() throws {
        let specificVerbToken = SyntaxTokenType.specificVerb(.take)

        if case .specificVerb(let verb) = specificVerbToken {
            #expect(verb == .take)
        } else {
            #expect(Bool(false), "Token should be .specificVerb")
        }
    }

    @Test("DirectObject case can be created")
    func testDirectObjectCase() throws {
        let directObjectToken = SyntaxTokenType.directObject

        if case .directObject = directObjectToken {
            // Test passes
        } else {
            #expect(Bool(false), "Token should be .directObject")
        }
    }

    @Test("DirectObjects case can be created")
    func testDirectObjectsCase() throws {
        let directObjectsToken = SyntaxTokenType.directObjects

        if case .directObjects = directObjectsToken {
            // Test passes
        } else {
            #expect(Bool(false), "Token should be .directObjects")
        }
    }

    @Test("IndirectObject case can be created")
    func testIndirectObjectCase() throws {
        let indirectObjectToken = SyntaxTokenType.indirectObject

        if case .indirectObject = indirectObjectToken {
            // Test passes
        } else {
            #expect(Bool(false), "Token should be .indirectObject")
        }
    }

    @Test("IndirectObjects case can be created")
    func testIndirectObjectsCase() throws {
        let indirectObjectsToken = SyntaxTokenType.indirectObjects

        if case .indirectObjects = indirectObjectsToken {
            // Test passes
        } else {
            #expect(Bool(false), "Token should be .indirectObjects")
        }
    }

    @Test("Direction case can be created")
    func testDirectionCase() throws {
        let directionToken = SyntaxTokenType.direction

        if case .direction = directionToken {
            // Test passes
        } else {
            #expect(Bool(false), "Token should be .direction")
        }
    }

    @Test("Particle case with associated value can be created")
    func testParticleCase() throws {
        let particleToken = SyntaxTokenType.particle("on")

        if case .particle(let particleValue) = particleToken {
            #expect(particleValue == "on")
        } else {
            #expect(Bool(false), "Token should be .particle")
        }
    }

    // MARK: - Equality Tests

    @Test("Same enum cases are equal")
    func testEquality() throws {
        #expect(SyntaxTokenType.verb == SyntaxTokenType.verb)
        #expect(SyntaxTokenType.directObject == SyntaxTokenType.directObject)
        #expect(SyntaxTokenType.direction == SyntaxTokenType.direction)
        #expect(SyntaxTokenType.specificVerb(.take) == SyntaxTokenType.specificVerb(.take))
        #expect(SyntaxTokenType.particle("on") == SyntaxTokenType.particle("on"))
    }

    @Test("Different enum cases are not equal")
    func testInequality() throws {
        #expect(SyntaxTokenType.verb != SyntaxTokenType.directObject)
        #expect(SyntaxTokenType.directObject != SyntaxTokenType.directObjects)
        #expect(SyntaxTokenType.indirectObject != SyntaxTokenType.indirectObjects)
        #expect(SyntaxTokenType.specificVerb(.take) != SyntaxTokenType.specificVerb(.drop))
        #expect(SyntaxTokenType.particle("on") != SyntaxTokenType.particle("off"))
        #expect(SyntaxTokenType.verb != SyntaxTokenType.specificVerb(.take))
    }

    @Test("Same cases with different associated values are not equal")
    func testDifferentAssociatedValues() throws {
        #expect(SyntaxTokenType.specificVerb(.take) != SyntaxTokenType.specificVerb(.drop))
        #expect(SyntaxTokenType.particle("in") != SyntaxTokenType.particle("on"))
        #expect(SyntaxTokenType.particle("UP") != SyntaxTokenType.particle("up"))
    }

    // MARK: - Codable Tests

    @Test("All SyntaxTokenType cases are Codable")
    func testCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let testCases: [SyntaxTokenType] = [
            .verb,
            .specificVerb(.take),
            .directObject,
            .directObjects,
            .indirectObject,
            .indirectObjects,
            .direction,
            .particle("on"),
            .particle("with"),
        ]

        for tokenType in testCases {
            let encodedData = try encoder.encode(tokenType)
            let decodedTokenType = try decoder.decode(SyntaxTokenType.self, from: encodedData)
            #expect(decodedTokenType == tokenType, "Failed encoding/decoding for \(tokenType)")
        }
    }

    @Test("Complex SyntaxTokenType cases encode and decode correctly")
    func testComplexCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let complexToken = SyntaxTokenType.specificVerb(.examine)

        let encodedData = try encoder.encode(complexToken)
        let decodedToken = try decoder.decode(SyntaxTokenType.self, from: encodedData)

        #expect(decodedToken == complexToken)

        if case .specificVerb(let verb) = decodedToken {
            #expect(verb == .examine)
        } else {
            #expect(Bool(false), "Decoded token should be .specificVerb")
        }
    }

    // MARK: - ExpressibleByStringLiteral Tests

    @Test("SyntaxTokenType supports string literal initialization")
    func testStringLiteralInitialization() throws {
        let onToken: SyntaxTokenType = "on"
        let offToken: SyntaxTokenType = "off"
        let customToken: SyntaxTokenType = "customParticle"

        #expect(onToken == .particle("on"))
        #expect(offToken == .particle("off"))
        #expect(customToken == .particle("customParticle"))
    }

    @Test("String literal creates particle tokens")
    func testStringLiteralCreatesParticle() throws {
        let literalToken: SyntaxTokenType = "test"

        if case .particle(let value) = literalToken {
            #expect(value == "test")
        } else {
            #expect(Bool(false), "String literal should create .particle token")
        }
    }

    // MARK: - Static Preposition Properties Tests

    @Test("All preposition properties exist and have correct values")
    func testPrepositionProperties() throws {
        #expect(SyntaxTokenType.about == .particle("about"))
        #expect(SyntaxTokenType.at == .particle("at"))
        #expect(SyntaxTokenType.behind == .particle("behind"))
        #expect(SyntaxTokenType.below == .particle("below"))
        #expect(SyntaxTokenType.beneath == .particle("beneath"))
        #expect(SyntaxTokenType.down == .particle("down"))
        #expect(SyntaxTokenType.for == .particle("for"))
        #expect(SyntaxTokenType.from == .particle("from"))
        #expect(SyntaxTokenType.in == .particle("in"))
        #expect(SyntaxTokenType.inside == .particle("inside"))
        #expect(SyntaxTokenType.into == .particle("into"))
        #expect(SyntaxTokenType.off == .particle("off"))
        #expect(SyntaxTokenType.on == .particle("on"))
        #expect(SyntaxTokenType.onto == .particle("onto"))
        #expect(SyntaxTokenType.out == .particle("out"))
        #expect(SyntaxTokenType.over == .particle("over"))
        #expect(SyntaxTokenType.through == .particle("through"))
        #expect(SyntaxTokenType.to == .particle("to"))
        #expect(SyntaxTokenType.under == .particle("under"))
        #expect(SyntaxTokenType.up == .particle("up"))
        #expect(SyntaxTokenType.with == .particle("with"))
    }

    @Test("Preposition properties are distinct from each other")
    func testPrepositionPropertiesDistinct() throws {
        let prepositions: [SyntaxTokenType] = [
            .about, .at, .behind, .below, .beneath, .down, .for, .from,
            .in, .inside, .into, .off, .on, .onto, .out, .over,
            .through, .to, .under, .up, .with,
        ]

        // All prepositions should be unique - test by comparing each pair
        for i in 0..<prepositions.count {
            for j in (i + 1)..<prepositions.count {
                #expect(
                    prepositions[i] != prepositions[j],
                    "Prepositions at indices \(i) and \(j) should be different")
            }
        }
    }

    // MARK: - Verb Factory Method Tests

    @Test("Verb factory method creates specificVerb tokens")
    func testVerbFactoryMethod() throws {
        let takeToken = SyntaxTokenType.verb(.take)
        let dropToken = SyntaxTokenType.verb(.drop)
        let examineToken = SyntaxTokenType.verb(.examine)

        #expect(takeToken == .specificVerb(.take))
        #expect(dropToken == .specificVerb(.drop))
        #expect(examineToken == .specificVerb(.examine))
    }

    @Test("Verb factory method produces different tokens for different verbs")
    func testVerbFactoryMethodDistinct() throws {
        let takeToken = SyntaxTokenType.verb(.take)
        let dropToken = SyntaxTokenType.verb(.drop)

        #expect(takeToken != dropToken)
        #expect(takeToken == .specificVerb(.take))
        #expect(dropToken == .specificVerb(.drop))
    }

    // MARK: - Associated Values Tests

    @Test("SpecificVerb associated values work correctly")
    func testSpecificVerbAssociatedValues() throws {
        let tokens: [SyntaxTokenType] = [
            .specificVerb(.take),
            .specificVerb(.drop),
            .specificVerb(.examine),
        ]

        for token in tokens {
            if case .specificVerb(let verb) = token {
                switch token {
                case .specificVerb(.take):
                    #expect(verb == .take)
                case .specificVerb(.drop):
                    #expect(verb == .drop)
                case .specificVerb(.examine):
                    #expect(verb == .examine)
                default:
                    #expect(Bool(false), "Unexpected token case")
                }
            } else {
                #expect(Bool(false), "Token should be .specificVerb")
            }
        }
    }

    @Test("Particle associated values work correctly")
    func testParticleAssociatedValues() throws {
        let particles = ["on", "off", "in", "out", "with", "about"]

        for particleValue in particles {
            let token = SyntaxTokenType.particle(particleValue)

            if case .particle(let value) = token {
                #expect(value == particleValue)
            } else {
                #expect(Bool(false), "Token should be .particle")
            }
        }
    }

    // MARK: - Pattern Matching Tests

    @Test("Pattern matching works correctly")
    func testPatternMatching() throws {
        let tokens: [SyntaxTokenType] = [
            .verb,
            .specificVerb(.take),
            .directObject,
            .directObjects,
            .indirectObject,
            .indirectObjects,
            .direction,
            .particle("on"),
        ]

        var verbCount = 0
        var specificVerbCount = 0
        var directObjectCount = 0
        var directObjectsCount = 0
        var indirectObjectCount = 0
        var indirectObjectsCount = 0
        var directionCount = 0
        var particleCount = 0

        for token in tokens {
            switch token {
            case .verb:
                verbCount += 1
            case .specificVerb:
                specificVerbCount += 1
            case .directObject:
                directObjectCount += 1
            case .directObjects:
                directObjectsCount += 1
            case .indirectObject:
                indirectObjectCount += 1
            case .indirectObjects:
                indirectObjectsCount += 1
            case .direction:
                directionCount += 1
            case .particle:
                particleCount += 1
            }
        }

        #expect(verbCount == 1)
        #expect(specificVerbCount == 1)
        #expect(directObjectCount == 1)
        #expect(directObjectsCount == 1)
        #expect(indirectObjectCount == 1)
        #expect(indirectObjectsCount == 1)
        #expect(directionCount == 1)
        #expect(particleCount == 1)
    }

    // MARK: - Equatable Tests

    @Test("SyntaxTokenType equality works correctly")
    func testEquatable() throws {
        let tokens: [SyntaxTokenType] = [
            .verb,
            .specificVerb(.take),
            .directObject,
            .directObjects,
            .indirectObject,
            .indirectObjects,
            .direction,
            .particle("on"),
            .particle("off"),
        ]

        #expect(tokens.count == 9)
        #expect(tokens.contains(.verb))
        #expect(tokens.contains(.specificVerb(.take)))
        #expect(tokens.contains(.particle("on")))
    }

    @Test("Same SyntaxTokenType instances are equal")
    func testEqualityConsistency() throws {
        let token1 = SyntaxTokenType.specificVerb(.take)
        let token2 = SyntaxTokenType.specificVerb(.take)

        #expect(token1 == token2)
    }

    // MARK: - Collections Tests

    @Test("SyntaxTokenType works in collections")
    func testInCollections() throws {
        let tokenArray: [SyntaxTokenType] = [
            .verb,
            .directObject,
            .particle("on"),
            .specificVerb(.take),
        ]

        #expect(tokenArray.count == 4)
        #expect(tokenArray.contains(.verb))
        #expect(tokenArray.contains(.directObject))
        #expect(tokenArray.contains(.particle("on")))
        #expect(tokenArray.contains(.specificVerb(.take)))
    }

    @Test("SyntaxTokenType array lookup works correctly")
    func testArrayLookup() throws {
        let tokenPairs: [(SyntaxTokenType, String)] = [
            (.verb, "verb"),
            (.directObject, "direct object"),
            (.particle("on"), "on particle"),
            (.specificVerb(.take), "take verb"),
        ]

        for (token, expectedDescription) in tokenPairs {
            let foundPair = tokenPairs.first { $0.0 == token }
            #expect(foundPair?.1 == expectedDescription)
        }
    }

    // MARK: - Edge Cases

    @Test("Empty particle string works")
    func testEmptyParticle() throws {
        let emptyParticleToken = SyntaxTokenType.particle("")

        if case .particle(let value) = emptyParticleToken {
            #expect(value == "")
        } else {
            #expect(Bool(false), "Token should be .particle with empty string")
        }
    }

    @Test("Particle with whitespace works")
    func testParticleWithWhitespace() throws {
        let whitespaceParticleToken = SyntaxTokenType.particle(" on ")

        if case .particle(let value) = whitespaceParticleToken {
            #expect(value == " on ")
        } else {
            #expect(Bool(false), "Token should be .particle with whitespace")
        }
    }

    @Test("Case-sensitive particle comparison")
    func testCaseSensitiveParticle() throws {
        let lowerToken = SyntaxTokenType.particle("on")
        let upperToken = SyntaxTokenType.particle("ON")
        let mixedToken = SyntaxTokenType.particle("On")

        #expect(lowerToken != upperToken)
        #expect(lowerToken != mixedToken)
        #expect(upperToken != mixedToken)
    }

    // MARK: - Integration with Verb Tests

    @Test("SyntaxTokenType integrates correctly with Verb types")
    func testVerbIntegration() throws {
        let commonVerbs: [Verb] = [.take, .drop, .examine, .look, .go]

        for verb in commonVerbs {
            let specificVerbToken = SyntaxTokenType.specificVerb(verb)
            let factoryToken = SyntaxTokenType.verb(verb)

            #expect(specificVerbToken == factoryToken)

            if case .specificVerb(let extractedVerb) = specificVerbToken {
                #expect(extractedVerb == verb)
            } else {
                #expect(Bool(false), "Token should be .specificVerb")
            }
        }
    }
}

// MARK: - Test Helper Extensions

extension Verb {
    fileprivate static let take = Verb("take")
    fileprivate static let drop = Verb("drop")
    fileprivate static let examine = Verb("examine")
    fileprivate static let look = Verb("look")
    fileprivate static let go = Verb("go")
}
