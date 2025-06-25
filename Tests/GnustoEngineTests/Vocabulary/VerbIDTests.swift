import CustomDump
import Foundation
import Testing

@testable import GnustoEngine

@Suite("VerbID Tests")
struct VerbIDTests {

    // MARK: - Basic Functionality Tests

    @Test("VerbID initialization with raw value")
    func testVerbIDInitialization() throws {
        let verbID = VerbID(rawValue: "test")
        #expect(verbID.rawValue == "test")
    }

    @Test("VerbID Initialization with Special Characters")
    func testSpecialCharacterInitialization() throws {
        let id: VerbID = "verb_with-special.chars@123"
        #expect(id.rawValue == "verb_with-special.chars@123")
    }

    @Test("VerbID Initialization with Unicode")
    func testUnicodeInitialization() throws {
        let id: VerbID = "🎮动作"
        #expect(id.rawValue == "🎮动作")
    }

    @Test("VerbID initialization with empty string assertion")
    func testVerbIDEmptyStringAssertion() throws {
        // Note: This would assert in debug builds, but we can't easily test assertions
        // Just verify that non-empty strings work
        let verbID = VerbID(rawValue: "valid")
        #expect(verbID.rawValue == "valid")
    }

    // MARK: - GnustoID Conformance Tests

    @Test("VerbID conforms to GnustoID")
    func testGnustoIDConformance() throws {
        let verbID = VerbID(rawValue: "take")

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
        #expect(VerbID.take.rawValue == "take")
        #expect(VerbID.drop.rawValue == "drop")
        #expect(VerbID.get.rawValue == "get")
        #expect(VerbID.give.rawValue == "give")
        #expect(VerbID.put.rawValue == "put")
        #expect(VerbID.look.rawValue == "look")
        #expect(VerbID.examine.rawValue == "examine")
        #expect(VerbID.go.rawValue == "go")
        #expect(VerbID.enter.rawValue == "enter")
        #expect(VerbID.open.rawValue == "open")
        #expect(VerbID.close.rawValue == "close")

        // Test movement verbs
        #expect(VerbID.climb.rawValue == "climb")
        #expect(VerbID.jump.rawValue == "jump")
        #expect(VerbID.run.rawValue == "run")
        #expect(VerbID.walk.rawValue == "walk")
        #expect(VerbID.ascend.rawValue == "ascend")

        // Test interaction verbs
        #expect(VerbID.push.rawValue == "push")
        #expect(VerbID.pull.rawValue == "pull")
        #expect(VerbID.turn.rawValue == "turn")
        #expect(VerbID.move.rawValue == "move")
        #expect(VerbID.lift.rawValue == "lift")
        #expect(VerbID.touch.rawValue == "touch")
        #expect(VerbID.feel.rawValue == "feel")

        // Test light-related verbs
        #expect(VerbID.light.rawValue == "light")
        #expect(VerbID.burn.rawValue == "burn")
        #expect(VerbID.extinguish.rawValue == "extinguish")
        #expect(VerbID.ignite.rawValue == "ignite")

        // Test violence verbs
        #expect(VerbID.attack.rawValue == "attack")
        #expect(VerbID.kill.rawValue == "kill")
        #expect(VerbID.fight.rawValue == "fight")
        #expect(VerbID.hit.rawValue == "hit")
        #expect(VerbID.kick.rawValue == "kick")
        #expect(VerbID.stab.rawValue == "stab")
        #expect(VerbID.slay.rawValue == "slay")

        // Test consumption verbs
        #expect(VerbID.eat.rawValue == "eat")
        #expect(VerbID.drink.rawValue == "drink")
        #expect(VerbID.taste.rawValue == "taste")
        #expect(VerbID.consume.rawValue == "consume")
        #expect(VerbID.devour.rawValue == "devour")
        #expect(VerbID.bite.rawValue == "bite")
        #expect(VerbID.chew.rawValue == "chew")
        #expect(VerbID.chomp.rawValue == "chomp")
        #expect(VerbID.imbibe.rawValue == "imbibe")
        #expect(VerbID.quaff.rawValue == "quaff")
        #expect(VerbID.sip.rawValue == "sip")

        // Test communication verbs
        #expect(VerbID.ask.rawValue == "ask")
        #expect(VerbID.tell.rawValue == "tell")
        #expect(VerbID.shout.rawValue == "shout")
        #expect(VerbID.yell.rawValue == "yell")
        #expect(VerbID.scream.rawValue == "scream")
        #expect(VerbID.holler.rawValue == "holler")
        #expect(VerbID.shriek.rawValue == "shriek")

        // Test game control verbs
        #expect(VerbID.save.rawValue == "save")
        #expect(VerbID.restore.rawValue == "restore")
        #expect(VerbID.restart.rawValue == "restart")
        #expect(VerbID.quit.rawValue == "quit")
        #expect(VerbID.score.rawValue == "score")
        #expect(VerbID.inventory.rawValue == "inventory")
        #expect(VerbID.help.rawValue == "help")
        #expect(VerbID.brief.rawValue == "brief")
        #expect(VerbID.verbose.rawValue == "verbose")
        #expect(VerbID.script.rawValue == "script")
        #expect(VerbID.unscript.rawValue == "unscript")

        // Test special/magical verbs
        #expect(VerbID.xyzzy.rawValue == "xyzzy")

        // Test profanity verbs
        #expect(VerbID.fuck.rawValue == "fuck")
        #expect(VerbID.shit.rawValue == "shit")
        #expect(VerbID.damn.rawValue == "damn")
        #expect(VerbID.curse.rawValue == "curse")
        #expect(VerbID.swear.rawValue == "swear")
    }

