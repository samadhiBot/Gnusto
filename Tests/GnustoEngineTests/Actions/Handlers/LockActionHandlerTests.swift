import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("LockActionHandler Tests")
struct LockActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("LOCK DIRECTOBJECT syntax works")
    func testLockDirectObjectSyntax() async throws {
        // Given
        let door = Item(
            id: "door",
            .name("wooden door"),
            .description("A wooden door."),
            .isLockable,
            .lockKey("key"),
            .in(.startRoom)
        )

        let key = Item(
            id: "key",
            .name("brass key"),
            .description("A brass key."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: door, key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("lock door")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > lock door
            Lock the wooden door with what?
            """
        )
    }

    @Test("LOCK DIRECTOBJECT WITH INDIRECTOBJECT syntax works")
    func testLockDirectObjectWithIndirectObjectSyntax() async throws {
        // Given
        let chest = Item(
            id: "chest",
            .name("treasure chest"),
            .description("A treasure chest."),
            .isContainer,
            .isLockable,
            .lockKey("key"),
            .in(.startRoom)
        )

        let key = Item(
            id: "key",
            .name("golden key"),
            .description("A golden key."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: chest, key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("lock chest with key")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > lock chest with key
            The treasure chest is now locked.
            """
        )

        let finalChestState = await engine.item("chest")
        let finalKeyState = await engine.item("key")
        #expect(await finalChestState.hasFlag(.isLocked))
        #expect(await finalChestState.hasFlag(.isTouched))
        #expect(await finalKeyState.hasFlag(.isTouched))
    }

    // MARK: - Validation Testing

    @Test("Cannot lock without specifying what")
    func testCannotLockWithoutSpecifyingWhat() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("lock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > lock
            Lock what?
            """
        )
    }

    @Test("Cannot lock without specifying key")
    func testCannotLockWithoutSpecifyingKey() async throws {
        // Given
        let door = Item(
            id: "door",
            .name("iron door"),
            .description("An iron door."),
            .isLockable,
            .lockKey("key"),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: door
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("lock door")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > lock door
            Lock the iron door with what?
            """
        )
    }

    @Test("Cannot lock with key not held")
    func testCannotLockWithKeyNotHeld() async throws {
        // Given
        let door = Item(
            id: "door",
            .name("oak door"),
            .description("An oak door."),
            .isLockable,
            .lockKey("key"),
            .in(.startRoom)
        )

        let key = Item(
            id: "key",
            .name("silver key"),
            .description("A silver key."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: door, key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("lock door with key")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > lock door with key
            You aren't holding the silver key.
            """
        )
    }

    @Test("Cannot lock target not in scope")
    func testCannotLockTargetNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteDoor = Item(
            id: "remoteDoor",
            .name("distant door"),
            .description("A door in another room."),
            .isLockable,
            .lockKey("key"),
            .in("anotherRoom")
        )

        let key = Item(
            id: "key",
            .name("brass key"),
            .description("A brass key."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteDoor, key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("lock door with key")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > lock door with key
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot lock non-lockable item")
    func testCannotLockNonLockableItem() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A large boulder."),
            .in(.startRoom)
        )

        let key = Item(
            id: "key",
            .name("brass key"),
            .description("A brass key."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: rock, key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("lock rock with key")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > lock rock with key
            The large rock stubbornly resists your attempts to lock it.
            """
        )
    }

    @Test("Cannot lock with wrong key")
    func testCannotLockWithWrongKey() async throws {
        // Given
        let door = Item(
            id: "door",
            .name("secure door"),
            .description("A secure door."),
            .isLockable,
            .lockKey("correctKey"),
            .in(.startRoom)
        )

        let wrongKey = Item(
            id: "wrongKey",
            .name("wrong key"),
            .description("A key that doesn't fit."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: door, wrongKey
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("lock door with key")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > lock door with key
            The wrong key and the secure door were never meant to be
            together.
            """
        )
    }

    @Test("Requires light to lock")
    func testRequiresLight() async throws {
        // Given: Dark room with lockable item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let door = Item(
            id: "door",
            .name("mysterious door"),
            .description("A mysterious door."),
            .isLockable,
            .lockKey("key"),
            .in("darkRoom")
        )

        let key = Item(
            id: "key",
            .name("glowing key"),
            .description("A glowing key."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: door, key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("lock door with key")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > lock door with key
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Lock item successfully")
    func testLockItemSuccessfully() async throws {
        // Given
        let safe = Item(
            id: "safe",
            .name("metal safe"),
            .description("A metal safe."),
            .isContainer,
            .isLockable,
            .lockKey("combination"),
            .in(.startRoom)
        )

        let combination = Item(
            id: "combination",
            .name("combination code"),
            .description("A piece of paper with the combination."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: safe, combination
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("lock safe with combination")

        // Then: Verify state changes
        let finalSafeState = await engine.item("safe")
        let finalCombinationState = await engine.item("combination")
        #expect(await finalSafeState.hasFlag(.isLocked))
        #expect(await finalSafeState.hasFlag(.isTouched))
        #expect(await finalCombinationState.hasFlag(.isTouched))

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > lock safe with combination
            The metal safe is now locked.
            """
        )
    }

    @Test("Lock already locked item gives appropriate message")
    func testLockAlreadyLockedItem() async throws {
        // Given
        let door = Item(
            id: "door",
            .name("locked door"),
            .description("A locked door."),
            .isLockable,
            .isLocked,
            .lockKey("key"),
            .in(.startRoom)
        )

        let key = Item(
            id: "key",
            .name("brass key"),
            .description("A brass key."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: door, key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("lock door with key")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > lock door with key
            The locked door is already locked.
            """
        )

        // Item should remain locked but not touched again
        let finalDoorState = await engine.item("door")
        #expect(await finalDoorState.hasFlag(.isLocked))
    }

    @Test("Lock sets touched flag on both items")
    func testLockSetsTouchedFlagOnBothItems() async throws {
        // Given
        let box = Item(
            id: "box",
            .name("jewelry box"),
            .description("A jewelry box."),
            .isContainer,
            .isLockable,
            .lockKey("tinyKey"),
            .in(.startRoom)
        )

        let tinyKey = Item(
            id: "tinyKey",
            .name("tiny key"),
            .description("A tiny key."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: box, tinyKey
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("lock box with key")

        // Then: Verify state changes
        let finalBoxState = await engine.item("box")
        let finalKeyState = await engine.item("tinyKey")
        #expect(await finalBoxState.hasFlag(.isLocked))
        #expect(await finalBoxState.hasFlag(.isTouched))
        #expect(await finalKeyState.hasFlag(.isTouched))

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > lock box with key
            The jewelry box is now locked.
            """
        )
    }

    @Test("Lock multiple different items")
    func testLockMultipleDifferentItems() async throws {
        // Given
        let door = Item(
            id: "door",
            .name("front door"),
            .description("The front door."),
            .isLockable,
            .lockKey("doorKey"),
            .in(.startRoom)
        )

        let chest = Item(
            id: "chest",
            .name("storage chest"),
            .description("A storage chest."),
            .isContainer,
            .isLockable,
            .lockKey("chestKey"),
            .in(.startRoom)
        )

        let doorKey = Item(
            id: "doorKey",
            .name("door key"),
            .description("A key for the door."),
            .isTakable,
            .in(.player)
        )

        let chestKey = Item(
            id: "chestKey",
            .name("chest key"),
            .description("A key for the chest."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: door, chest, doorKey, chestKey
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Lock door
        try await engine.execute("lock door with door key")

        // Then
        let output1 = await mockIO.flush()
        expectNoDifference(
            output1,
            """
            > lock door with door key
            The front door is now locked.
            """
        )

        // When: Lock chest
        try await engine.execute("lock chest with chest key")

        // Then
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > lock chest with chest key
            The storage chest is now locked.
            """
        )

        // Verify both items are locked
        let doorState = await engine.item("door")
        let chestState = await engine.item("chest")
        #expect(await doorState.hasFlag(.isLocked))
        #expect(await chestState.hasFlag(.isLocked))
    }

    @Test("Lock item with special key types")
    func testLockItemWithSpecialKeyTypes() async throws {
        // Given
        let magicBox = Item(
            id: "magicBox",
            .name("magic box"),
            .description("A magic box."),
            .isContainer,
            .isLockable,
            .lockKey("crystal"),
            .in(.startRoom)
        )

        let crystal = Item(
            id: "crystal",
            .name("magic crystal"),
            .description("A magic crystal that serves as a key."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: magicBox, crystal
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("lock box with crystal")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > lock box with crystal
            The magic box is now locked.
            """
        )

        let finalBoxState = await engine.item("magicBox")
        #expect(await finalBoxState.hasFlag(.isLocked))
    }

    @Test("Lock attempts with non-key items fail")
    func testLockAttemptsWithNonKeyItemsFail() async throws {
        // Given
        let door = Item(
            id: "door",
            .name("heavy door"),
            .description("A heavy door."),
            .isLockable,
            .lockKey("properKey"),
            .in(.startRoom)
        )

        let stick = Item(
            id: "stick",
            .name("wooden stick"),
            .description("A wooden stick."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: door, stick
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("lock door with stick")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > lock door with stick
            The wooden stick and the heavy door were never meant to be
            together.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = LockActionHandler()
        #expect(handler.synonyms.contains(.lock))
        #expect(handler.synonyms.count == 1)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = LockActionHandler()
        #expect(handler.requiresLight == true)
    }
}
