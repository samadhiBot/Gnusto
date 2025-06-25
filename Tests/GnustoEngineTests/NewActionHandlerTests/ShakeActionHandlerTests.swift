import Testing
import CustomDump
@testable import GnustoEngine

@Suite("ShakeActionHandler Tests")
struct ShakeActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("SHAKE DIRECTOBJECT syntax works")
    func testShakeDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let bottle = Item(
            id: "bottle",
            .name("empty bottle"),
            .description("A glass bottle."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bottle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shake bottle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > shake bottle
            Nothing happens.
            """)

        let finalState = try await engine.item("bottle")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("RATTLE syntax works")
    func testRattleSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A small wooden box."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rattle box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > rattle box
            Nothing happens.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot shake without specifying target")
    func testCannotShakeWithoutTarget() async throws {
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
        try await engine.execute("shake")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > shake
            Shake what?
            """)
    }

    @Test("Cannot shake target not in scope")
    func testCannotShakeTargetNotInScope() async throws {
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

        let remoteItem = Item(
            id: "remoteItem",
            .name("remote item"),
            .description("An item in another room."),
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteItem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shake item")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > shake item
            You can’t see any such thing.
            """)
    }

    @Test("Requires light to shake")
    func testRequiresLight() async throws {
        // Given: Dark room with an object to shake
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let jar = Item(
            id: "jar",
            .name("glass jar"),
            .description("A large glass jar."),
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: jar
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shake jar")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > shake jar
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Shake takable object")
    func testShakeTakableObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A shiny gold coin."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shake coin")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > shake coin
            Nothing happens.
            """)

        let finalState = try await engine.item("coin")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Shake fixed object")
    func testShakeFixedObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let tree = Item(
            id: "tree",
            .name("oak tree"),
            .description("A massive oak tree."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: tree
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shake tree")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > shake tree
            You can’t shake the oak tree.
            """)
    }

    @Test("Shake character")
    func testShakeCharacter() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .description("A wise old wizard with a long beard."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: wizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shake wizard")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > shake wizard
            You don’t need to shake the old wizard.
            """)
    }

    @Test("Shake open container")
    func testShakeOpenContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bag = Item(
            id: "bag",
            .name("leather bag"),
            .description("A worn leather bag."),
            .isContainer,
            .isOpenable,
            .isOpen,
            .in(.location("testRoom"))
        )

        let gem = Item(
            id: "gem",
            .name("red gem"),
            .description("A precious red gem."),
            .in(.item("bag"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bag, gem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shake bag")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > shake bag
            The things in the leather bag rattle.
            """)
    }

    @Test("Shake closed container")
    func testShakeClosedContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let chest = Item(
            id: "chest",
            .name("treasure chest"),
            .description("An ornate treasure chest."),
            .isContainer,
            .isOpenable,
            .in(.location("testRoom"))
        )

        let treasure = Item(
            id: "treasure",
            .name("pile of gold"),
            .description("A pile of golden coins."),
            .in(.item("chest"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: chest, treasure
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shake chest")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > shake chest
            Something rattles around inside the treasure chest.
            """)
    }

    @Test("Shake liquid container")
    func testShakeLiquidContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let flask = Item(
            id: "flask",
            .name("water flask"),
            .description("A metal flask filled with water."),
            .isLiquidContainer,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: flask
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shake flask")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > shake flask
            The water flask sloshes.
            """)
    }

    @Test("Shake held item")
    func testShakeHeldItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let dice = Item(
            id: "dice",
            .name("pair of dice"),
            .description("Two white dice."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: dice
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shake dice")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > shake dice
            Nothing happens.
            """)
    }

    @Test("Shaking sets isTouched flag")
    func testShakingSetsTouchedFlag() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bell = Item(
            id: "bell",
            .name("small bell"),
            .description("A tiny bronze bell."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bell
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Verify initial state
        let initialState = try await engine.item("bell")
        #expect(initialState.hasFlag(.isTouched) == false)

        // When
        try await engine.execute("shake bell")

        // Then
        let finalState = try await engine.item("bell")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Shake multiple objects in sequence")
    func testShakeMultipleObjects() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box1 = Item(
            id: "box1",
            .name("small box"),
            .description("A small wooden box."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let box2 = Item(
            id: "box2",
            .name("large box"),
            .description("A large cardboard box."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box1, box2
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shake small box")
        try await engine.execute("rattle large box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > shake small box
            Nothing happens.
            > rattle large box
            Nothing happens.
            """)

        let box1State = try await engine.item("box1")
        let box2State = try await engine.item("box2")
        #expect(box1State.hasFlag(.isTouched) == true)
        #expect(box2State.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = ShakeActionHandler()
        // ShakeActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = ShakeActionHandler()
        #expect(handler.verbs.contains(.shake))
        #expect(handler.verbs.contains(.rattle))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = ShakeActionHandler()
        #expect(handler.requiresLight == true)
    }
}
