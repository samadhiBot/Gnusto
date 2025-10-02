import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("Proxy System Integration Tests")
struct ProxySystemIntegrationTests {

    // MARK: - ItemProxy Integration Tests

    @Test("ItemProxy integrates correctly with state changes through engine")
    func testItemProxyStateChangeIntegration() async throws {
        // Given
        let lamp = Item("lamp")
            .name("brass lamp")
            .description("A shiny brass lamp.")
            .isLightSource
            .isDevice
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Multiple operations that should work through proxies
        try await engine.execute(
            "take lamp",
            "turn on lamp",
            "examine lamp"
        )

        // Then: All operations should work correctly
        await mockIO.expectOutput(
            """
            > take lamp
            Taken.

            > turn on lamp
            You successfully turn on the brass lamp.

            > examine lamp
            A shiny brass lamp.
            """
        )

        // And: ItemProxy should reflect all changes
        let lampProxy = await engine.item("lamp")
        #expect(await lampProxy.parent == .player)
        #expect(await lampProxy.hasFlag(ItemPropertyID.isOn) == true)
        #expect(await lampProxy.hasFlag(ItemPropertyID.isTouched) == true)
    }

    @Test("LocationProxy integrates with dynamic lighting calculations")
    func testLocationProxyLightingIntegration() async throws {
        // Given
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")
        // No .inherentlyLit - room starts dark

        let brightRoom = Location("brightRoom")
            .name("Bright Room")
            .description("A well-lit room.")
            .inherentlyLit

        let torch = Item("torch")
            .name("wooden torch")
            .description("A burning wooden torch.")
            .isLightSource
            .isDevice
            .isOn
            .isTakable
            .in(.player)

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom, brightRoom,
            items: torch
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Moving between rooms with light source
        try await engine.execute(
            "look",
            "go to bright room",
            "look",
            "turn off torch",
            "look"
        )

        // Then: LocationProxy should correctly calculate lighting
        let darkRoomProxy = await engine.location("darkRoom")
        let brightRoomProxy = await engine.location("brightRoom")

        // Dark room should be lit when player has torch
        _ = await engine.player.move(to: "darkRoom")
        try await engine.execute("turn on torch")
        #expect(await darkRoomProxy.isLit == true)

        // Bright room should always be lit
        #expect(await brightRoomProxy.isLit == true)

        // Dark room should be dark when player has no light
        try await engine.execute("turn off torch")
        #expect(await darkRoomProxy.isLit == false)
    }

