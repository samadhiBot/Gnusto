import Testing
import Foundation
@testable import GnustoEngine

@Suite("FuseID Tests")
struct FuseIDTests {

    // MARK: - Test Data

    let testID1: FuseID = "bombFuse"
    let testID2: FuseID = "candleTimer"
    let testID3: FuseID = "alarmClock"

    // MARK: - Initialization Tests

    @Test("FuseID String Literal Initialization")
    func testStringLiteralInitialization() throws {
        let id: FuseID = "testFuse"
        #expect(id.rawValue == "testFuse")
    }

    @Test("FuseID Raw Value Initialization")
    func testRawValueInitialization() throws {
        let id = FuseID("testFuse")
        #expect(id.rawValue == "testFuse")
    }

    @Test("FuseID Initialization with Special Characters")
    func testSpecialCharacterInitialization() throws {
        let id: FuseID = "fuse_with-special.chars@123"
        #expect(id.rawValue == "fuse_with-special.chars@123")
    }

    @Test("FuseID Initialization with Unicode")
    func testUnicodeInitialization() throws {
        let id: FuseID = "💣定时器"
        #expect(id.rawValue == "💣定时器")
    }

    // MARK: - Equality Tests

    @Test("FuseID Equality")
    func testEquality() throws {
        let id1: FuseID = "bombFuse"
        let id2 = FuseID("bombFuse")
        let id3: FuseID = "candleTimer"

        #expect(id1 == id2)
        #expect(id1 != id3)
        #expect(id2 != id3)
    }

    @Test("FuseID Case Sensitivity")
    func testCaseSensitivity() throws {
        let id1: FuseID = "BombFuse"
        let id2: FuseID = "bombfuse"
        let id3: FuseID = "BOMBFUSE"

        #expect(id1 != id2)
        #expect(id1 != id3)
        #expect(id2 != id3)
    }

    // MARK: - Hashability Tests

    @Test("FuseID Hashability")
    func testHashability() throws {
        let fuseDict = [
            FuseID("bombFuse"): "Explosive timer",
            FuseID("candleTimer"): "Candle burndown",
            FuseID("alarmClock"): "Scheduled alarm"
        ]

        #expect(fuseDict[FuseID("bombFuse")] == "Explosive timer")
        #expect(fuseDict[FuseID("candleTimer")] == "Candle burndown")
        #expect(fuseDict[FuseID("alarmClock")] == "Scheduled alarm")
        #expect(fuseDict[FuseID("nonexistent")] == nil)
    }

    @Test("FuseID Set Operations")
    func testSetOperations() throws {
        let fuseSet: Set<FuseID> = [
            "bombFuse",
            "candleTimer",
            "alarmClock",
            "bombFuse" // Duplicate should be ignored
        ]

        #expect(fuseSet.count == 3)
        #expect(fuseSet.contains("bombFuse"))
        #expect(fuseSet.contains("candleTimer"))
        #expect(fuseSet.contains("alarmClock"))
        #expect(!fuseSet.contains("nonexistent"))
    }

    // MARK: - Comparable Tests

    @Test("FuseID Comparability")
    func testComparability() throws {
        let id1: FuseID = "apple"
        let id2: FuseID = "banana"
        let id3: FuseID = "cherry"

        #expect(id1 < id2)
        #expect(id2 < id3)
        #expect(id1 < id3)
        #expect(!(id2 < id1))
        #expect(!(id3 < id2))
    }

    @Test("FuseID Sorting")
    func testSorting() throws {
        let unsortedIDs: [FuseID] = ["zebra", "apple", "monkey", "banana"]
        let sortedIDs = unsortedIDs.sorted()

        let expectedOrder: [FuseID] = ["apple", "banana", "monkey", "zebra"]
        #expect(sortedIDs == expectedOrder)
    }

    @Test("FuseID Sorting with Numbers and Letters")
    func testSortingWithNumbersAndLetters() throws {
        let unsortedIDs: [FuseID] = ["fuse10", "fuse2", "fuse1", "fuseA"]
        let sortedIDs = unsortedIDs.sorted()

        // String sorting: numbers come before letters, but "10" < "2" lexicographically
        let expectedOrder: [FuseID] = ["fuse1", "fuse10", "fuse2", "fuseA"]
        #expect(sortedIDs == expectedOrder)
    }

