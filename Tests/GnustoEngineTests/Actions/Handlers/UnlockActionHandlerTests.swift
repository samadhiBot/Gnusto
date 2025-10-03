import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("UnlockActionHandler Tests")
struct UnlockActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("UNLOCK DIRECTOBJECT syntax works")
    func testUnlockDirectObjectSyntax() async throws {
        // Given
        let chest = Item("chest")
            .name("wooden chest")
            .description("A locked wooden chest.")
            .isLockable
            .isLocked
            .lockKey("missingKey")
            .in(.startRoom)

        let game = MinimalGame(
            items: chest
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("unlock chest")

        // Then
        await mockIO.expect(
            """
            > unlock chest
            Unlock the wooden chest with what?
            """
        )
    }

    @Test("UNLOCK DIRECTOBJECT WITH INDIRECTOBJECT syntax works")
    func testUnlockWithSyntax() async throws {
        // Given
        let door = Item("door")
            .name("oak door")
            .description("A sturdy oak door with a brass lock.")
            .isLockable
            .isLocked
            .lockKey("brassKey")
            .in(.startRoom)

        let key = Item("brassKey")
            .name("brass key")
            .description("A shiny brass key.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: door, key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("unlock door with key")

        // Then
        await mockIO.expect(
            """
            > unlock door with key
            The oak door is now unlocked.
            """
        )

        let finalDoor = await engine.item("door")
        let finalKey = await engine.item("brassKey")
        #expect(await finalDoor.hasFlag(.isLocked) == false)
        #expect(await finalDoor.hasFlag(.isTouched) == true)
        #expect(await finalKey.hasFlag(.isTouched) == true)
    }

    // MARK: - Validation Testing

    @Test("Cannot unlock without specifying what")
    func testCannotUnlockWithoutWhat() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("unlock")

        // Then
        await mockIO.expect(
            """
            > unlock
            Unlock what?
            """
        )
    }

    @Test("Cannot unlock without specifying key")
    func testCannotUnlockWithoutKey() async throws {
        // Given
        let safe = Item("safe")
            .name("metal safe")
            .description("A heavy metal safe.")
            .lockKey("missingKey")
            .isLockable
            .isLocked
            .in(.startRoom)

        let game = MinimalGame(
            items: safe
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("unlock safe")

        // Then
        await mockIO.expect(
            """
            > unlock safe
            Unlock the metal safe with what?
            """
        )
    }

    @Test("Cannot unlock with key not held")
    func testCannotUnlockWithKeyNotHeld() async throws {
        // Given
        let box = Item("box")
            .name("jewelry box")
            .description("An ornate jewelry box.")
            .isLockable
            .isLocked
            .lockKey("silverKey")
            .in(.startRoom)

        let key = Item("silverKey")
            .name("silver key")
            .description("A delicate silver key.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: box, key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("unlock box with key")

        // Then
        await mockIO.expect(
            """
            > unlock box with key
            You aren't holding the silver key.
            """
        )
    }

    @Test("Cannot unlock item not in scope")
    func testCannotUnlockItemNotInScope() async throws {
        // Given
        let anotherRoom = Location("anotherRoom")
            .name("Another Room")
            .inherentlyLit

        let remoteDoor = Item("remoteDoor")
            .name("remote door")
            .description("A door in another room.")
            .isLockable
            .isLocked
            .in("anotherRoom")

        let key = Item("key")
            .name("master key")
            .description("A master key.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteDoor, key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("unlock door with key")

        // Then
        await mockIO.expect(
            """
            > unlock door with key
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot unlock non-lockable item")
    func testCannotUnlockNonLockableItem() async throws {
        // Given
        let table = Item("table")
            .name("wooden table")
            .description("A simple wooden table.")
            .in(.startRoom)

        let key = Item("key")
            .name("old key")
            .description("An old key.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: table, key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("unlock table with key")

        // Then
        await mockIO.expect(
            """
            > unlock table with key
            That's not something you can unlock.
            """
        )
    }

    @Test("Cannot unlock already unlocked item")
    func testCannotUnlockAlreadyUnlocked() async throws {
        // Given
        let cabinet = Item("cabinet")
            .name("glass cabinet")
            .description("A glass display cabinet.")
            .isLockable
            .lockKey("cabinetKey")
            .in(.startRoom)
            // Note: No .isLocked flag - already unlocked

        let key = Item("cabinetKey")
            .name("cabinet key")
            .description("A key for the cabinet.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: cabinet, key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("unlock cabinet with key")

        // Then
        await mockIO.expect(
            """
            > unlock cabinet with key
            The glass cabinet is already unlocked.
            """
        )
    }

    @Test("Cannot unlock with wrong key")
    func testCannotUnlockWithWrongKey() async throws {
        // Given
        let strongbox = Item("strongbox")
            .name("iron strongbox")
            .description("A heavy iron strongbox.")
            .isLockable
            .isLocked
            .lockKey("ironKey")
            .in(.startRoom)

        let wrongKey = Item("copperKey")
            .name("copper key")
            .description("A copper key.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: strongbox, wrongKey
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("unlock strongbox with key")

        // Then
        await mockIO.expect(
            """
            > unlock strongbox with key
            The copper key and the iron strongbox were never meant to be
            together.
            """
        )
    }

    @Test("Requires light to unlock")
    func testRequiresLight() async throws {
        // Given: Dark room with locked item
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")
            // Note: No .inherentlyLit property

        let chest = Item("chest")
            .name("treasure chest")
            .description("A locked treasure chest.")
            .isLockable
            .isLocked
            .lockKey("treasureKey")
            .in("darkRoom")

        let key = Item("treasureKey")
            .name("treasure key")
            .description("A key to the treasure chest.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: chest, key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("unlock chest with key")

        // Then
        await mockIO.expect(
            """
            > unlock chest with key
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Unlock lockable item with correct key")
    func testUnlockWithCorrectKey() async throws {
        // Given
        let lockbox = Item("lockbox")
            .name("steel lockbox")
            .description("A secure steel lockbox.")
            .isLockable
            .isLocked
            .lockKey("steelKey")
            .in(.startRoom)

        let key = Item("steelKey")
            .name("steel key")
            .description("A steel key.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: lockbox, key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("unlock lockbox with key")

        // Then: Verify state changes
        let finalLockbox = await engine.item("lockbox")
        let finalKey = await engine.item("steelKey")

        #expect(await finalLockbox.hasFlag(.isLocked) == false)
        #expect(await finalLockbox.hasFlag(.isTouched) == true)
        #expect(await finalKey.hasFlag(.isTouched) == true)

        // Verify message
        await mockIO.expect(
            """
            > unlock lockbox with key
            The steel lockbox is now unlocked.
            """
        )
    }

    @Test("Unlock multiple different items")
    func testUnlockMultipleItems() async throws {
        // Given
        let door = Item("door")
            .name("wooden door")
            .description("A wooden door.")
            .isLockable
            .isLocked
            .lockKey("doorKey")
            .in(.startRoom)

        let chest = Item("chest")
            .name("small chest")
            .description("A small chest.")
            .isLockable
            .isLocked
            .lockKey("chestKey")
            .in(.startRoom)

        let doorKey = Item("doorKey")
            .name("door key")
            .description("A key for the door.")
            .isTakable
            .in(.player)

        let chestKey = Item("chestKey")
            .name("chest key")
            .description("A key for the chest.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: door, chest, doorKey, chestKey
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Unlock first item
        try await engine.execute("unlock door with door key")

        // Then
        await mockIO.expect(
            """
            > unlock door with door key
            The wooden door is now unlocked.
            """
        )

        // When: Unlock second item
        try await engine.execute("unlock chest with chest key")

        // Then
        await mockIO.expect(
            """
            > unlock chest with chest key
            The small chest is now unlocked.
            """
        )

        // Verify both items are unlocked
        let finalDoor = await engine.item("door")
        let finalChest = await engine.item("chest")
        #expect(await finalDoor.hasFlag(.isLocked) == false)
        #expect(await finalChest.hasFlag(.isLocked) == false)
    }

    @Test("Unlock preserves other item properties")
    func testUnlockPreservesOtherProperties() async throws {
        // Given
        let container = Item("container")
            .name("magic container")
            .description("A magical container.")
            .isContainer
            .isLockable
            .isLocked
            .isOpenable
            .lockKey("magicKey")
            .in(.startRoom)

        let key = Item("magicKey")
            .name("magic key")
            .description("A glowing magic key.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: container, key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("unlock container with key")

        // Then: Verify unlocking preserves other properties
        let finalContainer = await engine.item("container")

        #expect(await finalContainer.hasFlag(.isLocked) == false)
        #expect(await finalContainer.isContainer == true)
        #expect(await finalContainer.hasFlag(.isLockable) == true)
        #expect(await finalContainer.isOpenable == true)

        await mockIO.expect(
            """
            > unlock container with key
            The magic container is now unlocked.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = UnlockActionHandler()
        #expect(handler.synonyms.contains(.unlock))
        #expect(handler.synonyms.count == 1)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = UnlockActionHandler()
        #expect(handler.requiresLight == true)
    }
}