    @Test("Throwing and manipulation verbs")
    func testThrowingAndManipulationVerbs() throws {
        #expect(VerbID.throw.rawValue == "throw")
        #expect(VerbID.toss.rawValue == "toss")
        #expect(VerbID.hurl.rawValue == "hurl")
        #expect(VerbID.chuck.rawValue == "chuck")
        #expect(VerbID.brandish.rawValue == "brandish")
        #expect(VerbID.wave.rawValue == "wave")
        #expect(VerbID.shake.rawValue == "shake")
        #expect(VerbID.rattle.rawValue == "rattle")
        #expect(VerbID.squeeze.rawValue == "squeeze")
        #expect(VerbID.compress.rawValue == "compress")
        #expect(VerbID.press.rawValue == "press")
    }

    @Test("Sensory and observation verbs")
    func testSensoryVerbs() throws {
        #expect(VerbID.listen.rawValue == "listen")
        #expect(VerbID.smell.rawValue == "smell")
        #expect(VerbID.sniff.rawValue == "sniff")
        #expect(VerbID.peek.rawValue == "peek")
        #expect(VerbID.inspect.rawValue == "inspect")
        #expect(VerbID.search.rawValue == "search")
        #expect(VerbID.find.rawValue == "find")
        #expect(VerbID.locate.rawValue == "locate")
    }

    @Test("Emotional and expressive verbs")
    func testEmotionalVerbs() throws {
        #expect(VerbID.laugh.rawValue == "laugh")
        #expect(VerbID.giggle.rawValue == "giggle")
        #expect(VerbID.chuckle.rawValue == "chuckle")
        #expect(VerbID.snicker.rawValue == "snicker")
        #expect(VerbID.chortle.rawValue == "chortle")
        #expect(VerbID.cry.rawValue == "cry")
        #expect(VerbID.sob.rawValue == "sob")
        #expect(VerbID.weep.rawValue == "weep")
        #expect(VerbID.sing.rawValue == "sing")
        #expect(VerbID.hum.rawValue == "hum")
        #expect(VerbID.dance.rawValue == "dance")
    }

    @Test("Mechanical and technical verbs")
    func testMechanicalVerbs() throws {
        #expect(VerbID.switch.rawValue == "switch")
        #expect(VerbID.rotate.rawValue == "rotate")
        #expect(VerbID.twist.rawValue == "twist")
        #expect(VerbID.set.rawValue == "set")
        #expect(VerbID.lock.rawValue == "lock")
        #expect(VerbID.unlock.rawValue == "unlock")
        #expect(VerbID.fasten.rawValue == "fasten")
        #expect(VerbID.tie.rawValue == "tie")
        #expect(VerbID.bind.rawValue == "bind")
        #expect(VerbID.hang.rawValue == "hang")
        #expect(VerbID.load.rawValue == "load")
    }