    // MARK: - Codable Tests

    @Test("FuseID Codable Conformance")
    func testCodableConformance() throws {
        let originalIDs: [FuseID] = [
            "bombFuse",
            "candleTimer",
            "alarmClock",
            "fuse_with-special.chars",
            "💣定时器",
        ]

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let decoder = JSONDecoder()

        for originalID in originalIDs {
            let jsonData = try encoder.encode(originalID)
            let decodedID = try decoder.decode(FuseID.self, from: jsonData)

            #expect(decodedID == originalID)
            #expect(decodedID.rawValue == originalID.rawValue)
        }
    }

    @Test("FuseID JSON Representation")
    func testJSONRepresentation() throws {
        let id: FuseID = "bombFuse"
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(id)
        let jsonString = String(data: jsonData, encoding: .utf8)

        #expect(jsonString == "\"bombFuse\"")
    }

    // MARK: - ExpressibleByStringLiteral Tests

    @Test("FuseID ExpressibleByStringLiteral Usage")
    func testExpressibleByStringLiteral() throws {
        // These should all work due to ExpressibleByStringLiteral
        let fuses: [FuseID] = [
            "bombFuse",
            "candleTimer",
            "alarmClock"
        ]

        #expect(fuses.count == 3)
        #expect(fuses[0].rawValue == "bombFuse")
        #expect(fuses[1].rawValue == "candleTimer")
        #expect(fuses[2].rawValue == "alarmClock")
    }

    // MARK: - Sendable Compliance Tests

    @Test("FuseID Sendable Compliance")
    func testSendableCompliance() async throws {
        let fuseIDs: [FuseID] = [
            "bombFuse",
            "candleTimer",
            "alarmClock"
        ]

        // Test that FuseID can be safely passed across actor boundaries
        let results = await withTaskGroup(of: FuseID.self) { group in
            for fuseID in fuseIDs {
                group.addTask {
                    return fuseID
                }
            }

            var collectedResults: [FuseID] = []
            for await result in group {
                collectedResults.append(result)
            }
            return collectedResults
        }

        #expect(results.count == fuseIDs.count)

        // Verify all original fuse IDs are present in results
        for originalFuseID in fuseIDs {
            #expect(results.contains(originalFuseID))
        }
    }

    // MARK: - Performance Tests

    @Test("FuseID Large Collection Performance")
    func testLargeCollectionPerformance() throws {
        // Create a large set of FuseIDs
        let fuseIDs = (0..<1000).map { FuseID("fuse\($0)") }
        let fuseSet = Set(fuseIDs)

        #expect(fuseSet.count == 1000)

        // Test lookup performance
        let lookupID: FuseID = "fuse500"
        #expect(fuseSet.contains(lookupID))
    }

    // MARK: - Edge Cases Tests

    @Test("FuseID Very Long String")
    func testVeryLongString() throws {
        let longString = String(repeating: "a", count: 10000)
        let id = FuseID(longString)
        #expect(id.rawValue == longString)
    }

