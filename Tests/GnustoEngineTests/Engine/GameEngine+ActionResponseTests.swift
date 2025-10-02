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

        await mockIO.expectOutput(
            """
            > go xyzzy
            Which direction?
            """
        )
    }

    @Test("ActionResponse: directionIsBlocked")
    func testDirectionIsBlocked() async throws {
        let testRoom = Location(.startRoom)
            .name("Test Room")
            .north("The path is blocked by fallen rocks.")
            .inherentlyLit

        let game = MinimalGame(locations: testRoom)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("go north")

        await mockIO.expectOutput(
            """
            > go north
            The path is blocked by fallen rocks.
            """
        )
    }

    // MARK: - Item Taking Error Tests

    @Test("ActionResponse: itemNotTakable")
    func testItemNotTakable() async throws {
        let pebble = Item("pebble")
            .name("pebble")
            .in(.startRoom)
            // No .isTakable flag

        let game = MinimalGame(items: pebble)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("take pebble")

        await mockIO.expectOutput(
            """
            > take pebble
            The pebble stubbornly resists your attempts to take it.
            """
        )
    }

    @Test("ActionResponse: itemNotHeld")
    func testItemNotHeld() async throws {
        let pebble = Item("pebble")
            .name("pebble")
            .in(.startRoom)

        let game = MinimalGame(items: pebble)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wear pebble")

        await mockIO.expectOutput(
            """
            > wear pebble
            You aren't holding the pebble.
            """
        )
    }

    @Test("ActionResponse: playerCannotCarryMore")
    func testPlayerCannotCarryMore() async throws {
        let heavyItem = Item("sword")
            .name("heavy sword")
            .in(.player)
            .isTakable
            .size(20)

        let shield = Item("shield")
            .name("large shield")
            .in(.startRoom)
            .isTakable
            .size(42)

        let player = Player(in: .startRoom, characterSheet: .weak)

        let game = MinimalGame(
            player: player,
            items: heavyItem, shield
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("take shield")

        await mockIO.expectOutput(
            """
            > take shield
            Your burden has reached its practical limit.
            """
        )
    }

    @Test("ActionResponse: itemNotDroppable")
    func testItemNotDroppable() async throws {
        let ankleBracelet = Item("ankleBracelet")
            .name("ankle bracelet")
            .in(.player)
            .omitDescription
            // No .isTakable flag makes it not droppable

        let game = MinimalGame(
            items: ankleBracelet
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("drop my ankle bracelet")

        await mockIO.expectOutput(
            """
            > drop my ankle bracelet
            The ankle bracelet stubbornly resists your attempts to drop it.
            """
        )
    }

    // MARK: - Container Error Tests

    @Test("ActionResponse: containerIsClosed")
    func testContainerIsClosed() async throws {
        let key = Item("key")
            .name("key")
            .in(.player)
            .isTakable

        let box = Item("box")
            .name("box")
            .in(.startRoom)
            .isContainer
            .isOpenable
            // No .isOpen flag - defaults to closed

        let game = MinimalGame(
            items: key, box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("put key in box")

        await mockIO.expectOutput(
            """
            > put key in box
            The box is closed.
            """
        )
    }

    @Test("ActionResponse: targetIsNotAContainer")
    func testTargetIsNotAContainer() async throws {
        let key = Item("key")
            .name("key")
            .in(.player)
            .isTakable

        let rock = Item("rock")
            .name("rock")
            .in(.startRoom)

        let game = MinimalGame(
            items: key, rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("put key in rock")

        await mockIO.expectOutput(
            """
            > put key in rock
            You can't put things in the rock.
            """
        )
    }

    @Test("ActionResponse: targetIsNotASurface")
    func testTargetIsNotASurface() async throws {
        let key = Item("key")
            .name("key")
            .in(.player)
            .isTakable

        let rock = Item("rock")
            .name("rock")
            .in(.startRoom)

        let game = MinimalGame(
            items: key, rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("put key on rock")

        await mockIO.expectOutput(
            """
            > put key on rock
            You can't put things on the rock.
            """
        )
    }

    // MARK: - Opening/Closing Error Tests

    @Test("ActionResponse: itemNotOpenable")
    func testItemNotOpenable() async throws {
        let rock = Item("rock")
            .name("rock")
            .in(.startRoom)

        let game = MinimalGame(
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("open rock")

        await mockIO.expectOutput(
            """
            > open rock
            The rock stubbornly resists your attempts to open it.
            """
        )
    }

    @Test("ActionResponse: itemNotClosable")
    func testItemNotClosable() async throws {
        let book = Item("book")
            .name("book")
            .in(.startRoom)

        let game = MinimalGame(
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("close book")

        await mockIO.expectOutput(
            """
            > close book
            The book stubbornly resists your attempts to close it.
            """
        )
    }

    @Test("ActionResponse: itemAlreadyClosed")
    func testItemAlreadyClosed() async throws {
        let box = Item("box")
            .name("box")
            .in(.startRoom)
            .isContainer
            .isOpenable
            // No .isOpen flag - defaults to closed

        let game = MinimalGame(
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("close box")

        await mockIO.expectOutput(
            """
            > close box
            The box is already closed.
            """
        )
    }

    // MARK: - Wearable Error Tests

    @Test("ActionResponse: itemNotWearable")
    func testItemNotWearable() async throws {
        let rock = Item("rock")
            .name("rock")
            .in(.player)
            .isTakable

        let game = MinimalGame(
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wear rock")

        await mockIO.expectOutput(
            """
            > wear rock
            The rock stubbornly resists your attempts to wear it.
            """
        )
    }

    @Test("ActionResponse: itemNotRemovable")
    func testItemNotRemovable() async throws {
        let amulet = Item("amulet")
            .name("cursed amulet")
            .in(.player)
            .isWearable
            .isWorn
            .omitDescription
            // No .isTakable flag makes it not removable

        let game = MinimalGame(
            items: amulet
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("remove amulet")

        await mockIO.expectOutput(
            """
            > remove amulet
            The cursed amulet stubbornly resists your attempts to remove
            it.
            """
        )
    }

    // MARK: - Locking/Unlocking Error Tests

    @Test("ActionResponse: itemIsUnlocked")
    func testItemIsUnlocked() async throws {
        let chest = Item("chest")
            .name("chest")
            .in(.startRoom)
            .isContainer
            .isLockable
            .lockKey("key1")
            // No .isLocked flag - defaults to unlocked

        let key = Item("key1")
            .name("key")
            .in(.player)
            .isTakable

        let game = MinimalGame(
            items: chest, key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("unlock chest with key")

        await mockIO.expectOutput(
            """
            > unlock chest with key
            The chest is already unlocked.
            """
        )
    }

    @Test("ActionResponse: wrongKey")
    func testWrongKey() async throws {
        let chest = Item("chest")
            .name("chest")
            .in(.startRoom)
            .isContainer
            .isLockable
            .isLocked
            .lockKey("key1")

        let wrongKey = Item("key2")
            .name("wrong key")
            .in(.player)
            .isTakable

        let game = MinimalGame(
            items: chest, wrongKey
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("unlock chest with wrong key")

        await mockIO.expectOutput(
            """
            > unlock chest with wrong key
            The wrong key and the chest were never meant to be together.
            """
        )
    }

    // MARK: - Darkness Error Tests

    @Test("ActionResponse: roomIsDark")
    func testRoomIsDark() async throws {
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A dark, dark room.")
            // No .inherentlyLit flag - defaults to dark

        let shadow = Item("shadow")
            .name("shadow")
            .in("darkRoom")

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: shadow
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("examine shadow")

        await mockIO.expectOutput(
            """
            > examine shadow
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Prerequisite Error Tests

    @Test("ActionResponse: prerequisiteNotMet")
    func testPrerequisiteNotMet() async throws {
        let testRoom = Location(.startRoom)
            .name("Test Room")
            .up("You need something to climb on.")
            .inherentlyLit

        let game = MinimalGame(locations: testRoom)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("go up")

        await mockIO.expectOutput(
            """
            > go up
            You need something to climb on.
            """
        )
    }

    // MARK: - Item State Error Tests

    @Test("ActionResponse: itemAlreadyOpen")
    func testItemAlreadyOpen() async throws {
        let box = Item("box")
            .name("box")
            .in(.startRoom)
            .isContainer
            .isOpenable
            .isOpen

        let game = MinimalGame(
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("open box")

        await mockIO.expectOutput(
            """
            > open box
            The box is already open.
            """
        )
    }

    @Test("ActionResponse: itemIsLocked")
    func testItemIsLocked() async throws {
        let chest = Item("chest")
            .name("chest")
            .in(.startRoom)
            .isContainer
            .isOpenable
            .isLockable
            .isLocked
            .lockKey("key1")

        let game = MinimalGame(
            items: chest
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("open chest")

        await mockIO.expectOutput(
            """
            > open chest
            The chest is locked.
            """
        )
    }

    @Test("ActionResponse: itemAlreadyLocked")
    func testItemAlreadyLocked() async throws {
        let chest = Item("chest")
            .name("chest")
            .in(.startRoom)
            .isContainer
            .isLockable
            .isLocked
            .lockKey("key1")

        let key = Item("key1")
            .name("key")
            .in(.player)
            .isTakable

        let game = MinimalGame(
            items: chest, key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("lock chest with key")

        await mockIO.expectOutput(
            """
            > lock chest with key
            The chest is already locked.
            """
        )
    }

    // MARK: - Device Error Tests

    @Test("ActionResponse: itemAlreadyOn")
    func testItemAlreadyOn() async throws {
        let lamp = Item("lamp")
            .name("lamp")
            .in(.player)
            .isLightSource
            .isDevice
            .isOn
            .isTakable

        let game = MinimalGame(
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("turn on lamp")

        await mockIO.expectOutput(
            """
            > turn on lamp
            It's already on.
            """
        )
    }

    @Test("ActionResponse: itemAlreadyOff")
    func testItemAlreadyOff() async throws {
        let lamp = Item("lamp")
            .name("lamp")
            .in(.player)
            .isLightSource
            .isDevice
            .isTakable
            // No .isOn flag - defaults to off

        let game = MinimalGame(
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("turn off lamp")

        await mockIO.expectOutput(
            """
            > turn off lamp
            It's already off.
            """
        )
    }

    @Test("ActionResponse: itemNotADevice")
    func testItemNotADevice() async throws {
        let rock = Item("rock")
            .name("rock")
            .in(.startRoom)

        let game = MinimalGame(
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("turn on rock")

        await mockIO.expectOutput(
            """
            > turn on rock
            It remains stubbornly inert despite your ministrations.
            """
        )
    }

    // MARK: - Item Not In Scope Tests

    @Test("ActionResponse: itemNotInScope")
    func testItemNotInScope() async throws {
        let otherRoom = Location("otherRoom")
            .name("Other Room")
            .inherentlyLit

        let distantItem = Item("distantItem")
            .name("distant item")
            .in("otherRoom")
            .isTakable

        let game = MinimalGame(
            locations: otherRoom,
            items: distantItem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("take distant item")

        await mockIO.expectOutput(
            """
            > take distant item
            Any such thing lurks beyond your reach.
            """
        )
    }

    // MARK: - Object Requirement Error Tests

    @Test("ActionResponse: directObjectRequired")
    func testDirectObjectRequired() async throws {
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("take")

        await mockIO.expectOutput(
            """
            > take
            Take what?
            """
        )
    }

    @Test("ActionResponse: indirectObjectRequired")
    func testIndirectObjectRequired() async throws {
        let key = Item("key")
            .name("key")
            .in(.player)
            .isTakable

        let game = MinimalGame(
            items: key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("unlock key")

        await mockIO.expectOutput(
            """
            > unlock key
            That's not something you can unlock.
            """
        )
    }

    // MARK: - Eating Error Tests

    @Test("ActionResponse: itemNotEdible")
    func testItemNotEdible() async throws {
        let rock = Item("rock")
            .name("rock")
            .in(.player)
            .isTakable

        let game = MinimalGame(
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("eat rock")

        await mockIO.expectOutput(
            """
            > eat rock
            The rock falls well outside the realm of culinary possibility.
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

        await mockIO.expectOutput(
            """
            > teleport
            The art of teleport-ing remains a mystery to me.
            """
        )
    }

    // MARK: - Complex Container Error Tests

    @Test("ActionResponse: containerIsNotEmpty")
    func testContainerIsNotEmpty() async throws {
        let gem = Item("gem")
            .name("gem")
            .in(.item("box"))
            .isTakable

        let box = Item("box")
            .name("box")
            .in(.startRoom)
            .isContainer
            .isOpenable
            .isOpen

        let game = MinimalGame(
            items: gem, box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("close box")

        await mockIO.expectOutput(
            """
            > close box
            Firmly closed.
            """
        )
    }

    // MARK: - Error Message Formatting Tests

    @Test("ActionResponse: error messages include item names correctly")
    func testErrorMessagesIncludeItemNames() async throws {
        let fancyBox = Item("fancyBox")
            .name("ornate jewelry box")
            .in(.startRoom)
            .isContainer
            .isOpenable
            // No .isOpen - defaults to closed

        let key = Item("key")
            .name("tiny key")
            .in(.player)
            .isTakable

        let game = MinimalGame(
            items: fancyBox, key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("put tiny key in ornate jewelry box")

        await mockIO.expectOutput(
            """
            > put tiny key in ornate jewelry box
            The ornate jewelry box is closed.
            """
        )
    }

    // MARK: - Multiple Error Conditions Tests

    @Test("ActionResponse: multiple error conditions prioritization")
    func testMultipleErrorConditionsPrioritization() async throws {
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")
            // No .inherentlyLit - defaults to dark

        let lockedChest = Item("chest")
            .name("locked chest")
            .in("darkRoom")
            .isContainer
            .isLockable
            .isLocked
            .lockKey("key1")

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: lockedChest
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Try to examine something in a dark room - darkness should take precedence
        try await engine.execute("examine chest")

        await mockIO.expectOutput(
            """
            > examine chest
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }
}
