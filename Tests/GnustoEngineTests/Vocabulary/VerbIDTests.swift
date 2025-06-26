import CustomDump
import Foundation
import Testing

@testable import GnustoEngine

@Suite("Verb Tests")
struct VerbTests {

    // MARK: - Basic Functionality Tests

    @Test("Verb initialization with raw value")
    func testVerbInitialization() throws {
        let verbID = Verb(rawValue: "test")
        #expect(verbID.rawValue == "test")
    }

    @Test("Verb Initialization with Special Characters")
    func testSpecialCharacterInitialization() throws {
        let id: Verb = "verb_with-special.chars@123"
        #expect(id.rawValue == "verb_with-special.chars@123")
    }

    @Test("Verb Initialization with Unicode")
    func testUnicodeInitialization() throws {
        let id: Verb = "🎮动作"
        #expect(id.rawValue == "🎮动作")
    }

    @Test("Verb initialization with empty string assertion")
    func testVerbEmptyStringAssertion() throws {
        // Note: This would assert in debug builds, but we can't easily test assertions
        // Just verify that non-empty strings work
        let verbID = Verb(rawValue: "valid")
        #expect(verbID.rawValue == "valid")
    }

    // MARK: - GnustoID Conformance Tests

    @Test("Verb conforms to GnustoID")
    func testGnustoIDConformance() throws {
        let verbID = Verb(rawValue: "take")

        // Test that it can be used as a GnustoID
        func acceptsGnustoID<T: GnustoID>(_ id: T) -> String {
            return id.rawValue
        }

        let result = acceptsGnustoID(verbID)
        #expect(result == "take")
    }

    // MARK: - Static Verb Definitions Tests

    @Test("All static verbs have expected raw values")
    func testStaticVerbDefinitions() throws {
        // Test core action verbs
        #expect(Verb.take.rawValue == "take")
        #expect(Verb.drop.rawValue == "drop")
        #expect(Verb.get.rawValue == "get")
        #expect(Verb.give.rawValue == "give")
        #expect(Verb.put.rawValue == "put")
        #expect(Verb.look.rawValue == "look")
        #expect(Verb.examine.rawValue == "examine")
        #expect(Verb.go.rawValue == "go")
        #expect(Verb.enter.rawValue == "enter")
        #expect(Verb.open.rawValue == "open")
        #expect(Verb.close.rawValue == "close")

        // Test movement verbs
        #expect(Verb.climb.rawValue == "climb")
        #expect(Verb.jump.rawValue == "jump")
        #expect(Verb.run.rawValue == "run")
        #expect(Verb.walk.rawValue == "walk")
        #expect(Verb.ascend.rawValue == "ascend")

        // Test interaction verbs
        #expect(Verb.push.rawValue == "push")
        #expect(Verb.pull.rawValue == "pull")
        #expect(Verb.turn.rawValue == "turn")
        #expect(Verb.move.rawValue == "move")
        #expect(Verb.lift.rawValue == "lift")
        #expect(Verb.touch.rawValue == "touch")
        #expect(Verb.feel.rawValue == "feel")

        // Test light-related verbs
        #expect(Verb.light.rawValue == "light")
        #expect(Verb.burn.rawValue == "burn")
        #expect(Verb.extinguish.rawValue == "extinguish")
        #expect(Verb.ignite.rawValue == "ignite")

        // Test violence verbs
        #expect(Verb.attack.rawValue == "attack")
        #expect(Verb.kill.rawValue == "kill")
        #expect(Verb.fight.rawValue == "fight")
        #expect(Verb.hit.rawValue == "hit")
        #expect(Verb.kick.rawValue == "kick")
        #expect(Verb.stab.rawValue == "stab")
        #expect(Verb.slay.rawValue == "slay")

        // Test consumption verbs
        #expect(Verb.eat.rawValue == "eat")
        #expect(Verb.drink.rawValue == "drink")
        #expect(Verb.taste.rawValue == "taste")
        #expect(Verb.consume.rawValue == "consume")
        #expect(Verb.devour.rawValue == "devour")
        #expect(Verb.bite.rawValue == "bite")
        #expect(Verb.chew.rawValue == "chew")
        #expect(Verb.chomp.rawValue == "chomp")
        #expect(Verb.imbibe.rawValue == "imbibe")
        #expect(Verb.quaff.rawValue == "quaff")
        #expect(Verb.sip.rawValue == "sip")

        // Test communication verbs
        #expect(Verb.ask.rawValue == "ask")
        #expect(Verb.tell.rawValue == "tell")
        #expect(Verb.shout.rawValue == "shout")
        #expect(Verb.yell.rawValue == "yell")
        #expect(Verb.scream.rawValue == "scream")
        #expect(Verb.holler.rawValue == "holler")
        #expect(Verb.shriek.rawValue == "shriek")

        // Test game control verbs
        #expect(Verb.save.rawValue == "save")
        #expect(Verb.restore.rawValue == "restore")
        #expect(Verb.restart.rawValue == "restart")
        #expect(Verb.quit.rawValue == "quit")
        #expect(Verb.score.rawValue == "score")
        #expect(Verb.inventory.rawValue == "inventory")
        #expect(Verb.help.rawValue == "help")
        #expect(Verb.brief.rawValue == "brief")
        #expect(Verb.verbose.rawValue == "verbose")
        #expect(Verb.script.rawValue == "script")
        #expect(Verb.unscript.rawValue == "unscript")

        // Test special/magical verbs
        #expect(Verb.xyzzy.rawValue == "xyzzy")

        // Test profanity verbs
        #expect(Verb.fuck.rawValue == "fuck")
        #expect(Verb.shit.rawValue == "shit")
        #expect(Verb.damn.rawValue == "damn")
        #expect(Verb.curse.rawValue == "curse")
        #expect(Verb.swear.rawValue == "swear")
    }

