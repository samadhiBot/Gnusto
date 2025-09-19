import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("LocationProxy Tests")
struct LocationProxyTests {

    // MARK: - Core Functionality Tests

    @Test("LocationProxy basic creation and identity")
    func testLocationProxyBasics() async throws {
        // Given
        let testRoom = Location(
            id: .startRoom,
            .name("Test Room"),
            .description("A room for testing location proxies."),
            .inherentlyLit
        )

        let game = MinimalGame(locations: testRoom)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let proxy = await engine.location(.startRoom)

        // Then
        #expect(proxy.id == .startRoom)
    }

    @Test("LocationProxy property access")
    func testLocationProxyPropertyAccess() async throws {
        // Given
        let testRoom = Location(
            id: .startRoom,
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit,
            .localGlobals("globalItem1", "globalItem2")
        )

        let game = MinimalGame(locations: testRoom)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = await engine.location(.startRoom)

        // When/Then - Test basic property access
        let name = await proxy.property(.name)?.toString
        #expect(name == "Test Room")

        let description = await proxy.property(.description)?.toString
        #expect(description == "A room for testing.")

        let isLit = await proxy.property(.inherentlyLit)?.toBool
        #expect(isLit == true)
    }

    @Test("LocationProxy equality and hashing")
    func testLocationProxyEquality() async throws {
        // Given
        let room1 = Location(
            id: "room1",
            .name("First Room"),
            .inherentlyLit
        )

        let room2 = Location(
            id: "room2",
            .name("Second Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "room1"),
            locations: room1, room2
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let proxy1a = await engine.location("room1")
        let proxy1b = await engine.location("room1")
        let proxy2 = await engine.location("room2")

        // Then
        #expect(proxy1a == proxy1b)
        #expect(proxy1a != proxy2)
        #expect(proxy1a.hashValue == proxy1b.hashValue)
    }

    // MARK: - Accessor Tests

    @Test("LocationProxy name and description accessors")
    func testNameAndDescriptionAccessors() async throws {
        // Given
        let roomWithDescription = Location(
            id: "library",
            .name("Grand Library"),
            .description("A vast library filled with ancient tomes."),
            .inherentlyLit
        )

        let roomWithoutDescription = Location(
            id: "emptyRoom",
            .name("Empty Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "library"),
            locations: roomWithDescription, roomWithoutDescription
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then
        let libraryProxy = await engine.location("library")
        let name = await libraryProxy.name
        #expect(name == "Grand Library")

        let description = await libraryProxy.description
        #expect(description == "A vast library filled with ancient tomes.")

        let emptyProxy = await engine.location("emptyRoom")
        let emptyDescription = await emptyProxy.description
        #expect(!emptyDescription.isEmpty)  // Should get one of the random undescribed location messages
    }

    @Test("LocationProxy flag checking methods")
    func testFlagCheckingMethods() async throws {
        // Given
        let litRoom = Location(
            id: "litRoom",
            .name("Lit Room"),
            .inherentlyLit
        )

        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room")
            // No inherentlyLit flag
        )

        let specialRoom = Location(
            id: "specialRoom",
            .name("Special Room"),
            .inherentlyLit,
            .omitArticle
        )

        let game = MinimalGame(
            player: Player(in: "litRoom"),
            locations: litRoom, darkRoom, specialRoom
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then
        let litProxy = await engine.location("litRoom")
        #expect(await litProxy.hasFlag(.inherentlyLit) == true)
        #expect(await litProxy.hasFlag(.omitArticle) == false)

        let darkProxy = await engine.location("darkRoom")
        #expect(await darkProxy.hasFlag(.inherentlyLit) == false)

        let specialProxy = await engine.location("specialRoom")
        #expect(await specialProxy.hasFlags(any: .inherentlyLit, .omitArticle) == true)
        #expect(await specialProxy.hasFlag(.inherentlyLit) == true)
        #expect(await specialProxy.hasFlag(.omitArticle) == true)
    }

    @Test("LocationProxy lighting calculations")
    func testLightingCalculations() async throws {
        // Given
        let litRoom = Location(
            id: "litRoom",
            .name("Lit Room"),
            .inherentlyLit
        )

        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room")
        )

        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .isLightSource,
            .isDevice,
            .isOn,
            .isTakable,
            .in(.player)
        )

        let unlit_lamp = Item(
            id: "unlitLamp",
            .name("unlit lamp"),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in("darkRoom")
        )

        let torch = Item(
            id: "torch",
            .name("burning torch"),
            .isLightSource,
            .isBurning,
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "litRoom"),
            locations: litRoom, darkRoom,
            items: lamp, unlit_lamp, torch
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then
        let litProxy = await engine.location("litRoom")
        #expect(await litProxy.isLit == true)  // Inherently lit

        let darkProxy = await engine.location("darkRoom")
        #expect(await darkProxy.isLit == true)  // Has burning torch

        // Move player to dark room without lamp
        try await engine.execute("drop lamp")
        try await engine.execute("go to darkRoom")

        // Dark room should still be lit due to burning torch
        #expect(await darkProxy.isLit == true)
    }

    @Test("LocationProxy items and contents")
    func testItemsAndContents() async throws {
        // Given
        let visibleItem = Item(
            id: "book",
            .name("leather book"),
            .description("A worn book."),
            .in(.startRoom)
        )

        let invisibleItem = Item(
            id: "hiddenKey",
            .name("hidden key"),
            .isInvisible,
            .in(.startRoom)
        )

        let omittedItem = Item(
            id: "air",
            .name("air"),
            .omitDescription,
            .in(.startRoom)
        )

        let openContainer = Item(
            id: "openBox",
            .name("open box"),
            .isContainer,
            .isOpen,
            .in(.startRoom)
        )

        let itemInContainer = Item(
            id: "gem",
            .name("sparkling gem"),
            .in(.item("openBox"))
        )

        let closedContainer = Item(
            id: "closedBox",
            .name("closed box"),
            .isContainer,
            .in(.startRoom)
        )

        let itemInClosedContainer = Item(
            id: "coin",
            .name("gold coin"),
            .in(.item("closedBox"))
        )

        let game = MinimalGame(
            items: visibleItem, invisibleItem, omittedItem, openContainer,
            itemInContainer, closedContainer, itemInClosedContainer
        )

        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = await engine.location(.startRoom)

        // When/Then
        let allItems = await proxy.allItems
        #expect(allItems.count == 7)  // All items including hidden ones and contents

        let directItems = await proxy.items
        #expect(directItems.count == 5)  // Only items directly in room

        let visibleItems = await proxy.visibleItems
        #expect(visibleItems.count == 4)  // book, openBox, gem (visible through open container), closedBox
    }

    @Test("LocationProxy exits handling")
    func testExitsHandling() async throws {
        // Given
        let room1 = Location(
            id: "room1",
            .name("First Room"),
            .inherentlyLit,
            .exits(
                .north("room2"),
                .south("room3")
            )
        )

        let room2 = Location(
            id: "room2",
            .name("Second Room"),
            .inherentlyLit,
            .exits(
                .south("room1")
            )
        )

        let room3 = Location(
            id: "room3",
            .name("Third Room"),
            .inherentlyLit,
            .exits(
                .north("room1")
            )
        )

        let game = MinimalGame(
            player: Player(in: "room1"),
            locations: room1, room2, room3
        )

        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = await engine.location("room1")

        // When/Then
        let exits = await proxy.exits
        expectNoDifference(
            exits,
            [
                .north("room2"),
                .south("room3"),
            ])
    }

    @Test("LocationProxy local globals")
    func testLocalGlobals() async throws {
        // Given
        let testRoom = Location(
            id: .startRoom,
            .name("Test Room"),
            .inherentlyLit,
            .localGlobals("globalItem1", "globalItem2", "globalItem3")
        )

        let game = MinimalGame(locations: testRoom)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = await engine.location(.startRoom)

        // When/Then
        let globals = await proxy.localGlobals
        #expect(globals.count == 3)
        #expect(globals.contains("globalItem1"))
        #expect(globals.contains("globalItem2"))
        #expect(globals.contains("globalItem3"))
    }

    @Test("LocationProxy article methods")
    func testArticleMethods() async throws {
        // Given
        let regularRoom = Location(
            id: "library",
            .name("Grand Library"),
            .inherentlyLit
        )

        let noArticleRoom = Location(
            id: "nowhere",
            .name("Nowhere"),
            .omitArticle,
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "library"),
            locations: regularRoom, noArticleRoom
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then
        let libraryProxy = await engine.location("library")
        #expect(await libraryProxy.withDefiniteArticle == "the Grand Library")

        let nowhereProxy = await engine.location("nowhere")
        #expect(await nowhereProxy.withDefiniteArticle == "Nowhere")
    }

    // MARK: - State Change Tests

    @Test("LocationProxy flag setting and clearing")
    func testFlagSettingAndClearing() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = await engine.location(.startRoom)

        // When/Then - Test setting a flag
        #expect(await proxy.hasFlag(.isVisited) == false)

        let setChange = await proxy.setFlag(.isVisited)
        #expect(setChange != nil)
        if let setChange {
            if case .setLocationProperty(let id, _, _) = setChange {
                #expect(id == .startRoom)
            } else {
                #expect(Bool(false), "Expected setLocationProperty case")
            }
        }

        // Apply the change to update the game state
        try await engine.apply(setChange)

        // Test setting the same flag again returns nil
        let noChange = await proxy.setFlag(.isVisited)
        #expect(noChange == nil)

        // Test clearing a flag
        let clearChange = await proxy.clearFlag(.isVisited)
        #expect(clearChange != nil)

        // Apply the change to update the game state
        try await engine.apply(clearChange)

        // Test clearing an already false flag returns nil
        let noClearChange = await proxy.clearFlag(.isVisited)
        #expect(noClearChange == nil)
    }

    @Test("LocationProxy property setting methods")
    func testPropertySettingMethods() async throws {
        // Given
        let testRoom = Location(
            id: .startRoom,
            .name("Test Room"),
            .description("Original description"),
            .inherentlyLit
        )

        let game = MinimalGame(locations: testRoom)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = await engine.location(.startRoom)

        // When/Then - Test setting string property
        let descChange = await proxy.setDescription(to: "New description")
        #expect(descChange != nil)

        let sameDescChange = await proxy.setDescription(to: "Original description")
        #expect(sameDescChange == nil)  // No change needed

        // Test setting boolean property
        let boolChange = await proxy.setProperty(.isVisited, to: true)
        #expect(boolChange != nil)

        // Test setting integer property (if any exist)
        // Most location properties are booleans or strings

        // Test setting string property directly
        let stringChange = await proxy.setProperty(.name, to: "New Name")
        #expect(stringChange != nil)
    }

    @Test("LocationProxy complex lighting scenarios")
    func testComplexLightingScenarios() async throws {
        // Given
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Cave")
        )

        let lamp = Item(
            id: "lamp",
            .name("oil lamp"),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.player)
        )

