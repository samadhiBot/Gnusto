import CustomDump
import Foundation
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("EntityID Tests")
struct EntityIDTests {

    // MARK: - Test Data

    let testDaemonID: DaemonID = "testDaemon"
    let testFuseID: FuseID = "testFuse"
    let testItemID: ItemID = "testItem"
    let testLocationID: LocationID = "testLocation"

    // MARK: - Initialization Tests

    @Test("EntityID Daemon Case")
    func testDaemonCase() throws {
        let entityID = EntityID.daemon(testDaemonID)

        #expect(entityID == .daemon(testDaemonID))

        // Test the convenience getter
        let extractedDaemonID = try entityID.daemonID()
        #expect(extractedDaemonID == testDaemonID)
    }

    @Test("EntityID Fuse Case")
    func testFuseCase() throws {
        let entityID = EntityID.fuse(testFuseID)

        #expect(entityID == .fuse(testFuseID))

        // Test the convenience getter
        let extractedFuseID = try entityID.fuseID()
        #expect(extractedFuseID == testFuseID)
    }

    @Test("EntityID Item Case")
    func testItemCase() throws {
        let entityID = EntityID.item(testItemID)

        #expect(entityID == .item(testItemID))

        // Test the convenience getter
        let extractedItemID = try entityID.itemID()
        #expect(extractedItemID == testItemID)
    }

    @Test("EntityID Location Case")
    func testLocationCase() throws {
        let entityID = EntityID.location(testLocationID)

        #expect(entityID == .location(testLocationID))

        // Test the convenience getter
        let extractedLocationID = try entityID.locationID()
        #expect(extractedLocationID == testLocationID)
    }

    @Test("EntityID Player Case")
    func testPlayerCase() throws {
        let entityID = EntityID.player

        #expect(entityID == .player)
    }

    @Test("EntityID Global Case")
    func testGlobalCase() throws {
        let entityID = EntityID.global

        #expect(entityID == .global)
    }

    // MARK: - Equality Tests

    @Test("EntityID Equality")
    func testEntityIDEquality() throws {
        let daemon1 = EntityID.daemon(testDaemonID)
        let daemon2 = EntityID.daemon(testDaemonID)
        let daemon3 = EntityID.daemon("differentDaemon")

        let fuse1 = EntityID.fuse(testFuseID)
        let fuse2 = EntityID.fuse(testFuseID)

        let item1 = EntityID.item(testItemID)
        let location1 = EntityID.location(testLocationID)
        let player1 = EntityID.player
        let player2 = EntityID.player
        let global1 = EntityID.global
        let global2 = EntityID.global

        // Same cases with same values should be equal
        #expect(daemon1 == daemon2)
        #expect(fuse1 == fuse2)
        #expect(player1 == player2)
        #expect(global1 == global2)

        // Same cases with different values should not be equal
        #expect(daemon1 != daemon3)

        // Different cases should not be equal
        #expect(daemon1 != fuse1)
        #expect(daemon1 != item1)
        #expect(daemon1 != location1)
        #expect(daemon1 != player1)
        #expect(daemon1 != global1)
        #expect(fuse1 != item1)
        #expect(item1 != location1)
        #expect(location1 != player1)
        #expect(player1 != global1)
    }

    // MARK: - Hashability Tests

    @Test("EntityID Hashability")
    func testEntityIDHashability() throws {
        let entityIDs: Set<EntityID> = [
            .daemon(testDaemonID),
            .daemon(testDaemonID),  // Duplicate should be ignored
            .fuse(testFuseID),
            .item(testItemID),
            .location(testLocationID),
            .player,
            .player,  // Duplicate should be ignored
            .global,
        ]

        // Should have 6 unique values (duplicates removed)
        #expect(entityIDs.count == 6)
        #expect(entityIDs.contains(.daemon(testDaemonID)))
        #expect(entityIDs.contains(.fuse(testFuseID)))
        #expect(entityIDs.contains(.item(testItemID)))
        #expect(entityIDs.contains(.location(testLocationID)))
        #expect(entityIDs.contains(.player))
        #expect(entityIDs.contains(.global))

        // Test use as dictionary keys
        let entityDict: [EntityID: String] = [
            .daemon(testDaemonID): "daemon",
            .fuse(testFuseID): "fuse",
            .item(testItemID): "item",
            .location(testLocationID): "location",
            .player: "player",
            .global: "global",
        ]

        #expect(entityDict[.daemon(testDaemonID)] == "daemon")
        #expect(entityDict[.fuse(testFuseID)] == "fuse")
        #expect(entityDict[.item(testItemID)] == "item")
        #expect(entityDict[.location(testLocationID)] == "location")
        #expect(entityDict[.player] == "player")
        #expect(entityDict[.global] == "global")
    }

    // MARK: - Codable Tests