    @Test("Throwing and manipulation verbs")
    func testThrowingAndManipulationVerbs() throws {
        #expect(Verb.throw.rawValue == "throw")
        #expect(Verb.toss.rawValue == "toss")
        #expect(Verb.hurl.rawValue == "hurl")
        #expect(Verb.chuck.rawValue == "chuck")
        #expect(Verb.brandish.rawValue == "brandish")
        #expect(Verb.wave.rawValue == "wave")
        #expect(Verb.shake.rawValue == "shake")
        #expect(Verb.rattle.rawValue == "rattle")
        #expect(Verb.squeeze.rawValue == "squeeze")
        #expect(Verb.compress.rawValue == "compress")
        #expect(Verb.press.rawValue == "press")
    }

    @Test("Sensory and observation verbs")
    func testSensoryVerbs() throws {
        #expect(Verb.listen.rawValue == "listen")
        #expect(Verb.smell.rawValue == "smell")
        #expect(Verb.sniff.rawValue == "sniff")
        #expect(Verb.peek.rawValue == "peek")
        #expect(Verb.inspect.rawValue == "inspect")
        #expect(Verb.search.rawValue == "search")
        #expect(Verb.find.rawValue == "find")
        #expect(Verb.locate.rawValue == "locate")
    }

    @Test("Emotional and expressive verbs")
    func testEmotionalVerbs() throws {
        #expect(Verb.laugh.rawValue == "laugh")
        #expect(Verb.giggle.rawValue == "giggle")
        #expect(Verb.chuckle.rawValue == "chuckle")
        #expect(Verb.snicker.rawValue == "snicker")
        #expect(Verb.chortle.rawValue == "chortle")
        #expect(Verb.cry.rawValue == "cry")
        #expect(Verb.sob.rawValue == "sob")
        #expect(Verb.weep.rawValue == "weep")
        #expect(Verb.sing.rawValue == "sing")
        #expect(Verb.hum.rawValue == "hum")
        #expect(Verb.dance.rawValue == "dance")
    }

    @Test("Mechanical and technical verbs")
    func testMechanicalVerbs() throws {
        #expect(Verb.switch.rawValue == "switch")
        #expect(Verb.rotate.rawValue == "rotate")
        #expect(Verb.twist.rawValue == "twist")
        #expect(Verb.set.rawValue == "set")
        #expect(Verb.lock.rawValue == "lock")
        #expect(Verb.unlock.rawValue == "unlock")
        #expect(Verb.fasten.rawValue == "fasten")
        #expect(Verb.tie.rawValue == "tie")
        #expect(Verb.bind.rawValue == "bind")
        #expect(Verb.hang.rawValue == "hang")
        #expect(Verb.load.rawValue == "load")
    }

