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
        let game = MinimalGame(items: [item])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(blueprint: game, parser: MockParser(), ioHandler: mockIO)

        // When
        let change = try await engine.clearFlag(.testFlag, on: item.id)

        // Then
        #expect(change != nil)
        #expect(change?.entityID == .item("testItem"))
        #expect(change?.attribute == .itemAttribute(.testFlag))
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
        let game = MinimalGame(items: [item])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(blueprint: game, parser: MockParser(), ioHandler: mockIO)

        // When
        let change = try await engine.clearFlag(.testFlag, on: item.id)

        // Then
        #expect(change == nil)
    }

    @Test("clearFlag with ItemID - nil when itemID is nil")
    func testClearFlagItemIDWhenNil() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(blueprint: game, parser: MockParser(), ioHandler: mockIO)

        // When
        let nilItemID: ItemID? = nil

        // Then
        await #expect(throws: ActionResponse.self) {
            try await engine.clearFlag(.testFlag, on: nilItemID)
        }
    }

    @Test("clearFlag with ItemID - throws when item not found")
    func testClearFlagItemIDThrowsWhenNotFound() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(blueprint: game, parser: MockParser(), ioHandler: mockIO)

        // When/Then
        await #expect(throws: ActionResponse.self) {
            try await engine.clearFlag(.testFlag, on: ItemID("nonexistentItem"))
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
        let game = MinimalGame(items: [item])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(blueprint: game, parser: MockParser(), ioHandler: mockIO)

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
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(blueprint: game, parser: MockParser(), ioHandler: mockIO)

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
        let game = MinimalGame(items: [item])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(blueprint: game, parser: MockParser(), ioHandler: mockIO)

        // When
        let change = try await engine.setAttribute(.testCounter, on: item.id, to: .int(42))

        // Then
        #expect(change != nil)
        #expect(change?.entityID == .item("testItem"))
        #expect(change?.attribute == .itemAttribute(.testCounter))
        #expect(change?.newValue == .int(42))
    }

    @Test("setAttribute with ItemID - Bool variant")
    func testSetAttributeItemIDBool() async throws {
        // Given
        let item = Item(
            id: "testItem",
            .name("Test Item")
        )
        let game = MinimalGame(items: [item])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(blueprint: game, parser: MockParser(), ioHandler: mockIO)

        // When
        let change = try await engine.setAttribute(.testFlag, on: item.id, to: true)

        // Then
        #expect(change != nil)
        #expect(change?.entityID == .item("testItem"))
        #expect(change?.attribute == .itemAttribute(.testFlag))
        #expect(change?.newValue == true)
    }

    @Test("setFlag with ItemID - success")
    func testSetFlagItemIDSuccess() async throws {
        // Given
        let item = Item(
            id: "testItem",
            .name("Test Item")
        )
        let game = MinimalGame(items: [item])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(blueprint: game, parser: MockParser(), ioHandler: mockIO)

        // When
        let change = try await engine.setFlag(.testFlag, on: item.id)

        // Then
        #expect(change != nil)
        #expect(change?.newValue == true)
    }

    @Test("setFlag with ItemID - nil when itemID is nil")
    func testSetFlagItemIDWhenNil() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(blueprint: game, parser: MockParser(), ioHandler: mockIO)

        // When
        let nilItemID: ItemID? = nil

        // Then
        await #expect(throws: ActionResponse.self) {
            try await engine.clearFlag(.testFlag, on: nilItemID)
        }
    }

    @Test("setDescription with ItemID - success")
    func testSetDescriptionItemIDSuccess() async throws {
        // Given
        let item = Item(
            id: "testItem",
            .name("Test Item")
        )
        let game = MinimalGame(items: [item])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(blueprint: game, parser: MockParser(), ioHandler: mockIO)

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
        let game = MinimalGame(locations: [location])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(blueprint: game, parser: MockParser(), ioHandler: mockIO)

        // When
        let change = try await engine.clearFlag(.testFlag, on: LocationID("testLocation"))

        // Then
        #expect(change != nil)
        #expect(change?.entityID == .location("testLocation"))
        #expect(change?.attribute == .locationAttribute(.testFlag))
        #expect(change?.oldValue == true)
        #expect(change?.newValue == false)
    }

    @Test("clearFlag with LocationID - throws when location not found")
    func testClearFlagLocationIDThrowsWhenNotFound() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(blueprint: game, parser: MockParser(), ioHandler: mockIO)

        // When/Then
        await #expect(throws: ActionResponse.self) {
            try await engine.clearFlag(.testFlag, on: LocationID("nonexistentLocation"))
        }
    }

    @Test("setFlag with LocationID - success")
    func testSetFlagLocationIDSuccess() async throws {
        // Given
        let location = Location(
            id: "testLocation",
            .name("Test Location")
        )
        let game = MinimalGame(locations: [location])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(blueprint: game, parser: MockParser(), ioHandler: mockIO)

        // When
        let change = try await engine.setFlag(.testFlag, on: LocationID("testLocation"))

        // Then
        #expect(change != nil)
        #expect(change?.entityID == .location("testLocation"))
        #expect(change?.attribute == .locationAttribute(.testFlag))
        #expect(change?.newValue == true)
    }

    @Test("setAttribute with LocationID - StateValue variant")
    func testSetAttributeLocationIDStateValue() async throws {
        // Given
        let testCounter = AttributeID("testCounter")
        let location = Location(
            id: "testLocation",
            .name("Test Location")
        )
        let game = MinimalGame(locations: [location])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(blueprint: game, parser: MockParser(), ioHandler: mockIO)

        // When
        let change = try await engine.setAttribute(.testCounter, on: LocationID("testLocation"), to: .int(42))

        // Then
        #expect(change != nil)
        #expect(change?.entityID == .location("testLocation"))
        #expect(change?.attribute == .locationAttribute(testCounter))
        #expect(change?.newValue == .int(42))
    }

    @Test("setDescription with LocationID - success")
    func testSetDescriptionLocationIDSuccess() async throws {
        // Given
        let location = Location(
            id: "testLocation",
            .name("Test Location")
        )
        let game = MinimalGame(locations: [location])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(blueprint: game, parser: MockParser(), ioHandler: mockIO)

        // When
        let change = try await engine.setDescription(on: LocationID("testLocation"), to: "New description")

        // Then
        #expect(change != nil)
        #expect(change?.newValue == .string("New description"))
    }

    // MARK: - Error handling comprehensive tests

    @Test("All ItemID variants throw when item not found")
    func testItemIDVariantsThrowWhenNotFound() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(blueprint: game, parser: MockParser(), ioHandler: mockIO)
        let nonexistentID: ItemID = "nonexistent"

        // When/Then - Test all variants that should throw
        await #expect(throws: ActionResponse.self) {
            try await engine.move(nonexistentID, to: .player)
        }

        await #expect(throws: ActionResponse.self) {
            try await engine.setAttribute(.testFlag, on: nonexistentID, to: .bool(true))
        }

        await #expect(throws: ActionResponse.self) {
            try await engine.setAttribute(.testFlag, on: nonexistentID, to: true)
        }

        await #expect(throws: ActionResponse.self) {
            try await engine.setAttribute(AttributeID("testCounter"), on: nonexistentID, to: 42)
        }

        await #expect(throws: ActionResponse.self) {
            try await engine.setAttribute(AttributeID("testName"), on: nonexistentID, to: "test")
        }

        await #expect(throws: ActionResponse.self) {
            try await engine.setDescription(on: nonexistentID, to: "test description")
        }
    }

    @Test("All LocationID variants throw when location not found")
    func testLocationIDVariantsThrowWhenNotFound() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(blueprint: game, parser: MockParser(), ioHandler: mockIO)
        let nonexistentID: LocationID = "nonexistent"

        // When/Then - Test all variants that should throw
        await #expect(throws: ActionResponse.self) {
            try await engine.setAttribute(.testFlag, on: nonexistentID, to: .bool(true))
        }

        await #expect(throws: ActionResponse.self) {
            try await engine.setAttribute(.testFlag, on: nonexistentID, to: true)
        }

        await #expect(throws: ActionResponse.self) {
            try await engine.setAttribute(AttributeID("testCounter"), on: nonexistentID, to: 42)
        }

        await #expect(throws: ActionResponse.self) {
            try await engine.setAttribute(AttributeID("testName"), on: nonexistentID, to: "test")
        }

        await #expect(throws: ActionResponse.self) {
            try await engine.setDescription(on: nonexistentID, to: "test description")
        }
    }
}

private extension ItemID {
    static let item = ItemID(rawValue: "item")
}

private extension AttributeID {
    static let testFlag = AttributeID("testFlag")
    static let testCounter = AttributeID("testCounter")
}

private extension ItemAttribute {
    static let testItemAttrFlag = ItemAttribute(id: .testFlag, rawValue: true)
}

private extension LocationAttribute {
    static let testLocationAttrFlag = LocationAttribute(id: .testFlag, rawValue: true)
}