    @Test("EntityID Codable Conformance")
    func testEntityIDCodable() throws {
        let originalEntityIDs: [EntityID] = [
            .daemon(testDaemonID),
            .fuse(testFuseID),
            .item(testItemID),
            .location(testLocationID),
            .player,
            .global,
        ]

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let decoder = JSONDecoder()

        for originalEntityID in originalEntityIDs {
            let jsonData = try encoder.encode(originalEntityID)
            let decodedEntityID = try decoder.decode(EntityID.self, from: jsonData)

            #expect(decodedEntityID == originalEntityID)
        }
    }

    // MARK: - Convenience Method Error Tests

    @Test("daemonID() Throws on Wrong Case")
    func testDaemonIDThrowsOnWrongCase() throws {
        let testCases: [EntityID] = [
            .fuse(testFuseID),
            .item(testItemID),
            .location(testLocationID),
            .player,
            .global,
        ]

        for testCase in testCases {
            #expect {
                try testCase.daemonID()
            } throws: { error in
                guard case ActionResponse.internalEngineError(let message) = error else {
                    return false
                }
                return message.contains("EntityID expected to be DaemonID")
            }
        }
    }

    @Test("fuseID() Throws on Wrong Case")
    func testFuseIDThrowsOnWrongCase() throws {
        let testCases: [EntityID] = [
            .daemon(testDaemonID),
            .item(testItemID),
            .location(testLocationID),
            .player,
            .global,
        ]

        for testCase in testCases {
            #expect {
                try testCase.fuseID()
            } throws: { error in
                guard case ActionResponse.internalEngineError(let message) = error else {
                    return false
                }
                return message.contains("EntityID expected to be FuseID")
            }
        }
    }

    @Test("itemID() Throws on Wrong Case")
    func testItemIDThrowsOnWrongCase() throws {
        let testCases: [EntityID] = [
            .daemon(testDaemonID),
            .fuse(testFuseID),
            .location(testLocationID),
            .player,
            .global,
        ]

        for testCase in testCases {
            #expect {
                try testCase.itemID()
            } throws: { error in
                guard case ActionResponse.internalEngineError(let message) = error else {
                    return false
                }
                return message.contains("EntityID expected to be ItemID")
            }
        }
    }

    @Test("locationID() Throws on Wrong Case")
    func testLocationIDThrowsOnWrongCase() throws {
        let testCases: [EntityID] = [
            .daemon(testDaemonID),
            .fuse(testFuseID),
            .item(testItemID),
            .player,
            .global,
        ]

        for testCase in testCases {
            #expect {
                try testCase.locationID()
            } throws: { error in
                guard case ActionResponse.internalEngineError(let message) = error else {
                    return false
                }
                return message.contains("EntityID expected to be LocationID")
            }
        }
    }

    // MARK: - Error Message Content Tests

    @Test("Error Messages Include Actual EntityID")
    func testErrorMessagesIncludeActualEntityID() throws {
        let playerEntityID = EntityID.player

        #expect {
            try playerEntityID.daemonID()
        } throws: { error in
            guard case ActionResponse.internalEngineError(let message) = error else {
                return false
            }

            expectNoDifference(message, "EntityID expected to be DaemonID, got: .player")
            return true
        }

        #expect {
            try playerEntityID.fuseID()
        } throws: { error in
            guard case ActionResponse.internalEngineError(let message) = error else {
                return false
            }

            expectNoDifference(message, "EntityID expected to be FuseID, got: .player")
            return true
        }

        #expect {
            try playerEntityID.itemID()
        } throws: { error in
            guard case ActionResponse.internalEngineError(let message) = error else {
                return false
            }

            expectNoDifference(message, "EntityID expected to be ItemID, got: .player")
            return true
        }

        #expect {
            try playerEntityID.locationID()
        } throws: { error in
            guard case ActionResponse.internalEngineError(let message) = error else {
                return false
            }

            expectNoDifference(message, "EntityID expected to be LocationID, got: .player")
            return true
        }
    }

    // MARK: - Sendable Compliance Test

    @Test("EntityID Sendable Compliance")
    func testEntityIDSendableCompliance() async throws {
        // Test that EntityID can be safely passed across actor boundaries
        let entityIDs: [EntityID] = [
            .daemon(testDaemonID),
            .fuse(testFuseID),
            .item(testItemID),
            .location(testLocationID),
            .player,
            .global,
        ]

        // This test ensures that EntityID conforms to Sendable by using it in an async context
        let results = await withTaskGroup(of: EntityID.self) { group in
            for entityID in entityIDs {
                group.addTask {
                    return entityID
                }
            }

            var collectedResults: [EntityID] = []
            for await result in group {
                collectedResults.append(result)
            }
            return collectedResults
        }

        #expect(results.count == entityIDs.count)

        // Verify all original entity IDs are present in results
        for originalEntityID in entityIDs {
            #expect(results.contains(originalEntityID))
        }
    }
}
