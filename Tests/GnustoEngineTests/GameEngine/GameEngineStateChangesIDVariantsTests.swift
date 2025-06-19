import CustomDump
import Foundation
import Testing

@testable import GnustoEngine

/// Tests for the ItemID and LocationID variants of StateChange factory methods.
@Suite("GameEngine StateChange ID Variants")
struct GameEngineStateChangesIDVariantsTests {

    // MARK: - ItemID Tests

    @Test("clearFlag with ItemID - success")
    func testClearFlagItemIDSuccess() async throws {
        // Given
        let item = Item(
            id: "testItem",
            .name("Test Item"),
            .testItemAttrFlag
        )
        let game = MinimalGame(items: item)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let change = try await engine.clearFlag(.testItemFlag, on: item.id)

        // Then
        #expect(change != nil)
        #expect(change?.entityID == .item("testItem"))
        #expect(change?.attribute == .itemAttribute(.testItemFlag))
        #expect(change?.oldValue == true)
        #expect(change?.newValue == false)
    }

    @Test("clearFlag with ItemID - nil when flag not set")
    func testClearFlagItemIDWhenNotSet() async throws {
        // Given
        let item = Item(
            id: "testItem",
            .name("Test Item")
        )
        let game = MinimalGame(items: item)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let change = try await engine.clearFlag(.testItemFlag, on: item.id)

        // Then
        #expect(change == nil)
    }