    @Test("PlayerProxy integrates with movement and inventory changes")
    func testPlayerProxyMovementIntegration() async throws {
        // Given
        let room1 = Location("room1")
            .name("Room One")
            .inherentlyLit
            .east("room2")

        let room2 = Location("room2")
            .name("Room Two")
            .inherentlyLit
            .west("room1")

        let coin = Item("coin")
            .name("gold coin")
            .description("A shiny gold coin.")
            .isTakable
            .in("room1")

        let game = MinimalGame(
            player: Player(in: "room1"),
            locations: room1, room2,
            items: coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player moves and interacts with items
        try await engine.execute(
            "take coin",
            "east",
            "inventory"
        )

        // Then: PlayerProxy should reflect all changes
        let playerProxy = await engine.player
        let playerLocation = await playerProxy.location
        #expect(playerLocation.id == LocationID("room2"))

        let playerItems = await playerProxy.inventory
        #expect(playerItems.count == 1)
        #expect(playerItems.first?.id == ItemID("coin"))

        await mockIO.expectOutput(
            """
            > take coin
            Taken.

            > east
            --- Room Two ---

            Error 404: Room description not found. But you're definitely
            somewhere.

            > inventory
            You are carrying:
            - A gold coin
            """
        )
    }

    // MARK: - Complex Multi-Proxy Scenarios

    @Test("Complex scenario with multiple interacting proxies")
    func testComplexMultiProxyScenario() async throws {
        // Given
        let laboratory = Location("laboratory")
            .name("Mad Scientist's Laboratory")
            .description("A cluttered laboratory filled with strange equipment.")
            .inherentlyLit
            .south("darkVault")

        let darkVault = Location("darkVault")
            .name("Dark Vault")
            .description("A pitch black vault.")
            .north("laboratory")
            // No inherent lighting

        let mysteriousBox = Item("mysteriousBox")
            .name("mysterious box")
            .description("A strange box with glowing runes.")
            .isContainer
            .isOpenable
            .isTakable
            .in("laboratory")

        let crystalOrb = Item("crystalOrb")
            .name("crystal orb")
            .description("A glowing crystal orb.")
            .isLightSource
            .isOn
            .isTakable
            .in(.item("mysteriousBox"))

        let game = MinimalGame(
            player: Player(in: "laboratory"),
            locations: laboratory, darkVault,
            items: mysteriousBox, crystalOrb
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Complex sequence of operations affecting multiple proxies
        try await engine.execute(
            "examine mysterious box",
            "open mysterious box",
            "take crystal orb",
            "put crystal orb in mysterious box",
            "close mysterious box",
            "take mysterious box",
            "south",
            "look"
        )

        // Then: All proxies should reflect the correct state
        let boxProxy = await engine.item("mysteriousBox")
        let orbProxy = await engine.item("crystalOrb")
        let vaultProxy = await engine.location("darkVault")
        let playerProxy = await engine.player

        // Box should be in player's inventory and closed
        #expect(await boxProxy.parent == .player)
        #expect(await boxProxy.hasFlag(ItemPropertyID.isOpen) == false)

        // Orb should be inside the box
        let orbParent = await orbProxy.parent
        if case .item(let parentItem) = orbParent {
            #expect(parentItem.id == ItemID("mysteriousBox"))
        }

        // Vault should be dark (orb is contained)
        #expect(await vaultProxy.isLit == false)

        // Player should be in the vault
        let playerLocation = await playerProxy.location
        #expect(playerLocation.id == LocationID("darkVault"))

        await mockIO.expectOutput(
            """
            > examine mysterious box
            A strange box with glowing runes. The mysterious box is closed.

            > open mysterious box
            As the mysterious box opens, it reveals a crystal orb within.

            > take crystal orb
            Got it.

            > put crystal orb in mysterious box
            The crystal orb finds a new home inside the mysterious box.

            > close mysterious box
            Closed.

            > take mysterious box
            Got it.

            > south
            You are swallowed by impenetrable shadow.

            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.

            > look
            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.
            """
        )
    }

    @Test("Proxy system handles concurrent state changes correctly")
    func testConcurrentProxyOperations() async throws {
        // Given
        var items: [Item] = []
        for i in 1...5 {
            items.append(
                Item(ItemID("item\(i)"))
                    .name("test item \(i)")
                    .description("Test item number \(i).")
                    .isTakable
                    .in(.startRoom)
            )
        }

        let game = MinimalGame(
            items: items[0], items[1], items[2], items[3], items[4]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Taking all items in sequence (simulates concurrent state changes)
        try await engine.execute("take all")

        // Then: All items should be properly moved to player
        for i in 1...5 {
            let itemProxy = await engine.item(ItemID("item\(i)"))
            #expect(await itemProxy.parent == .player)
            #expect(await itemProxy.hasFlag(ItemPropertyID.isTouched) == true)
        }

        let playerProxy = await engine.player
        let playerItems = await playerProxy.inventory
        #expect(playerItems.count == 5)

        await mockIO.expectOutput(
            """
            > take all
            You take the test item 1, the test item 2, the test item 3, the
            test item 4, and the test item 5.
            """
        )
    }

    // MARK: - Proxy Computed Properties Integration

    @Test("Proxy computed properties work correctly in complex scenarios")
    func testProxyComputedPropertiesIntegration() async throws {
        // Given
        let workshop = Location("workshop")
            .name("Inventor's Workshop")
            .description("A workshop filled with mechanical contraptions.")
            .inherentlyLit

        let mechanicalDevice = Item("mechanicalDevice")
            .name("mechanical device")
            .description("A complex mechanical device with gears and springs.")
            .isDevice
            .isContainer
            .isOpenable
            .isTakable
            .capacity(3)
            .in("workshop")

        let gear1 = Item("gear1")
            .name("bronze gear")
            .description("A small bronze gear.")
            .isTakable
            .size(1)
            .in(.item("mechanicalDevice"))

        let gear2 = Item("gear2")
            .name("silver gear")
            .description("A medium silver gear.")
            .isTakable
            .size(2)
            .in(.item("mechanicalDevice"))

        let game = MinimalGame(
            player: Player(in: "workshop"),
            locations: workshop,
            items: mechanicalDevice, gear1, gear2
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Interacting with container and checking computed properties
        try await engine.execute(
            "open mechanical device",
            "examine mechanical device"
        )

        // Then: Proxy computed properties should reflect current state
        let deviceProxy = await engine.item("mechanicalDevice")

        // Should have 2 items inside
        let contents = await deviceProxy.contents
        #expect(contents.count == 2)

        // Should show correct capacity usage (1 + 2 = 3 out of 3)
        // Should be at capacity - check by examining contents size
        var totalSize = 0
        for proxy in contents {
            let size = await proxy.size
            totalSize += size
        }
        #expect(totalSize == 3)

        await mockIO.expectOutput(
            """
            > open mechanical device
            As the mechanical device opens, it reveals a bronze gear and a
            silver gear within.

            > examine mechanical device
            A complex mechanical device with gears and springs. In the
            mechanical device you can see a bronze gear and a silver gear.
            """
        )
    }

    // MARK: - Cross-Proxy Communication

    @Test("Proxies correctly communicate changes across the system")
    func testCrossProxyCommunication() async throws {
        // Given
        let magicShop = Location("magicShop")
            .name("Magic Shop")
            .description("A mystical shop filled with enchanted items.")
            .inherentlyLit

        let enchantedMirror = Item("enchantedMirror")
            .name("enchanted mirror")
            .description("A mirror that reflects magical auras.")
            .in("magicShop")

        let magicWand = Item("magicWand")
            .name("magic wand")
            .description("A wand crackling with arcane energy.")
            .isLightSource
            .isDevice
            .isTakable
            .in("magicShop")

        let game = MinimalGame(
            player: Player(in: "magicShop"),
            locations: magicShop,
            items: enchantedMirror, magicWand
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player actions affect multiple proxies
        try await engine.execute(
            "take magic wand",
            "turn on magic wand",
            "examine enchanted mirror"
        )

        // Then: All proxies should show consistent state
        let wandProxy = await engine.item("magicWand")
        let mirrorProxy = await engine.item("enchantedMirror")
        let shopProxy = await engine.location("magicShop")
        let playerProxy = await engine.player

        // Wand should be with player and on
        #expect(await wandProxy.parent == .player)
        #expect(await wandProxy.hasFlag(ItemPropertyID.isOn) == true)

        // Player should have the wand
        let playerItems = await playerProxy.inventory
        #expect(playerItems.contains { $0.id == ItemID("magicWand") })

        // Shop should still contain the mirror
        let shopItems = await shopProxy.items
        #expect(shopItems.contains { $0.id == ItemID("enchantedMirror") })

        // All proxies should be accessible and functional
        let mirrorLocation = await mirrorProxy.parent
        if case .location(let loc) = mirrorLocation {
            #expect(loc.id == LocationID("magicShop"))
        }

        await mockIO.expectOutput(
            """
            > take magic wand
            Taken.

            > turn on magic wand
            You successfully turn on the magic wand.

            > examine enchanted mirror
            A mirror that reflects magical auras.
            """
        )
    }
}