        let candle = Item(
            id: "candle",
            .name("wax candle"),
            .isLightSource,
            .isBurning,
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: lamp, candle
        )

        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = await engine.location("darkRoom")

        // When/Then - Room should be lit due to burning candle
        #expect(await proxy.isLit == true)

        // Turn on lamp - should still be lit
        try await engine.execute("turn on lamp")
        #expect(await proxy.isLit == true)

        // Put out candle and turn off lamp - should be dark
        // (This would require implementing extinguish command and state changes)
        // For now, just test that burning items provide light
        let candleProxy = await engine.item("candle")
        #expect(await candleProxy.isProvidingLight == true)
    }

    @Test("LocationProxy item visibility with containers")
    func testItemVisibilityWithContainers() async throws {
        // Given
        let transparentBox = Item(
            id: "glassBox",
            .name("glass box"),
            .isContainer,
            .isTransparent,
            .in(.startRoom)
        )

        let visibleThroughGlass = Item(
            id: "gem",
            .name("ruby gem"),
            .in(.item("glassBox"))
        )

        let surface = Item(
            id: "table",
            .name("wooden table"),
            .isSurface,
            .in(.startRoom)
        )

        let itemOnSurface = Item(
            id: "book",
            .name("old book"),
            .in(.item("table"))
        )

        let game = MinimalGame(
            items: transparentBox, visibleThroughGlass, surface, itemOnSurface
        )

        let (engine, _) = await GameEngine.test(blueprint: game)
        let proxy = await engine.location(.startRoom)

        // When/Then
        let visibleItems = await proxy.visibleItems

        // Should include: glassBox, gem (through transparent container), table, book (on surface)
        let itemNames = Set(visibleItems.map { $0.id.rawValue })
        #expect(itemNames.contains("glassBox"))
        #expect(itemNames.contains("gem"))
        #expect(itemNames.contains("table"))
        #expect(itemNames.contains("book"))
        #expect(visibleItems.count == 4)
    }
}