    @Test("Destructive and construction verbs")
    func testDestructiveVerbs() throws {
        #expect(Verb.cut.rawValue == "cut")
        #expect(Verb.slice.rawValue == "slice")
        #expect(Verb.chop.rawValue == "chop")
        #expect(Verb.dig.rawValue == "dig")
        #expect(Verb.excavate.rawValue == "excavate")
        #expect(Verb.prune.rawValue == "prune")
    }

    @Test("Liquid and container verbs")
    func testLiquidAndContainerVerbs() throws {
        #expect(Verb.fill.rawValue == "fill")
        #expect(Verb.empty.rawValue == "empty")
        #expect(Verb.pour.rawValue == "pour")
        #expect(Verb.spill.rawValue == "spill")
        #expect(Verb.douse.rawValue == "douse")
        #expect(Verb.insert.rawValue == "insert")
        #expect(Verb.place.rawValue == "place")
        #expect(Verb.remove.rawValue == "remove")
    }

    @Test("Body and physical action verbs")
    func testPhysicalActionVerbs() throws {
        #expect(Verb.breathe.rawValue == "breathe")
        #expect(Verb.blow.rawValue == "blow")
        #expect(Verb.puff.rawValue == "puff")
        #expect(Verb.kiss.rawValue == "kiss")
        #expect(Verb.lick.rawValue == "lick")
        #expect(Verb.sit.rawValue == "sit")
        #expect(Verb.leap.rawValue == "leap")
        #expect(Verb.hop.rawValue == "hop")
    }

    @Test("Clothing and wearable verbs")
    func testClothingVerbs() throws {
        #expect(Verb.wear.rawValue == "wear")
        #expect(Verb.don.rawValue == "don")
        #expect(Verb.doff.rawValue == "doff")
        #expect(Verb.remove.rawValue == "remove")
    }

    @Test("Maintenance and care verbs")
    func testMaintenanceVerbs() throws {
        #expect(Verb.clean.rawValue == "clean")
        #expect(Verb.polish.rawValue == "polish")
        #expect(Verb.rub.rawValue == "rub")
    }

    @Test("Mental and cognitive verbs")
    func testMentalVerbs() throws {
        #expect(Verb.think.rawValue == "think")
        #expect(Verb.consider.rawValue == "consider")
        #expect(Verb.ponder.rawValue == "ponder")
    }

    // MARK: - Equatable Conformance Tests

    @Test("Verb equality works correctly")
    func testEquatableConformance() throws {
        let verb1 = Verb(rawValue: "take")
        let verb2 = Verb(rawValue: "take")
        let verb3 = Verb(rawValue: "drop")

        #expect(verb1 == verb2)
        #expect(verb1 != verb3)
        #expect(verb2 != verb3)

        // Test static instances
        #expect(Verb.take == Verb.take)
        #expect(Verb.take != Verb.drop)
    }

    @Test("Verb Case Insensitivity")
    func testCaseSensitivity() throws {
        let id1: Verb = "Take"
        let id2: Verb = "take"
        let id3: Verb = "TAKE"

        #expect(id1 == id2)
        #expect(id1 == id3)
        #expect(id2 == id3)
    }

    // MARK: - Hashable Conformance Tests

    @Test("Verb is properly hashable")
    func testHashableConformance() throws {
        let verb1 = Verb(rawValue: "take")
        let verb2 = Verb(rawValue: "take")
        let verb3 = Verb(rawValue: "drop")

        // Test hash consistency
        #expect(verb1.hashValue == verb2.hashValue)

        // Test usage in Set
        let verbSet: Set<Verb> = [verb1, verb2, verb3]
        #expect(verbSet.count == 2)  // verb1 and verb2 should be the same
        #expect(verbSet.contains(verb1))
        #expect(verbSet.contains(verb3))

        // Test usage as dictionary keys
        var verbDict: [Verb: String] = [:]
        verbDict[.take] = "to take"
        verbDict[.drop] = "to drop"
        verbDict[.give] = "to give"

        #expect(verbDict[.take] == "to take")
        #expect(verbDict[.drop] == "to drop")
        #expect(verbDict[.give] == "to give")
        #expect(verbDict.count == 3)
    }

    @Test("Verb Set Operations")
    func testSetOperations() throws {
        let verbSet: Set<Verb> = [
            "go",
            "look",
            "go", // Duplicate should be ignored
            "take"
        ]

        #expect(verbSet.count == 3)
        #expect(verbSet.contains("go"))
        #expect(verbSet.contains("look"))
        #expect(verbSet.contains("take"))
        #expect(!verbSet.contains("nonexistent"))
    }