    @Test("FuseID Whitespace Handling")
    func testWhitespaceHandling() throws {
        let id1: FuseID = " leadingSpace"
        let id2: FuseID = "trailingSpace "
        let id3: FuseID = " spaces "
        let id4: FuseID = "no\tTab\nNewline"

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

    @Test("FuseID String Interpolation")
    func testStringInterpolation() throws {
        let id: FuseID = "bombFuse"
        let message = "The fuse is \(id)."
        #expect(message == "The fuse is .bombFuse.")
    }

    // MARK: - Array and Collection Tests

    @Test("FuseID Array Operations")
    func testArrayOperations() throws {
        var fuses: [FuseID] = ["bombFuse", "candleTimer"]
        fuses.append("alarmClock")
        fuses.insert("quickTimer", at: 1)

        let expectedFuses: [FuseID] = ["bombFuse", "quickTimer", "candleTimer", "alarmClock"]
        #expect(fuses == expectedFuses)
    }

    @Test("FuseID Dictionary Keys")
    func testDictionaryKeys() throws {
        var fuseDescriptions: [FuseID: String] = [:]
        fuseDescriptions["bombFuse"] = "Explosive timer"
        fuseDescriptions["candleTimer"] = "Candle burndown"

        #expect(fuseDescriptions.keys.count == 2)
        #expect(fuseDescriptions.keys.contains("bombFuse"))
        #expect(fuseDescriptions.keys.contains("candleTimer"))
    }

    // MARK: - Game Context Tests

    @Test("FuseID Game Realistic Examples")
    func testGameRealisticExamples() throws {
        // Test realistic fuse IDs that might be used in games
        let gameFuses: Set<FuseID> = [
            "bombCountdown",
            "candleBurnout",
            "torchFlicker",
            "floodTimer",
            "poisonGasDelay",
            "earthquakeWarning",
            "treasureVanish"
        ]

        #expect(gameFuses.count == 7)
        #expect(gameFuses.contains("bombCountdown"))
        #expect(gameFuses.contains("candleBurnout"))
        #expect(gameFuses.contains("torchFlicker"))
    }

    // MARK: - Time-Based Context Tests

    @Test("FuseID Time-Based Context")
    func testTimeBasedContext() throws {
        // Test fuse IDs in contexts that suggest turn-based timing
        let timeBasedFuses: [FuseID] = [
            "shortTimer",       // 1-2 turns
            "mediumTimer",      // 5-10 turns  
            "longTimer",        // 20+ turns
            "urgentCountdown",  // immediate
            "delayedReaction"   // varies
        ]

        #expect(timeBasedFuses.count == 5)
        
        // Test that they can be used in turn-based contexts
        let fuseTimings: [FuseID: Int] = [
            "shortTimer": 2,
            "mediumTimer": 8,
            "longTimer": 25,
            "urgentCountdown": 1,
            "delayedReaction": 15
        ]

        #expect(fuseTimings["shortTimer"] == 2)
        #expect(fuseTimings["mediumTimer"] == 8)
        #expect(fuseTimings["longTimer"] == 25)
    }

    // MARK: - Documentation Comment Validation Tests

    @Test("FuseID Documentation Comment Validation")
    func testDocumentationCommentValidation() throws {
        // Test that the documented usage pattern works
        let id: FuseID = "bombFuse"
        
        // Verify this can be used in contexts mentioned in the documentation
        let timeRegistry: [FuseID: String] = [
            id: "A timed explosive device"
        ]
        
        let gameState: [FuseID: Int] = [id: 10] // Remaining turns
        
        #expect(timeRegistry[id] == "A timed explosive device")
        #expect(gameState[id] == 10)
    }

    // MARK: - Type Safety Tests

    @Test("FuseID Type Safety")
    func testTypeSafety() throws {
        // Test that FuseID is properly type-safe
        let fuseID: FuseID = "bombFuse"
        
        // This should work - same type
        let sameFuseID: FuseID = fuseID
        #expect(sameFuseID == fuseID)
        
        // Test that we can't accidentally mix with other ID types
        // (This is enforced at compile time, but we can test runtime behavior)
        let fuseDict: [FuseID: String] = [fuseID: "test"]
        #expect(fuseDict[fuseID] == "test")
    }

    // MARK: - Timer Simulation Tests

    @Test("FuseID Timer Simulation")
    func testTimerSimulation() throws {
        // Simulate a basic timer system using FuseID
        struct FuseTimer {
            let id: FuseID
            var remainingTurns: Int
            let action: String
        }
        
        var activeTimers = [
            FuseTimer(id: "bombFuse", remainingTurns: 5, action: "explode"),
            FuseTimer(id: "candleTimer", remainingTurns: 10, action: "burnOut"),
            FuseTimer(id: "alarmClock", remainingTurns: 3, action: "ring")
        ]
        
        // Simulate one turn passing
        for i in 0..<activeTimers.count {
            activeTimers[i].remainingTurns -= 1
        }
        
        // Check for expired timers
        let expiredTimers = activeTimers.filter { $0.remainingTurns <= 0 }
        let remainingTimers = activeTimers.filter { $0.remainingTurns > 0 }
        
        #expect(expiredTimers.isEmpty) // No timers should expire yet
        #expect(remainingTimers.count == 3)
        #expect(remainingTimers.contains { $0.id == "bombFuse" && $0.remainingTurns == 4 })
        #expect(remainingTimers.contains { $0.id == "candleTimer" && $0.remainingTurns == 9 })
        #expect(remainingTimers.contains { $0.id == "alarmClock" && $0.remainingTurns == 2 })
    }
} 
