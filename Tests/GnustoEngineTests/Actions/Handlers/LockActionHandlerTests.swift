import CustomDump
import Testing

@testable import GnustoEngine

@Suite("LockActionHandler Tests")
struct LockActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("LOCK DIRECTOBJECT syntax works")
    func testLockDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let door = Item(
            id: "door",
            .name("wooden door"),
            .description("A wooden door."),
            .isDoor,
            .isLockable,
            .lockKey("key"),
            .in(.location("testRoom"))
        )

        let key = Item(
            id: "key",
            .name("brass key"),
            .description("A brass key."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            """)
    }

    @Test("LOCK DIRECTOBJECT WITH INDIRECTOBJECT syntax works")
    func testLockDirectObjectWithIndirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let chest = Item(
            id: "chest",
            .name("treasure chest"),
            .description("A treasure chest."),
            .isContainer,
            .isLockable,
            .lockKey("key"),
            .in(.location("testRoom"))
        )

        let key = Item(
            id: "key",
            .name("golden key"),
            .description("A golden key."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            """)

        let finalChestState = try await engine.item("chest")
        let finalKeyState = try await engine.item("key")
        #expect(finalChestState.hasFlag(.isLocked))
        #expect(finalChestState.hasFlag(.isTouched))
        #expect(finalKeyState.hasFlag(.isTouched))
    }

    // MARK: - Validation Testing

    @Test("Cannot lock without specifying what")
    func testCannotLockWithoutSpecifyingWhat() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

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
            """)
    }

    @Test("Cannot lock without specifying key")
    func testCannotLockWithoutSpecifyingKey() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let door = Item(
            id: "door",
            .name("iron door"),
            .description("An iron door."),
            .isDoor,
            .isLockable,
            .lockKey("key"),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            """)
    }

    @Test("Cannot lock with key not held")
    func testCannotLockWithKeyNotHeld() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let door = Item(
            id: "door",
            .name("oak door"),
            .description("An oak door."),
            .isDoor,
            .isLockable,
            .lockKey("key"),
            .in(.location("testRoom"))
        )

        let key = Item(
            id: "key",
            .name("silver key"),
            .description("A silver key."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You aren’t holding the silver key.
            """)
    }

    @Test("Cannot lock target not in scope")
    func testCannotLockTargetNotInScope() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteDoor = Item(
            id: "remoteDoor",
            .name("distant door"),
            .description("A door in another room."),
            .isDoor,
            .isLockable,
            .lockKey("key"),
            .in(.location("anotherRoom"))
        )

        let key = Item(
            id: "key",
            .name("brass key"),
            .description("A brass key."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
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
            You can’t see any such thing.
            """)
    }

    @Test("Cannot lock non-lockable item")
    func testCannotLockNonLockableItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A large boulder."),
            .in(.location("testRoom"))
        )

        let key = Item(
            id: "key",
            .name("brass key"),
            .description("A brass key."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You can’t lock the large rock.
            """)
    }

    @Test("Cannot lock with wrong key")
    func testCannotLockWithWrongKey() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let door = Item(
            id: "door",
            .name("secure door"),
            .description("A secure door."),
            .isDoor,
            .isLockable,
            .lockKey("correctKey"),
            .in(.location("testRoom"))
        )

        let wrongKey = Item(
            id: "wrongKey",
            .name("wrong key"),
            .description("A key that doesn’t fit."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            The wrong key doesn’t fit the secure door.
            """)
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
            .isDoor,
            .isLockable,
            .lockKey("key"),
            .in(.location("darkRoom"))
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
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Lock item successfully")
    func testLockItemSuccessfully() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let safe = Item(
            id: "safe",
            .name("metal safe"),
            .description("A metal safe."),
            .isContainer,
            .isLockable,
            .lockKey("combination"),
            .in(.location("testRoom"))
        )

        let combination = Item(
            id: "combination",
            .name("combination code"),
            .description("A piece of paper with the combination."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: safe, combination
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("lock safe with combination")

        // Then: Verify state changes
        let finalSafeState = try await engine.item("safe")
        let finalCombinationState = try await engine.item("combination")
        #expect(finalSafeState.hasFlag(.isLocked))
        #expect(finalSafeState.hasFlag(.isTouched))
        #expect(finalCombinationState.hasFlag(.isTouched))

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > lock safe with combination
            The metal safe is now locked.
            """)
    }

    @Test("Lock already locked item gives appropriate message")
    func testLockAlreadyLockedItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let door = Item(
            id: "door",
            .name("locked door"),
            .description("A locked door."),
            .isDoor,
            .isLockable,
            .isLocked,
            .lockKey("key"),
            .in(.location("testRoom"))
        )

        let key = Item(
            id: "key",
            .name("brass key"),
            .description("A brass key."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            """)

        // Item should remain locked but not touched again
        let finalDoorState = try await engine.item("door")
        #expect(finalDoorState.hasFlag(.isLocked))
    }

    @Test("Lock sets touched flag on both items")
    func testLockSetsTouchedFlagOnBothItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("jewelry box"),
            .description("A jewelry box."),
            .isContainer,
            .isLockable,
            .lockKey("tinyKey"),
            .in(.location("testRoom"))
        )

        let tinyKey = Item(
            id: "tinyKey",
            .name("tiny key"),
            .description("A tiny key."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box, tinyKey
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("lock box with key")

        // Then: Verify state changes
        let finalBoxState = try await engine.item("box")
        let finalKeyState = try await engine.item("tinyKey")
        #expect(finalBoxState.hasFlag(.isLocked))
        #expect(finalBoxState.hasFlag(.isTouched))
        #expect(finalKeyState.hasFlag(.isTouched))

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > lock box with key
            The jewelry box is now locked.
            """)
    }

    @Test("Lock multiple different items")
    func testLockMultipleDifferentItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let door = Item(
            id: "door",
            .name("front door"),
            .description("The front door."),
            .isDoor,
            .isLockable,
            .lockKey("doorKey"),
            .in(.location("testRoom"))
        )

        let chest = Item(
            id: "chest",
            .name("storage chest"),
            .description("A storage chest."),
            .isContainer,
            .isLockable,
            .lockKey("chestKey"),
            .in(.location("testRoom"))
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
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            """)

        // When: Lock chest
        try await engine.execute("lock chest with chest key")

        // Then
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > lock chest with chest key
            The storage chest is now locked.
            """)

        // Verify both items are locked
        let doorState = try await engine.item("door")
        let chestState = try await engine.item("chest")
        #expect(doorState.hasFlag(.isLocked))
        #expect(chestState.hasFlag(.isLocked))
    }

    @Test("Lock item with special key types")
    func testLockItemWithSpecialKeyTypes() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let magicBox = Item(
            id: "magicBox",
            .name("magic box"),
            .description("A magic box."),
            .isContainer,
            .isLockable,
            .lockKey("crystal"),
            .in(.location("testRoom"))
        )

        let crystal = Item(
            id: "crystal",
            .name("magic crystal"),
            .description("A magic crystal that serves as a key."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            """)

        let finalBoxState = try await engine.item("magicBox")
        #expect(finalBoxState.hasFlag(.isLocked))
    }

    @Test("Lock attempts with non-key items fail")
    func testLockAttemptsWithNonKeyItemsFail() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let door = Item(
            id: "door",
            .name("heavy door"),
            .description("A heavy door."),
            .isDoor,
            .isLockable,
            .lockKey("properKey"),
            .in(.location("testRoom"))
        )

        let stick = Item(
            id: "stick",
            .name("wooden stick"),
            .description("A wooden stick."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            The wooden stick doesn’t fit the heavy door.
            """)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = LockActionHandler()
        // LockActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = LockActionHandler()
        #expect(handler.verbs.contains(.lock))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = LockActionHandler()
        #expect(handler.requiresLight == true)
    }
}
