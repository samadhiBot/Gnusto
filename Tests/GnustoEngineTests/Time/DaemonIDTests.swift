import Foundation
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("DaemonID Tests")
struct DaemonIDTests {

    // MARK: - Test Data

    let testID1: DaemonID = "heartbeat"
    let testID2: DaemonID = "clockTower"
    let testID3: DaemonID = "weatherSystem"

    // MARK: - Initialization Tests

    @Test("DaemonID String Literal Initialization")
    func testStringLiteralInitialization() throws {
        let id: DaemonID = "testDaemon"
        #expect(id.rawValue == "testDaemon")
    }

    @Test("DaemonID Raw Value Initialization")
    func testRawValueInitialization() throws {
        let id = DaemonID("testDaemon")
        #expect(id.rawValue == "testDaemon")
    }

    @Test("DaemonID Initialization with Special Characters")
    func testSpecialCharacterInitialization() throws {
        let id: DaemonID = "daemon_with-special.chars@123"
        #expect(id.rawValue == "daemon_with-special.chars@123")
    }

    @Test("DaemonID Initialization with Unicode")
    func testUnicodeInitialization() throws {
        let id: DaemonID = "⚙️守护进程"
        #expect(id.rawValue == "⚙️守护进程")
    }

    // MARK: - Equality Tests

    @Test("DaemonID Equality")
    func testEquality() throws {
        let id1: DaemonID = "heartbeat"
        let id2 = DaemonID("heartbeat")
        let id3: DaemonID = "clockTower"

        #expect(id1 == id2)
        #expect(id1 != id3)
        #expect(id2 != id3)
    }

    @Test("DaemonIDs are case-insensitive")
    func testCaseSensitivity() throws {
        let id1: DaemonID = "HeartBeat"
        let id2: DaemonID = "heartbeat"
        let id3: DaemonID = "HEARTBEAT"

        #expect(id1 == id2)
        #expect(id1 == id3)
        #expect(id2 == id3)
    }

    // MARK: - Hashability Tests

    @Test("DaemonID Hashability")
    func testHashability() throws {
        let daemonDict = [
            DaemonID("heartbeat"): "Periodic pulse",
            DaemonID("clockTower"): "Hourly chimes",
            DaemonID("weatherSystem"): "Weather changes",
        ]

        #expect(daemonDict[DaemonID("heartbeat")] == "Periodic pulse")
        #expect(daemonDict[DaemonID("clockTower")] == "Hourly chimes")
        #expect(daemonDict[DaemonID("weatherSystem")] == "Weather changes")
        #expect(daemonDict[DaemonID("nonexistent")] == nil)
    }

    @Test("DaemonID Set Operations")
    func testSetOperations() throws {
        let daemonSet: Set<DaemonID> = [
            "heartbeat",
            "clockTower",
            "weatherSystem",
            "heartbeat",  // Duplicate should be ignored
        ]

        #expect(daemonSet.count == 3)
        #expect(daemonSet.contains("heartbeat"))
        #expect(daemonSet.contains("clockTower"))
        #expect(daemonSet.contains("weatherSystem"))
        #expect(!daemonSet.contains("nonexistent"))
    }

    // MARK: - Comparable Tests

    @Test("DaemonID Comparability")
    func testComparability() throws {
        let id1: DaemonID = "apple"
        let id2: DaemonID = "banana"
        let id3: DaemonID = "cherry"

        #expect(id1 < id2)
        #expect(id2 < id3)
        #expect(id1 < id3)
        #expect(!(id2 < id1))
        #expect(!(id3 < id2))
    }

    @Test("DaemonID Sorting")
    func testSorting() throws {
        let unsortedIDs: [DaemonID] = ["zebra", "apple", "monkey", "banana"]
        let sortedIDs = unsortedIDs.sorted()

        let expectedOrder: [DaemonID] = ["apple", "banana", "monkey", "zebra"]
        #expect(sortedIDs == expectedOrder)
    }

    @Test("DaemonID Sorting with Numbers and Letters")
    func testSortingWithNumbersAndLetters() throws {
        let unsortedIDs: [DaemonID] = ["daemon10", "daemon2", "daemon1", "daemonA"]
        let sortedIDs = unsortedIDs.sorted()

        // String sorting: numbers come before letters, but "10" < "2" lexicographically
        let expectedOrder: [DaemonID] = ["daemon1", "daemon10", "daemon2", "daemonA"]
        #expect(sortedIDs == expectedOrder)
    }

    // MARK: - Codable Tests

    @Test("DaemonID Codable Conformance")
    func testCodableConformance() throws {
        let originalIDs: [DaemonID] = [
            "heartbeat",
            "clockTower",
            "weatherSystem",
            "daemon_with-special.chars",
            "⚙️守护进程",
        ]

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let decoder = JSONDecoder()

        for originalID in originalIDs {
            let jsonData = try encoder.encode(originalID)
            let decodedID = try decoder.decode(DaemonID.self, from: jsonData)

            #expect(decodedID == originalID)
            #expect(decodedID.rawValue == originalID.rawValue)
        }
    }

    @Test("DaemonID JSON Representation")
    func testJSONRepresentation() throws {
        let id: DaemonID = "heartbeat"
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(id)
        let jsonString = String(data: jsonData, encoding: .utf8)

        #expect(jsonString == "\"heartbeat\"")
    }

    // MARK: - ExpressibleByStringLiteral Tests

