import Testing
import Foundation
@testable import GnustoEngine

@Suite("VerbID Tests")
struct VerbIDTests {

    // MARK: - Test Data

    let testID1: VerbID = "take"
    let testID2: VerbID = "drop"
    let testID3: VerbID = "examine"

    // MARK: - Initialization Tests

    @Test("VerbID String Literal Initialization")
    func testStringLiteralInitialization() throws {
        let id: VerbID = "testVerb"
        #expect(id.rawValue == "testVerb")
    }

    @Test("VerbID Raw Value Initialization")
    func testRawValueInitialization() throws {
        let id = VerbID("testVerb")
        #expect(id.rawValue == "testVerb")
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

    // MARK: - Equality Tests

    @Test("VerbID Equality")
    func testEquality() throws {
        let id1: VerbID = "take"
        let id2 = VerbID("take")
        let id3: VerbID = "drop"

        #expect(id1 == id2)
        #expect(id1 != id3)
        #expect(id2 != id3)
    }

    @Test("VerbID Case Sensitivity")
    func testCaseSensitivity() throws {
        let id1: VerbID = "Take"
        let id2: VerbID = "take"
        let id3: VerbID = "TAKE"

        #expect(id1 != id2)
        #expect(id1 != id3)
        #expect(id2 != id3)
    }

    // MARK: - Hashability Tests

    @Test("VerbID Hashability")
    func testHashability() throws {
        let verbDict = [
            VerbID("take"): "Pick up an object",
            VerbID("drop"): "Put down an object",
            VerbID("look"): "Examine surroundings"
        ]

        #expect(verbDict[VerbID("take")] == "Pick up an object")
        #expect(verbDict[VerbID("drop")] == "Put down an object")
        #expect(verbDict[VerbID("look")] == "Examine surroundings")
        #expect(verbDict[VerbID("nonexistent")] == nil)
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

    // MARK: - Codable Tests

    @Test("VerbID Codable Conformance")
    func testCodableConformance() throws {
        let originalIDs: [VerbID] = [
            "take",
            "drop",
            "examine",
            "verb_with-special.chars",
            "🎮动作",
        ]

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let decoder = JSONDecoder()

        for originalID in originalIDs {
            let jsonData = try encoder.encode(originalID)
            let decodedID = try decoder.decode(VerbID.self, from: jsonData)

            #expect(decodedID == originalID)
            #expect(decodedID.rawValue == originalID.rawValue)
        }
    }

    @Test("VerbID JSON Representation")
    func testJSONRepresentation() throws {
        let id: VerbID = "take"
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(id)
        let jsonString = String(data: jsonData, encoding: .utf8)

        // ID types now encode as plain strings
        #expect(jsonString == "\"take\"")
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

    // MARK: - CustomStringConvertible Tests

    @Test("VerbID CustomStringConvertible")
    func testCustomStringConvertible() throws {
        let id: VerbID = "take"
        #expect(id.description == ".take")
        #expect("\(id)" == ".take")
    }

    // MARK: - Interactive Verbs Tests

    @Test("VerbID Interactive Verbs Constants")
    func testInteractiveVerbs() throws {
        #expect(VerbID.close.rawValue == "close")
        #expect(VerbID.drop.rawValue == "drop")
        #expect(VerbID.examine.rawValue == "examine")
        #expect(VerbID.give.rawValue == "give")
        #expect(VerbID.go.rawValue == "go")
        #expect(VerbID.insert.rawValue == "insert")
        #expect(VerbID.inventory.rawValue == "inventory")
        #expect(VerbID.listen.rawValue == "listen")
        #expect(VerbID.lock.rawValue == "lock")
        #expect(VerbID.look.rawValue == "look")
        #expect(VerbID.open.rawValue == "open")
        #expect(VerbID.push.rawValue == "push")
        #expect(VerbID.putOn.rawValue == "putOn")
        #expect(VerbID.read.rawValue == "read")
        #expect(VerbID.remove.rawValue == "remove")
        #expect(VerbID.smell.rawValue == "smell")
        #expect(VerbID.take.rawValue == "take")
        #expect(VerbID.taste.rawValue == "taste")
        #expect(VerbID.thinkAbout.rawValue == "thinkAbout")
        #expect(VerbID.touch.rawValue == "touch")
        #expect(VerbID.turnOff.rawValue == "turnOff")
        #expect(VerbID.turnOn.rawValue == "turnOn")
        #expect(VerbID.unlock.rawValue == "unlock")
        #expect(VerbID.wear.rawValue == "wear")
        #expect(VerbID.xyzzy.rawValue == "xyzzy")
    }

    // MARK: - Meta Verbs Tests

    @Test("VerbID Meta Verbs Constants")
    func testMetaVerbs() throws {
        #expect(VerbID.brief.rawValue == "brief")
        #expect(VerbID.help.rawValue == "help")
        #expect(VerbID.quit.rawValue == "quit")
        #expect(VerbID.restore.rawValue == "restore")
        #expect(VerbID.save.rawValue == "save")
        #expect(VerbID.score.rawValue == "score")
        #expect(VerbID.verbose.rawValue == "verbose")
        #expect(VerbID.wait.rawValue == "wait")
    }

    // MARK: - Debug Verbs Tests

    #if DEBUG
    @Test("VerbID Debug Verbs Constants")
    func testDebugVerbs() throws {
        #expect(VerbID.debug.rawValue == "debug")
    }
    #endif

    // MARK: - Predefined Verbs Equality Tests

    @Test("VerbID Predefined Verbs Equality")
    func testPredefinedVerbsEquality() throws {
        #expect(VerbID.take == VerbID("take"))
        #expect(VerbID.drop == VerbID("drop"))
        #expect(VerbID.examine == VerbID("examine"))
        #expect(VerbID.go == VerbID("go"))
        #expect(VerbID.look == VerbID("look"))
        #expect(VerbID.quit == VerbID("quit"))
        #expect(VerbID.xyzzy == VerbID("xyzzy"))
    }

    // MARK: - Predefined Verbs Collection Tests

    @Test("VerbID All Interactive Verbs Collection")
    func testAllInteractiveVerbs() throws {
        let interactiveVerbs: Set<VerbID> = [
            .close, .drop, .examine, .give, .go, .insert, .inventory,
            .listen, .lock, .look, .open, .push, .putOn, .read, .remove,
            .smell, .take, .taste, .thinkAbout, .touch, .turnOff, .turnOn,
            .unlock, .wear, .xyzzy
        ]

        #expect(interactiveVerbs.count == 25)
        #expect(interactiveVerbs.contains(.take))
        #expect(interactiveVerbs.contains(.drop))
        #expect(interactiveVerbs.contains(.examine))
    }

    @Test("VerbID All Meta Verbs Collection")
    func testAllMetaVerbs() throws {
        let metaVerbs: Set<VerbID> = [
            .brief, .help, .quit, .restore, .save, .score, .verbose, .wait
        ]

        #expect(metaVerbs.count == 8)
        #expect(metaVerbs.contains(.quit))
        #expect(metaVerbs.contains(.score))
        #expect(metaVerbs.contains(.help))
    }

    // MARK: - Sendable Compliance Tests

    @Test("VerbID Sendable Compliance")
    func testSendableCompliance() async throws {
        let verbIDs: [VerbID] = [
            .take,
            .drop,
            .examine
        ]

        // Test that VerbID can be safely passed across actor boundaries
        let results = await withTaskGroup(of: VerbID.self) { group in
            for verbID in verbIDs {
                group.addTask {
                    return verbID
                }
            }

            var collectedResults: [VerbID] = []
            for await result in group {
                collectedResults.append(result)
            }
            return collectedResults
        }

        #expect(results.count == verbIDs.count)

        // Verify all original verb IDs are present in results
        for originalVerbID in verbIDs {
            #expect(results.contains(originalVerbID))
        }
    }

    // MARK: - Performance Tests

    @Test("VerbID Large Collection Performance")
    func testLargeCollectionPerformance() throws {
        // Create a large set of VerbIDs
        let verbIDs = (0..<1000).map { VerbID("verb\($0)") }
        let verbSet = Set(verbIDs)

        #expect(verbSet.count == 1000)

        // Test lookup performance
        let lookupID: VerbID = "verb500"
        #expect(verbSet.contains(lookupID))
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