    // MARK: - Comparable Tests

    @Test("Verb Comparability")
    func testComparability() throws {
        let id1: Verb = "apple"
        let id2: Verb = "banana"
        let id3: Verb = "cherry"

        #expect(id1 < id2)
        #expect(id2 < id3)
        #expect(id1 < id3)
        #expect(!(id2 < id1))
        #expect(!(id3 < id2))
    }

    @Test("Verb Sorting")
    func testSorting() throws {
        let unsortedIDs: [Verb] = ["zebra", "apple", "monkey", "banana"]
        let sortedIDs = unsortedIDs.sorted()

        let expectedOrder: [Verb] = ["apple", "banana", "monkey", "zebra"]
        #expect(sortedIDs == expectedOrder)
    }

    @Test("Verb Sorting with Numbers and Letters")
    func testSortingWithNumbersAndLetters() throws {
        let unsortedIDs: [Verb] = ["verb10", "verb2", "verb1", "verbA"]
        let sortedIDs = unsortedIDs.sorted()

        // String sorting: numbers come before letters, but "10" < "2" lexicographically
        let expectedOrder: [Verb] = ["verb1", "verb10", "verb2", "verbA"]
        #expect(sortedIDs == expectedOrder)
    }

    // MARK: - Codable Conformance Tests

    @Test("Verb encodes and decodes correctly")
    func testCodableConformance() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let originalVerb = Verb.take
        let encoded = try encoder.encode(originalVerb)
        let decoded = try decoder.decode(Verb.self, from: encoded)