    @Test("DaemonID ExpressibleByStringLiteral Usage")
    func testExpressibleByStringLiteral() throws {
        // These should all work due to ExpressibleByStringLiteral
        let daemons: [DaemonID] = [
            "heartbeat",
            "clockTower",
            "weatherSystem",
        ]

        #expect(daemons.count == 3)
        #expect(daemons[0].rawValue == "heartbeat")
        #expect(daemons[1].rawValue == "clockTower")
        #expect(daemons[2].rawValue == "weatherSystem")
    }

    // MARK: - Sendable Compliance Tests

    @Test("DaemonID Sendable Compliance")
    func testSendableCompliance() async throws {
        let daemonIDs: [DaemonID] = [
            "heartbeat",
            "clockTower",
            "weatherSystem",
        ]

        // Test that DaemonID can be safely passed across actor boundaries
        let results = await withTaskGroup(of: DaemonID.self) { group in
            for daemonID in daemonIDs {
                group.addTask {
                    return daemonID
                }
            }

            var collectedResults: [DaemonID] = []
            for await result in group {
                collectedResults.append(result)
            }
            return collectedResults
        }

        #expect(results.count == daemonIDs.count)

        // Verify all original daemon IDs are present in results
        for originalDaemonID in daemonIDs {
            #expect(results.contains(originalDaemonID))
        }
    }

    // MARK: - Performance Tests

    @Test("DaemonID Large Collection Performance")
    func testLargeCollectionPerformance() throws {
        // Create a large set of DaemonIDs
        let daemonIDs = (0..<1000).map { DaemonID("daemon\($0)") }
        let daemonSet = Set(daemonIDs)

        #expect(daemonSet.count == 1000)

        // Test lookup performance
        let lookupID: DaemonID = "daemon500"
        #expect(daemonSet.contains(lookupID))
    }

    // MARK: - Edge Cases Tests

    @Test("DaemonID Very Long String")
    func testVeryLongString() throws {
        let longString = String(repeating: "a", count: 10000)
        let id = DaemonID(longString)
        #expect(id.rawValue == longString)
    }

    @Test("DaemonID Whitespace Handling")
    func testWhitespaceHandling() throws {
        let id1: DaemonID = " leadingSpace"
        let id2: DaemonID = "trailingSpace "
        let id3: DaemonID = " spaces "
        let id4: DaemonID = "no\tTab\nNewline"

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

    @Test("DaemonID String Interpolation")
    func testStringInterpolation() throws {
        let id: DaemonID = "heartbeat"
        let message = "The daemon is \(id)."
        // DaemonID doesn't implement CustomStringConvertible, so it shows the full struct representation
        #expect(message == "The daemon is .heartbeat.")
    }

    // MARK: - Array and Collection Tests

    @Test("DaemonID Array Operations")
    func testArrayOperations() throws {
        var daemons: [DaemonID] = ["heartbeat", "clockTower"]
        daemons.append("weatherSystem")
        daemons.insert("backgroundMusic", at: 1)

        let expectedDaemons: [DaemonID] = [
            "heartbeat", "backgroundMusic", "clockTower", "weatherSystem",
        ]
        #expect(daemons == expectedDaemons)
    }

    @Test("DaemonID Dictionary Keys")
    func testDictionaryKeys() throws {
        var daemonDescriptions: [DaemonID: String] = [:]
        daemonDescriptions["heartbeat"] = "Periodic pulse"
        daemonDescriptions["clockTower"] = "Hourly chimes"

        #expect(daemonDescriptions.keys.count == 2)
        #expect(daemonDescriptions.keys.contains("heartbeat"))
        #expect(daemonDescriptions.keys.contains("clockTower"))
    }

    // MARK: - Game Context Tests

    @Test("DaemonID Game Realistic Examples")
    func testGameRealisticExamples() throws {
        // Test realistic daemon IDs that might be used in games
        let gameDaemons: Set<DaemonID> = [
            "grueMovement",
            "thief",
            "sunCycle",
            "tideChanges",
            "randomEvents",
            "npcBehavior",
            "weatherUpdates",
        ]

        #expect(gameDaemons.count == 7)
        #expect(gameDaemons.contains("grueMovement"))
        #expect(gameDaemons.contains("thief"))
        #expect(gameDaemons.contains("sunCycle"))
    }

    // MARK: - Documentation Comment Validation Tests

    @Test("DaemonID Documentation Comment Validation")
    func testDocumentationCommentValidation() throws {
        // Test that the documented usage pattern works
        let id: DaemonID = "heartbeat"

        // Verify this can be used in contexts mentioned in the documentation
        let timeRegistry: [DaemonID: String] = [
            id: "A periodic heartbeat daemon"
        ]

        let gameState: Set<DaemonID> = [id]

        #expect(timeRegistry[id] == "A periodic heartbeat daemon")
        #expect(gameState.contains(id))
    }

    // MARK: - Type Safety Tests

    @Test("DaemonID Type Safety")
    func testTypeSafety() throws {
        // Test that DaemonID is properly type-safe
        let daemonID: DaemonID = "heartbeat"

        // This should work - same type
        let sameDaemonID: DaemonID = daemonID
        #expect(sameDaemonID == daemonID)

        // Test that we can't accidentally mix with other ID types
        // (This is enforced at compile time, but we can test runtime behavior)
        let daemonDict: [DaemonID: String] = [daemonID: "test"]
        #expect(daemonDict[daemonID] == "test")
    }
}
