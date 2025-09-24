import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("Modernization Success Demonstration Tests")
struct ModernizationSuccessTests {

    // MARK: - Modern Swift Testing Framework

    @Test("Modern @Test syntax works correctly")
    func testModernTestSyntax() async throws {
        // Given: A simple game setup
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Executing a basic command
        try await engine.execute("look")

        // Then: Modern expectation syntax works
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.
            """
        )
    }

    // MARK: - Proxy System Modernization

    @Test("ItemProxy system works with modern async/await")
    func testItemProxyModernization() async throws {
        // Given: Modern game setup with items
        let modernItem = Item(
            id: "modernItem",
            .name("modern item"),
            .description("An item for testing modern features."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: modernItem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Using modern async operations
        try await engine.execute("take modern item")
        try await engine.execute("examine modern item")

        // Then: ItemProxy shows modern async properties
        let itemProxy = await engine.item("modernItem")
        #expect(await itemProxy.name == "modern item")
        #expect(await itemProxy.hasFlag(ItemPropertyID.isTouched) == true)

        // Verify parent relationship using pattern matching
        let parent = await itemProxy.parent
        if case .player = parent {
            // Success - item is with player
        } else {
            #expect(Bool(false), "Item should be with player")
        }

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take modern item
            Acquired.

            > examine modern item
            An item for testing modern features.
            """
        )
    }

    @Test("LocationProxy system integrates with modern concurrency")
    func testLocationProxyModernization() async throws {
        // Given: Multiple locations for testing
        let brightRoom = Location(
            id: "brightRoom",
            .name("Bright Room"),
            .description("A modern, well-lit room."),
            .inherentlyLit
        )

        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A room without lighting.")
        )

        let game = MinimalGame(
            player: Player(in: "brightRoom"),
            locations: brightRoom, darkRoom
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Accessing modern LocationProxy features
        let brightProxy = await engine.location("brightRoom")
        let darkProxy = await engine.location("darkRoom")

        // Then: Async properties work correctly
        #expect(await brightProxy.name == "Bright Room")
        #expect(await darkProxy.name == "Dark Room")
        #expect(await brightProxy.isLit == true)
        #expect(await darkProxy.isLit == false)
    }

    @Test("PlayerProxy demonstrates modern inventory management")
    func testPlayerProxyModernization() async throws {
        // Given: Game with items for inventory testing
        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .isTakable,
            .in(.startRoom)
        )

        let key = Item(
            id: "key",
            .name("silver key"),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: coin, key
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Modern inventory operations
        try await engine.execute("take coin")
        try await engine.execute("take key")

        // Then: PlayerProxy shows modern async inventory
        let playerProxy = await engine.player
        let inventory = await playerProxy.inventory

        #expect(inventory.count == 2)
        #expect(inventory.contains { $0.id == ItemID("coin") })
        #expect(inventory.contains { $0.id == ItemID("key") })

        // Verify player location using modern syntax
        let currentLocation = await playerProxy.location
        #expect(currentLocation.id == .startRoom)
    }

    // MARK: - State Change System Modernization

    @Test("Modern state changes work atomically")
    func testModernStateChanges() async throws {
        // Given: Device for state change testing
        let device = Item(
            id: "device",
            .name("test device"),
            .description("A device for state testing."),
            .isDevice,
            .isLightSource,
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: device
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Operations causing multiple state changes
        try await engine.execute("take device")
        try await engine.execute("turn on device")

        // Then: All state changes applied atomically
        let deviceProxy = await engine.item("device")

        // Verify device state using modern async flags
        #expect(await deviceProxy.hasFlag(ItemPropertyID.isDevice) == true)
        #expect(await deviceProxy.hasFlag(ItemPropertyID.isLightSource) == true)
        #expect(await deviceProxy.hasFlag(ItemPropertyID.isOn) == true)
        #expect(await deviceProxy.hasFlag(ItemPropertyID.isTouched) == true)

        // Verify parent using pattern matching
        let parent = await deviceProxy.parent
        if case .player = parent {
            // Success - device is with player
        } else {
            #expect(Bool(false), "Device should be with player")
        }
    }

    // MARK: - Integration Success Tests

    @Test("Complete modernization integration works end-to-end")
    func testCompleteModernizationIntegration() async throws {
        // Given: Complete game scenario
        let workshop = Location(
            id: "workshop",
            .name("Modern Workshop"),
            .description("A workshop for testing modern features."),
            .inherentlyLit
        )

        let toolbox = Item(
            id: "toolbox",
            .name("toolbox"),
            .description("A container for tools."),
            .isContainer,
            .isOpenable,
            .isOpen,
            .isTakable,
            .in("workshop")
        )

        let hammer = Item(
            id: "hammer",
            .name("hammer"),
            .description("A useful hammer."),
            .isTakable,
            .in(.item("toolbox"))
        )

        let game = MinimalGame(
            player: Player(in: "workshop"),
            locations: workshop,
            items: toolbox, hammer
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Complete workflow using modern features
        try await engine.execute("look")
        try await engine.execute("examine toolbox")
        try await engine.execute("take hammer from toolbox")
        try await engine.execute("take toolbox")
        try await engine.execute("inventory")

        // Then: All modern systems working together
        let output = await mockIO.flush()

        // Verify output contains expected elements
        #expect(output.contains("Modern Workshop"))
        #expect(output.contains("hammer"))
        #expect(output.contains("toolbox"))
        #expect(output.contains("Got it."))

        // Verify modern proxy states
        let hammerProxy = await engine.item("hammer")
        let toolboxProxy = await engine.item("toolbox")
        let playerProxy = await engine.player

        // Modern async property checks
        #expect(await hammerProxy.name == "hammer")
        #expect(await toolboxProxy.name == "toolbox")

        // Modern parent relationship checks
        let hammerParent = await hammerProxy.parent
        let toolboxParent = await toolboxProxy.parent

        if case .player = hammerParent, case .player = toolboxParent {
            // Success - both items with player
        } else {
            #expect(Bool(false), "Both items should be with player")
        }

        // Modern inventory check
        let inventory = await playerProxy.inventory
        #expect(inventory.count == 2)

        // Modern location check
        let currentLocation = await playerProxy.location
        #expect(currentLocation.id == LocationID("workshop"))
        #expect(await currentLocation.name == "Modern Workshop")
    }
}