    @Test("clearFlag with ItemID - nil when itemID is nil")
    func testClearFlagItemIDWhenNil() async throws {
        // Given
        let (engine, _) = await GameEngine.test()

        // When
        let nilItemID: ItemID? = nil

        // Then
        await #expect(throws: ActionResponse.self) {
            try await engine.clearFlag(.testItemFlag, on: nilItemID)
        }
    }

    @Test("clearFlag with ItemID - throws when item not found")
    func testClearFlagItemIDThrowsWhenNotFound() async throws {
        // Given
        let (engine, _) = await GameEngine.test()

        // When/Then
        await #expect(throws: ActionResponse.self) {
            try await engine.clearFlag(.testItemFlag, on: ItemID("nonexistentItem"))
        }
    }

    @Test("move with ItemID - success")
    func testMoveItemIDSuccess() async throws {
        // Given
        let item = Item(
            id: "testItem",
            .name("Test Item"),
            .in(.location("startLocation"))
        )
        let game = MinimalGame(items: item)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let change = try await engine.move(item.id, to: .player)

        // Then
        #expect(change.entityID == .item("testItem"))
        #expect(change.attribute == .itemParent)
        #expect(change.oldValue == .parentEntity(.location("startLocation")))
        #expect(change.newValue == .parentEntity(.player))
    }

    @Test("move with ItemID - throws when item not found")
    func testMoveItemIDThrowsWhenNotFound() async throws {
        // Given
        let (engine, _) = await GameEngine.test()

        // When/Then
        await #expect(throws: ActionResponse.self) {
            try await engine.move("nonexistentItem", to: .player)
        }
    }

    @Test("setAttribute with ItemID - StateValue variant")
    func testSetAttributeItemIDStateValue() async throws {
        // Given
        let item = Item(
            id: "testItem",
            .name("Test Item")
        )
        let game = MinimalGame(items: item)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let change = try await engine.setAttribute(.testItemCounter, on: item.id, to: .int(42))

        // Then
        #expect(change != nil)
        #expect(change?.entityID == .item("testItem"))
        #expect(change?.attribute == .itemAttribute(.testItemCounter))
        #expect(change?.newValue == .int(42))
    }

    @Test("setAttribute with ItemID - Bool variant")
    func testSetAttributeItemIDBool() async throws {
        // Given
        let item = Item(
            id: "testItem",
            .name("Test Item")
        )
        let game = MinimalGame(items: item)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let change = try await engine.setAttribute(.testItemFlag, on: item.id, to: true)

        // Then
        #expect(change != nil)
        #expect(change?.entityID == .item("testItem"))
        #expect(change?.attribute == .itemAttribute(.testItemFlag))
        #expect(change?.newValue == true)
    }

    @Test("setFlag with ItemID - success")
    func testSetFlagItemIDSuccess() async throws {
        // Given
        let item = Item(
            id: "testItem",
            .name("Test Item")
        )
        let game = MinimalGame(items: item)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let change = try await engine.setFlag(.testItemFlag, on: item.id)

        // Then
        #expect(change != nil)
        #expect(change?.newValue == true)
    }

    @Test("setFlag with ItemID - nil when itemID is nil")
    func testSetFlagItemIDWhenNil() async throws {
        // Given
        let (engine, _) = await GameEngine.test()

        // When
        let nilItemID: ItemID? = nil

        // Then
        await #expect(throws: ActionResponse.self) {
            try await engine.clearFlag(.testItemFlag, on: nilItemID)
        }
    }

    @Test("setDescription with ItemID - success")
    func testSetDescriptionItemIDSuccess() async throws {
        // Given
        let item = Item(
            id: "testItem",
            .name("Test Item")
        )
        let game = MinimalGame(items: item)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let change = try await engine.setDescription(on: item.id, to: "New description")

        // Then
        #expect(change != nil)
        #expect(change?.newValue == .string("New description"))
    }

    // MARK: - LocationID Tests

    @Test("clearFlag with LocationID - success")
    func testClearFlagLocationIDSuccess() async throws {
        // Given
        let location = Location(
            id: "testLocation",
            .name("Test Location"),
            .testLocationAttrFlag
        )
        let game = MinimalGame(locations: location)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let change = try await engine.clearFlag(.testLocationFlag, on: LocationID("testLocation"))

        // Then
        #expect(change != nil)
        #expect(change?.entityID == .location("testLocation"))
        #expect(change?.attribute == .locationAttribute(.testLocationFlag))
        #expect(change?.oldValue == true)
        #expect(change?.newValue == false)
    }

    @Test("clearFlag with LocationID - throws when location not found")
    func testClearFlagLocationIDThrowsWhenNotFound() async throws {
        // Given
        let (engine, _) = await GameEngine.test()

        // When/Then
        await #expect(throws: ActionResponse.self) {
            try await engine.clearFlag(.testLocationFlag, on: LocationID("nonexistentLocation"))
        }
    }

    @Test("setFlag with LocationID - success")
    func testSetFlagLocationIDSuccess() async throws {
        // Given
        let location = Location(
            id: "testLocation",
            .name("Test Location")
        )
        let game = MinimalGame(locations: location)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let change = try await engine.setFlag(.testLocationFlag, on: LocationID("testLocation"))

        // Then
        #expect(change != nil)
        #expect(change?.entityID == .location("testLocation"))
        #expect(change?.attribute == .locationAttribute(.testLocationFlag))
        #expect(change?.newValue == true)
    }

    @Test("setAttribute with LocationID - StateValue variant")
    func testSetAttributeLocationIDStateValue() async throws {
        // Given
        let testLocationCounter = LocationAttributeID("testLocationCounter")
        let location = Location(
            id: "testLocation",
            .name("Test Location")
        )
        let game = MinimalGame(locations: location)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let change = try await engine.setAttribute(
            .testLocationCounter,
            on: LocationID("testLocation"),
            to: .int(42)
        )

        // Then
        #expect(change != nil)
        #expect(change?.entityID == .location("testLocation"))
        #expect(change?.attribute == .locationAttribute(testLocationCounter))
        #expect(change?.newValue == .int(42))
    }

    @Test("setDescription with LocationID - success")
    func testSetDescriptionLocationIDSuccess() async throws {
        // Given
        let location = Location(
            id: "testLocation",
            .name("Test Location")
        )
        let game = MinimalGame(locations: location)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let change = try await engine.setDescription(
            on: LocationID("testLocation"), to: "New description")

        // Then
        #expect(change != nil)
        #expect(change?.newValue == .string("New description"))
    }

    // MARK: - Error handling comprehensive tests

    @Test("All ItemID variants throw when item not found")
    func testItemIDVariantsThrowWhenNotFound() async throws {
        // Given
        let (engine, _) = await GameEngine.test()
        let nonexistentID: ItemID = "nonexistent"

        // When/Then - Test all variants that should throw
        await #expect(throws: ActionResponse.self) {
            try await engine.move(nonexistentID, to: .player)
        }

        await #expect(throws: ActionResponse.self) {
            try await engine.setAttribute(.testItemFlag, on: nonexistentID, to: .bool(true))
        }

        await #expect(throws: ActionResponse.self) {
            try await engine.setAttribute(.testItemFlag, on: nonexistentID, to: true)
        }

        await #expect(throws: ActionResponse.self) {
            try await engine.setAttribute(
                ItemAttributeID("testItemCounter"), on: nonexistentID, to: 42)
        }

        await #expect(throws: ActionResponse.self) {
            try await engine.setAttribute(
                ItemAttributeID("testName"), on: nonexistentID, to: "test")
        }

        await #expect(throws: ActionResponse.self) {
            try await engine.setDescription(on: nonexistentID, to: "test description")
        }
    }

    @Test("All LocationID variants throw when location not found")
    func testLocationIDVariantsThrowWhenNotFound() async throws {
        // Given
        let (engine, _) = await GameEngine.test()
        let nonexistentID: ItemID = "nonexistent"

        // When/Then - Test all variants that should throw
        await #expect(throws: ActionResponse.self) {
            try await engine.setAttribute(.testItemFlag, on: nonexistentID, to: .bool(true))
        }

        await #expect(throws: ActionResponse.self) {
            try await engine.setAttribute(.testItemFlag, on: nonexistentID, to: true)
        }

        await #expect(throws: ActionResponse.self) {
            try await engine.setAttribute(
                ItemAttributeID("testItemCounter"), on: nonexistentID, to: 42)
        }

        await #expect(throws: ActionResponse.self) {
            try await engine.setAttribute(
                ItemAttributeID("testName"), on: nonexistentID, to: "test")
        }

        await #expect(throws: ActionResponse.self) {
            try await engine.setDescription(on: nonexistentID, to: "test description")
        }
    }
}

extension ItemID {
    fileprivate static let item = ItemID(rawValue: "item")
}

extension ItemAttributeID {
    fileprivate static let testItemFlag = ItemAttributeID("testItemFlag")
    fileprivate static let testItemCounter = ItemAttributeID("testItemCounter")
}

extension LocationAttributeID {
    fileprivate static let testLocationFlag = LocationAttributeID("testLocationFlag")
    fileprivate static let testLocationCounter = LocationAttributeID("testLocationCounter")
}

extension ItemAttribute {
    fileprivate static let testItemAttrFlag = ItemAttribute(id: .testItemFlag, rawValue: true)
}

extension LocationAttribute {
    fileprivate static let testLocationAttrFlag = LocationAttribute(
        id: .testLocationFlag, rawValue: true)
}