    @Test("Destructive and construction verbs")
    func testDestructiveVerbs() throws {
        #expect(VerbID.cut.rawValue == "cut")
        #expect(VerbID.slice.rawValue == "slice")
        #expect(VerbID.chop.rawValue == "chop")
        #expect(VerbID.dig.rawValue == "dig")
        #expect(VerbID.excavate.rawValue == "excavate")
        #expect(VerbID.prune.rawValue == "prune")
    }

    @Test("Liquid and container verbs")
    func testLiquidAndContainerVerbs() throws {
        #expect(VerbID.fill.rawValue == "fill")
        #expect(VerbID.empty.rawValue == "empty")
        #expect(VerbID.pour.rawValue == "pour")
        #expect(VerbID.spill.rawValue == "spill")
        #expect(VerbID.douse.rawValue == "douse")
        #expect(VerbID.insert.rawValue == "insert")
        #expect(VerbID.place.rawValue == "place")
        #expect(VerbID.remove.rawValue == "remove")
    }

    @Test("Body and physical action verbs")
    func testPhysicalActionVerbs() throws {
        #expect(VerbID.breathe.rawValue == "breathe")
        #expect(VerbID.blow.rawValue == "blow")
        #expect(VerbID.puff.rawValue == "puff")
        #expect(VerbID.kiss.rawValue == "kiss")
        #expect(VerbID.lick.rawValue == "lick")
        #expect(VerbID.sit.rawValue == "sit")
        #expect(VerbID.leap.rawValue == "leap")
        #expect(VerbID.hop.rawValue == "hop")
    }

    @Test("Clothing and wearable verbs")
    func testClothingVerbs() throws {
        #expect(VerbID.wear.rawValue == "wear")
        #expect(VerbID.don.rawValue == "don")
        #expect(VerbID.doff.rawValue == "doff")
        #expect(VerbID.remove.rawValue == "remove")
    }

    @Test("Maintenance and care verbs")
    func testMaintenanceVerbs() throws {
        #expect(VerbID.clean.rawValue == "clean")
        #expect(VerbID.polish.rawValue == "polish")
        #expect(VerbID.rub.rawValue == "rub")
    }

    @Test("Mental and cognitive verbs")
    func testMentalVerbs() throws {
        #expect(VerbID.think.rawValue == "think")
        #expect(VerbID.consider.rawValue == "consider")
        #expect(VerbID.ponder.rawValue == "ponder")
    }

    // MARK: - Equatable Conformance Tests

    @Test("VerbID equality works correctly")
    func testEquatableConformance() throws {
        let verb1 = VerbID(rawValue: "take")
        let verb2 = VerbID(rawValue: "take")
        let verb3 = VerbID(rawValue: "drop")

        #expect(verb1 == verb2)
        #expect(verb1 != verb3)
        #expect(verb2 != verb3)

        // Test static instances
        #expect(VerbID.take == VerbID.take)
        #expect(VerbID.take != VerbID.drop)
    }

    @Test("VerbID Case Insensitivity")
    func testCaseSensitivity() throws {
        let id1: VerbID = "Take"
        let id2: VerbID = "take"
        let id3: VerbID = "TAKE"

        #expect(id1 == id2)
        #expect(id1 == id3)
        #expect(id2 == id3)
    }

    // MARK: - Hashable Conformance Tests

    @Test("VerbID is properly hashable")
    func testHashableConformance() throws {
        let verb1 = VerbID(rawValue: "take")
        let verb2 = VerbID(rawValue: "take")
        let verb3 = VerbID(rawValue: "drop")

        // Test hash consistency
        #expect(verb1.hashValue == verb2.hashValue)

        // Test usage in Set
        let verbSet: Set<VerbID> = [verb1, verb2, verb3]
        #expect(verbSet.count == 2)  // verb1 and verb2 should be the same
        #expect(verbSet.contains(verb1))
        #expect(verbSet.contains(verb3))

        // Test usage as dictionary keys
        var verbDict: [VerbID: String] = [:]
        verbDict[.take] = "to take"
        verbDict[.drop] = "to drop"
        verbDict[.give] = "to give"

        #expect(verbDict[.take] == "to take")
        #expect(verbDict[.drop] == "to drop")
        #expect(verbDict[.give] == "to give")
        #expect(verbDict.count == 3)
    }