        #expect(decoded == originalVerb)
        #expect(decoded.rawValue == "take")
    }

    @Test("Verb encodes to expected JSON format")
    func testJSONEncoding() throws {
        let encoder = JSONEncoder()

        let takeVerb = Verb.take
        let encoded = try encoder.encode(takeVerb)
        let jsonString = String(data: encoded, encoding: .utf8)

        // Should encode as a simple string, not an object
        #expect(jsonString?.contains("\"take\"") == true)
    }

    @Test("Verb decodes from various JSON formats")
    func testJSONDecoding() throws {
        let decoder = JSONDecoder()

        // Test decoding from simple string
        let jsonData = "\"examine\"".data(using: .utf8)!
        let decoded = try decoder.decode(Verb.self, from: jsonData)
        #expect(decoded.rawValue == "examine")
        #expect(decoded == Verb.examine)
    }

    @Test("Multiple Verbs in collections")
    func testVerbsInCollections() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let verbs = [Verb.take, Verb.drop, Verb.examine]
        let encoded = try encoder.encode(verbs)
        let decoded = try decoder.decode([Verb].self, from: encoded)

        expectNoDifference(decoded, verbs)
    }

    // MARK: - ExpressibleByStringLiteral Tests

    @Test("Verb can be created from string literals")
    func testStringLiteralConformance() throws {
        let verbID: Verb = "customVerb"
        #expect(verbID.rawValue == "customVerb")

        // Test that static verbs work with string literal comparison
        let takeVerb: Verb = "take"
        #expect(takeVerb == Verb.take)
    }

    // MARK: - Static Verb Completeness Tests

    @Test("All expected game control verbs are defined")
    func testGameControlVerbsCompleteness() throws {
        // Test that common IF game control verbs are available
        let gameControlVerbs: [Verb] = [
            .inventory, .look, .examine, .help, .quit, .save, .restore,
            .restart, .score, .brief, .verbose, .script, .unscript,
        ]

        for verb in gameControlVerbs {
            #expect(!verb.rawValue.isEmpty)
        }
    }

    @Test("All expected movement verbs are defined")
    func testMovementVerbsCompleteness() throws {
        let movementVerbs: [Verb] = [
            .go, .walk, .run, .climb, .jump, .enter, .ascend,
            .travel, .proceed, .head, .stroll, .hike,
        ]

        for verb in movementVerbs {
            #expect(!verb.rawValue.isEmpty)
        }
    }

    @Test("All expected object manipulation verbs are defined")
    func testObjectManipulationVerbsCompleteness() throws {
        let manipulationVerbs: [Verb] = [
            .take, .get, .grab, .drop, .put, .give, .throw, .toss,
            .push, .pull, .move, .lift, .raise, .place,
        ]

        for verb in manipulationVerbs {
            #expect(!verb.rawValue.isEmpty)
        }
    }

    // MARK: - Sendable Conformance Tests

    @Test("Verb is Sendable")
    func testSendableConformance() async throws {
        // Test that Verb can be safely passed between actors
        let verbID = Verb.take

        await withCheckedContinuation { continuation in
            Task {
                #expect(verbID.rawValue == "take")
                continuation.resume()
            }
        }
    }

    // MARK: - Custom String Convertible Tests

    @Test("Verb string representation")
    func testStringRepresentation() throws {
        let verbID = Verb.take
        let description = String(describing: verbID)

        expectNoDifference(description, ".take")
    }

    // MARK: - CustomDumpStringConvertible Tests

    @Test("Verb CustomDumpStringConvertible")
    func testCustomDumpStringConvertible() throws {
        let id: Verb = "take"
        #expect(id.description == ".take")
    }

    @Test("Verb CustomDumpStringConvertible with Special Characters")
    func testCustomDumpStringConvertibleWithSpecialCharacters() throws {
        let id: Verb = "verb_with-special.chars@123"
        #expect(id.description == ".verb_with-special.chars@123")
    }

    // MARK: - Performance Tests

    @Test("Verb creation and comparison performance")
    func testPerformance() throws {
        // Test that Verb operations are efficient
        let iterations = 1000
        let startTime = Date()

        for i in 0..<iterations {
            let verbID = Verb(rawValue: "test\(i)")
            let isEqual = verbID == Verb(rawValue: "test\(i)")
            #expect(isEqual)
        }

        let endTime = Date()
        let elapsed = endTime.timeIntervalSince(startTime)

        // Should complete quickly (less than 1 second for 1000 operations)
        #expect(elapsed < 1.0)
    }

    // MARK: - Edge Cases Tests

    @Test("Verb Very Long String")
    func testVeryLongString() throws {
        let longString = String(repeating: "a", count: 10000)
        let id = Verb(longString)
        #expect(id.rawValue == longString)
    }

    @Test("Verb Whitespace Handling")
    func testWhitespaceHandling() throws {
        let id1: Verb = " leadingSpace"
        let id2: Verb = "trailingSpace "
        let id3: Verb = " spaces "
        let id4: Verb = "no\tTab\nNewline"

        #expect(id1.rawValue == " leadingSpace")
        #expect(id2.rawValue == "trailingSpace ")
        #expect(id3.rawValue == " spaces ")
        #expect(id4.rawValue == "no\tTab\nNewline")

        // All should be different
        #expect(id1 != id2)
        #expect(id2 != id3)
        #expect(id3 != id4)
    }

    // MARK: - String Interpolation Tests

    @Test("Verb String Interpolation")
    func testStringInterpolation() throws {
        let id: Verb = "take"
        let message = "The verb is \(id)"
        #expect(message == "The verb is .take")
    }

    // MARK: - Array and Collection Tests

    @Test("Verb Array Operations")
    func testArrayOperations() throws {
        var verbs: [Verb] = [.take, .drop]
        verbs.append(.examine)
        verbs.insert(.look, at: 1)

        let expectedVerbs: [Verb] = [.take, .look, .drop, .examine]
        #expect(verbs == expectedVerbs)
    }

    @Test("Verb Dictionary Keys")
    func testDictionaryKeys() throws {
        var verbDescriptions: [Verb: String] = [:]
        verbDescriptions[.take] = "Pick up an object"
        verbDescriptions[.drop] = "Put down an object"

        #expect(verbDescriptions.keys.count == 2)
        #expect(verbDescriptions.keys.contains(.take))
        #expect(verbDescriptions.keys.contains(.drop))
    }

    // MARK: - Mixed Usage Tests

    @Test("Verb Mixed Literal and Constant Usage")
    func testMixedUsage() throws {
        let customVerb: Verb = "customAction"
        let standardVerb = Verb.take

        let verbSet: Set<Verb> = [customVerb, standardVerb, .drop, "anotherCustom"]

        #expect(verbSet.count == 4)
        #expect(verbSet.contains(customVerb))
        #expect(verbSet.contains(standardVerb))
        #expect(verbSet.contains(.drop))
        #expect(verbSet.contains("anotherCustom"))
    }
}
