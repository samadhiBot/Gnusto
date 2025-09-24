import CustomDump
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("GameEngine ActionResponse Error Message Tests")
struct GameEngineActionResponseTests {

    // MARK: - Navigation Error Tests

    @Test("ActionResponse: invalidDirection")
    func testInvalidDirection() async throws {
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("go xyzzy")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > go xyzzy
            Which direction?
            """
        )
    }

    @Test("ActionResponse: directionIsBlocked")
    func testDirectionIsBlocked() async throws {
        let testRoom = Location(
            id: .startRoom,
            .name("Test Room"),
            .exits(
                .north(blocked: "The path is blocked by fallen rocks.")
            ),
            .inherentlyLit
        )

        let game = MinimalGame(locations: testRoom)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("go north")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > go north
            The path is blocked by fallen rocks.
            """
        )
    }

    // MARK: - Item Taking Error Tests

    @Test("ActionResponse: itemNotTakable")
    func testItemNotTakable() async throws {
        let pebble = Item(
            id: "pebble",
            .name("pebble"),
            .in(.startRoom)
            // No .isTakable flag
        )

        let game = MinimalGame(items: pebble)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("take pebble")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take pebble
            The universe denies your request to take the pebble.
            """
        )
    }

    @Test("ActionResponse: itemNotHeld")
    func testItemNotHeld() async throws {
        let pebble = Item(
            id: "pebble",
            .name("pebble"),
            .in(.startRoom)
        )

        let game = MinimalGame(items: pebble)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wear pebble")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wear pebble
            You aren't holding the pebble.
            """
        )
    }

    @Test("ActionResponse: playerCannotCarryMore")
    func testPlayerCannotCarryMore() async throws {
        let heavyItem = Item(
            id: "sword",
            .name("heavy sword"),
            .in(.player),
            .isTakable,
            .size(20)
        )

        let shield = Item(
            id: "shield",
            .name("large shield"),
            .in(.startRoom),
            .isTakable,
            .size(42)
        )

        let player = Player(in: .startRoom, characterSheet: .weak)

        let game = MinimalGame(
            player: player,
            items: heavyItem, shield
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("take shield")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take shield
            You're juggling quite enough already.
            """
        )
    }

    @Test("ActionResponse: itemNotDroppable")
    func testItemNotDroppable() async throws {
        let ankleBracelet = Item(
            id: "ankleBracelet",
            .name("ankle bracelet"),
            .in(.player),
            .omitDescription
            // No .isTakable flag makes it not droppable
        )

        let game = MinimalGame(
            items: ankleBracelet
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("drop my ankle bracelet")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > drop my ankle bracelet
            The universe denies your request to drop the ankle bracelet.
            """
        )
    }

    // MARK: - Container Error Tests

    @Test("ActionResponse: containerIsClosed")
    func testContainerIsClosed() async throws {
        let key = Item(
            id: "key",
            .name("key"),
            .in(.player),
            .isTakable
        )

        let box = Item(
            id: "box",
            .name("box"),
            .in(.startRoom),
            .isContainer,
            .isOpenable
            // No .isOpen flag - defaults to closed
        )

        let game = MinimalGame(
            items: key, box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("put key in box")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put key in box
            The box is closed.
            """
        )
    }

    @Test("ActionResponse: targetIsNotAContainer")
    func testTargetIsNotAContainer() async throws {
        let key = Item(
            id: "key",
            .name("key"),
            .in(.player),
            .isTakable
        )

        let rock = Item(
            id: "rock",
            .name("rock"),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: key, rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("put key in rock")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put key in rock
            You can't put things in the rock.
            """
        )
    }

    @Test("ActionResponse: targetIsNotASurface")
    func testTargetIsNotASurface() async throws {
        let key = Item(
            id: "key",
            .name("key"),
            .in(.player),
            .isTakable
        )

        let rock = Item(
            id: "rock",
            .name("rock"),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: key, rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("put key on rock")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put key on rock
            You can't put things on the rock.
            """
        )
    }

    // MARK: - Opening/Closing Error Tests

    @Test("ActionResponse: itemNotOpenable")
    func testItemNotOpenable() async throws {
        let rock = Item(
            id: "rock",
            .name("rock"),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("open rock")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > open rock
            The universe denies your request to open the rock.
            """
        )
    }

    @Test("ActionResponse: itemNotClosable")
    func testItemNotClosable() async throws {
        let book = Item(
            id: "book",
            .name("book"),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("close book")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > close book
            The universe denies your request to close the book.
            """
        )
    }

    @Test("ActionResponse: itemAlreadyClosed")
    func testItemAlreadyClosed() async throws {
        let box = Item(
            id: "box",
            .name("box"),
            .in(.startRoom),
            .isContainer,
            .isOpenable
            // No .isOpen flag - defaults to closed
        )

        let game = MinimalGame(
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("close box")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > close box
            The box is already closed.
            """
        )
    }

    // MARK: - Wearable Error Tests

    @Test("ActionResponse: itemNotWearable")
    func testItemNotWearable() async throws {
        let rock = Item(
            id: "rock",
            .name("rock"),
            .in(.player),
            .isTakable
        )

        let game = MinimalGame(
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wear rock")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wear rock
            The universe denies your request to wear the rock.
            """
        )
    }

    @Test("ActionResponse: itemNotRemovable")
    func testItemNotRemovable() async throws {
        let amulet = Item(
            id: "amulet",
            .name("cursed amulet"),
            .in(.player),
            .isWearable,
            .isWorn,
            .omitDescription
            // No .isTakable flag makes it not removable
        )

        let game = MinimalGame(
            items: amulet
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("remove amulet")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > remove amulet
            The universe denies your request to remove the cursed amulet.
            """
        )
    }

    // MARK: - Locking/Unlocking Error Tests

    @Test("ActionResponse: itemIsUnlocked")
    func testItemIsUnlocked() async throws {
        let chest = Item(
            id: "chest",
            .name("chest"),
            .in(.startRoom),
            .isContainer,
            .isLockable,
            .lockKey("key1")
            // No .isLocked flag - defaults to unlocked
        )

        let key = Item(
            id: "key1",
            .name("key"),
            .in(.player),
            .isTakable
        )

        let game = MinimalGame(
            items: chest, key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("unlock chest with key")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > unlock chest with key
            The chest is already unlocked.
            """
        )
    }

    @Test("ActionResponse: wrongKey")
    func testWrongKey() async throws {
        let chest = Item(
            id: "chest",
            .name("chest"),
            .in(.startRoom),
            .isContainer,
            .isLockable,
            .isLocked,
            .lockKey("key1")
        )

        let wrongKey = Item(
            id: "key2",
            .name("wrong key"),
            .in(.player),
            .isTakable
        )

        let game = MinimalGame(
            items: chest, wrongKey
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("unlock chest with wrong key")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > unlock chest with wrong key
            The teeth of the wrong key find no purchase in the chest's
            mechanism.
            """
        )
    }

    // MARK: - Darkness Error Tests

    @Test("ActionResponse: roomIsDark")
    func testRoomIsDark() async throws {
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A dark, dark room.")
            // No .inherentlyLit flag - defaults to dark
        )

        let shadow = Item(
            id: "shadow",
            .name("shadow"),
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: shadow
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("examine shadow")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine shadow
            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.
            """
        )
    }

    // MARK: - Prerequisite Error Tests

    @Test("ActionResponse: prerequisiteNotMet")
    func testPrerequisiteNotMet() async throws {
        let testRoom = Location(
            id: .startRoom,
            .name("Test Room"),
            .exits(
                .up(blocked: "You need something to climb on.")
            ),
            .inherentlyLit
        )

        let game = MinimalGame(locations: testRoom)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("go up")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > go up
            You need something to climb on.
            """
        )
    }

    // MARK: - Item State Error Tests

    @Test("ActionResponse: itemAlreadyOpen")
    func testItemAlreadyOpen() async throws {
        let box = Item(
            id: "box",
            .name("box"),
            .in(.startRoom),
            .isContainer,
            .isOpenable,
            .isOpen
        )

        let game = MinimalGame(
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("open box")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > open box
            The box is already open.
            """
        )
    }

    @Test("ActionResponse: itemIsLocked")
    func testItemIsLocked() async throws {
        let chest = Item(
            id: "chest",
            .name("chest"),
            .in(.startRoom),
            .isContainer,
            .isOpenable,
            .isLockable,
            .isLocked,
            .lockKey("key1")
        )

        let game = MinimalGame(
            items: chest
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("open chest")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > open chest
            The chest is locked.
            """
        )
    }

    @Test("ActionResponse: itemAlreadyLocked")
    func testItemAlreadyLocked() async throws {
        let chest = Item(
            id: "chest",
            .name("chest"),
            .in(.startRoom),
            .isContainer,
            .isLockable,
            .isLocked,
            .lockKey("key1")
        )

        let key = Item(
            id: "key1",
            .name("key"),
            .in(.player),
            .isTakable
        )

        let game = MinimalGame(
            items: chest, key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("lock chest with key")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > lock chest with key
            The chest is already locked.
            """
        )
    }

    // MARK: - Device Error Tests

    @Test("ActionResponse: itemAlreadyOn")
    func testItemAlreadyOn() async throws {
        let lamp = Item(
            id: "lamp",
            .name("lamp"),
            .in(.player),
            .isLightSource,
            .isDevice,
            .isOn,
            .isTakable
        )

        let game = MinimalGame(
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("turn on lamp")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn on lamp
            It hums with life already.
            """
        )
    }

    @Test("ActionResponse: itemAlreadyOff")
    func testItemAlreadyOff() async throws {
        let lamp = Item(
            id: "lamp",
            .name("lamp"),
            .in(.player),
            .isLightSource,
            .isDevice,
            .isTakable
            // No .isOn flag - defaults to off
        )

        let game = MinimalGame(
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("turn off lamp")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off lamp
            It rests in darkness already.
            """
        )
    }

    @Test("ActionResponse: itemNotADevice")
    func testItemNotADevice() async throws {
        let rock = Item(
            id: "rock",
            .name("rock"),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("turn on rock")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn on rock
            That lacks the spark of mechanical life you seek to kindle.
            """
        )
    }

    // MARK: - Item Not In Scope Tests

    @Test("ActionResponse: itemNotInScope")
    func testItemNotInScope() async throws {
        let otherRoom = Location(
            id: "otherRoom",
            .name("Other Room"),
            .inherentlyLit
        )

        let distantItem = Item(
            id: "distantItem",
            .name("distant item"),
            .in("otherRoom"),
            .isTakable
        )

        let game = MinimalGame(
            locations: otherRoom,
            items: distantItem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("take distant item")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take distant item
            Any such thing remains frustratingly inaccessible.
            """
        )
    }

    // MARK: - Object Requirement Error Tests

    @Test("ActionResponse: directObjectRequired")
    func testDirectObjectRequired() async throws {
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("take")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take
            Take what?
            """
        )
    }

    @Test("ActionResponse: indirectObjectRequired")
    func testIndirectObjectRequired() async throws {
        let key = Item(
            id: "key",
            .name("key"),
            .in(.player),
            .isTakable
        )

        let game = MinimalGame(
            items: key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("unlock key")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > unlock key
            That's not something you can unlock.
            """
        )
    }

    // MARK: - Eating Error Tests

    @Test("ActionResponse: itemNotEdible")
    func testItemNotEdible() async throws {
        let rock = Item(
            id: "rock",
            .name("rock"),
            .in(.player),
            .isTakable
        )

        let game = MinimalGame(
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("eat rock")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > eat rock
            Your digestive system firmly vetoes the consumption of the
            rock.
            """
        )
    }

    // MARK: - Action Not Implemented Tests

    @Test("ActionResponse: actionNotImplemented")
    func testActionNotImplemented() async throws {
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Use a verb that likely doesn't have a handler
        try await engine.execute("teleport")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > teleport
            I lack the knowledge necessary to teleport anything.
            """
        )
    }

    // MARK: - Complex Container Error Tests

    @Test("ActionResponse: containerIsNotEmpty")
    func testContainerIsNotEmpty() async throws {
        let gem = Item(
            id: "gem",
            .name("gem"),
            .in(.item("box")),
            .isTakable
        )

        let box = Item(
            id: "box",
            .name("box"),
            .in(.startRoom),
            .isContainer,
            .isOpenable,
            .isOpen
        )

        let game = MinimalGame(
            items: gem, box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("close box")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > close box
            Shut tight.
            """
        )
    }

    // MARK: - Error Message Formatting Tests

    @Test("ActionResponse: error messages include item names correctly")
    func testErrorMessagesIncludeItemNames() async throws {
        let fancyBox = Item(
            id: "fancyBox",
            .name("ornate jewelry box"),
            .in(.startRoom),
            .isContainer,
            .isOpenable
            // No .isOpen - defaults to closed
        )

        let key = Item(
            id: "key",
            .name("tiny key"),
            .in(.player),
            .isTakable
        )

        let game = MinimalGame(
            items: fancyBox, key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("put tiny key in ornate jewelry box")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put tiny key in ornate jewelry box
            The ornate jewelry box is closed.
            """
        )
    }

    // MARK: - Multiple Error Conditions Tests

    @Test("ActionResponse: multiple error conditions prioritization")
    func testMultipleErrorConditionsPrioritization() async throws {
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // No .inherentlyLit - defaults to dark
        )

        let lockedChest = Item(
            id: "chest",
            .name("locked chest"),
            .in("darkRoom"),
            .isContainer,
            .isLockable,
            .isLocked,
            .lockKey("key1")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: lockedChest
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Try to examine something in a dark room - darkness should take precedence
        try await engine.execute("examine chest")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine chest
            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.
            """
        )
    }
}