    @Test("VerbID Set Operations")
    func testSetOperations() throws {
        let verbSet: Set<VerbID> = [
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

    @Test("VerbID Comparability")
    func testComparability() throws {
        let id1: VerbID = "apple"
        let id2: VerbID = "banana"
        let id3: VerbID = "cherry"

        #expect(id1 < id2)
        #expect(id2 < id3)
        #expect(id1 < id3)
        #expect(!(id2 < id1))
        #expect(!(id3 < id2))
    }

    @Test("VerbID Sorting")
    func testSorting() throws {
        let unsortedIDs: [VerbID] = ["zebra", "apple", "monkey", "banana"]
        let sortedIDs = unsortedIDs.sorted()

        let expectedOrder: [VerbID] = ["apple", "banana", "monkey", "zebra"]
        #expect(sortedIDs == expectedOrder)
    }

    @Test("VerbID Sorting with Numbers and Letters")
    func testSortingWithNumbersAndLetters() throws {
        let unsortedIDs: [VerbID] = ["verb10", "verb2", "verb1", "verbA"]
        let sortedIDs = unsortedIDs.sorted()

        // String sorting: numbers come before letters, but "10" < "2" lexicographically
        let expectedOrder: [VerbID] = ["verb1", "verb10", "verb2", "verbA"]
        #expect(sortedIDs == expectedOrder)
    }

    // MARK: - Codable Conformance Tests

    @Test("VerbID encodes and decodes correctly")
    func testCodableConformance() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let originalVerb = VerbID.take
        let encoded = try encoder.encode(originalVerb)
        let decoded = try decoder.decode(VerbID.self, from: encoded)

        #expect(decoded == originalVerb)
        #expect(decoded.rawValue == "take")
    }

    @Test("VerbID encodes to expected JSON format")
    func testJSONEncoding() throws {
        let encoder = JSONEncoder()

        let takeVerb = VerbID.take
        let encoded = try encoder.encode(takeVerb)
        let jsonString = String(data: encoded, encoding: .utf8)

        // Should encode as a simple string, not an object
        #expect(jsonString?.contains("\"take\"") == true)
    }

    @Test("VerbID decodes from various JSON formats")
    func testJSONDecoding() throws {
        let decoder = JSONDecoder()

        // Test decoding from simple string
        let jsonData = "\"examine\"".data(using: .utf8)!
        let decoded = try decoder.decode(VerbID.self, from: jsonData)
        #expect(decoded.rawValue == "examine")
        #expect(decoded == VerbID.examine)
    }

    @Test("Multiple VerbIDs in collections")
    func testVerbIDsInCollections() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let verbs = [VerbID.take, VerbID.drop, VerbID.examine]
        let encoded = try encoder.encode(verbs)
        let decoded = try decoder.decode([VerbID].self, from: encoded)

        expectNoDifference(decoded, verbs)
    }

    // MARK: - ExpressibleByStringLiteral Tests

    @Test("VerbID can be created from string literals")
    func testStringLiteralConformance() throws {
        let verbID: VerbID = "customVerb"
        #expect(verbID.rawValue == "customVerb")

        // Test that static verbs work with string literal comparison
        let takeVerb: VerbID = "take"
        #expect(takeVerb == VerbID.take)
    }

    // MARK: - Static Verb Completeness Tests

    @Test("All expected game control verbs are defined")
    func testGameControlVerbsCompleteness() throws {
        // Test that common IF game control verbs are available
        let gameControlVerbs: [VerbID] = [
            .inventory, .look, .examine, .help, .quit, .save, .restore,
            .restart, .score, .brief, .verbose, .script, .unscript,
        ]

        for verb in gameControlVerbs {
            #expect(!verb.rawValue.isEmpty)
        }
    }

    @Test("All expected movement verbs are defined")
    func testMovementVerbsCompleteness() throws {
        let movementVerbs: [VerbID] = [
            .go, .walk, .run, .climb, .jump, .enter, .ascend,
            .travel, .proceed, .head, .stroll, .hike,
        ]

        for verb in movementVerbs {
            #expect(!verb.rawValue.isEmpty)
        }
    }

    @Test("All expected object manipulation verbs are defined")
    func testObjectManipulationVerbsCompleteness() throws {
        let manipulationVerbs: [VerbID] = [
            .take, .get, .grab, .drop, .put, .give, .throw, .toss,
            .push, .pull, .move, .lift, .raise, .place,
        ]

        for verb in manipulationVerbs {
            #expect(!verb.rawValue.isEmpty)
        }
    }

    // MARK: - Sendable Conformance Tests

    @Test("VerbID is Sendable")
    func testSendableConformance() async throws {
        // Test that VerbID can be safely passed between actors
        let verbID = VerbID.take

        await withCheckedContinuation { continuation in
            Task {
                #expect(verbID.rawValue == "take")
                continuation.resume()
            }
        }
    }

    // MARK: - Custom String Convertible Tests

    @Test("VerbID string representation")
    func testStringRepresentation() throws {
        let verbID = VerbID.take
        let description = String(describing: verbID)

        expectNoDifference(description, ".take")
    }

    // MARK: - CustomDumpStringConvertible Tests

    @Test("VerbID CustomDumpStringConvertible")
    func testCustomDumpStringConvertible() throws {
        let id: VerbID = "take"
        #expect(id.description == ".take")
    }

    @Test("VerbID CustomDumpStringConvertible with Special Characters")
    func testCustomDumpStringConvertibleWithSpecialCharacters() throws {
        let id: VerbID = "verb_with-special.chars@123"
        #expect(id.description == ".verb_with-special.chars@123")
    }

    // MARK: - Performance Tests

    @Test("VerbID creation and comparison performance")
    func testPerformance() throws {
        // Test that VerbID operations are efficient
        let iterations = 1000
        let startTime = Date()

        for i in 0..<iterations {
            let verbID = VerbID(rawValue: "test\(i)")
            let isEqual = verbID == VerbID(rawValue: "test\(i)")
            #expect(isEqual)
        }

        let endTime = Date()
        let elapsed = endTime.timeIntervalSince(startTime)

        // Should complete quickly (less than 1 second for 1000 operations)
        #expect(elapsed < 1.0)
    }

    // MARK: - Edge Cases Tests

    @Test("VerbID Very Long String")
    func testVeryLongString() throws {
        let longString = String(repeating: "a", count: 10000)
        let id = VerbID(longString)
        #expect(id.rawValue == longString)
    }

    @Test("VerbID Whitespace Handling")
    func testWhitespaceHandling() throws {
        let id1: VerbID = " leadingSpace"
        let id2: VerbID = "trailingSpace "
        let id3: VerbID = " spaces "
        let id4: VerbID = "no\tTab\nNewline"

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

    @Test("VerbID String Interpolation")
    func testStringInterpolation() throws {
        let id: VerbID = "take"
        let message = "The verb is \(id)"
        #expect(message == "The verb is .take")
    }

    // MARK: - Array and Collection Tests

    @Test("VerbID Array Operations")
    func testArrayOperations() throws {
        var verbs: [VerbID] = [.take, .drop]
        verbs.append(.examine)
        verbs.insert(.look, at: 1)

        let expectedVerbs: [VerbID] = [.take, .look, .drop, .examine]
        #expect(verbs == expectedVerbs)
    }

    @Test("VerbID Dictionary Keys")
    func testDictionaryKeys() throws {
        var verbDescriptions: [VerbID: String] = [:]
        verbDescriptions[.take] = "Pick up an object"
        verbDescriptions[.drop] = "Put down an object"

        #expect(verbDescriptions.keys.count == 2)
        #expect(verbDescriptions.keys.contains(.take))
        #expect(verbDescriptions.keys.contains(.drop))
    }

    // MARK: - Mixed Usage Tests

    @Test("VerbID Mixed Literal and Constant Usage")
    func testMixedUsage() throws {
        let customVerb: VerbID = "customAction"
        let standardVerb = VerbID.take

        let verbSet: Set<VerbID> = [customVerb, standardVerb, .drop, "anotherCustom"]

        #expect(verbSet.count == 4)
        #expect(verbSet.contains(customVerb))
        #expect(verbSet.contains(standardVerb))
        #expect(verbSet.contains(.drop))
        #expect(verbSet.contains("anotherCustom"))
    }
}
