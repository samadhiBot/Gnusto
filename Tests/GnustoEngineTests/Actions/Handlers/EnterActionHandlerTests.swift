import CustomDump
import Testing

@testable import GnustoEngine

@Suite("EnterActionHandler Tests")
struct EnterActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("ENTER DIRECTOBJECT syntax works")
    func testEnterDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let cabin = Item(
            id: "cabin",
            .name("wooden cabin"),
            .description("A cozy wooden cabin."),
            .isEnterable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: cabin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("enter cabin")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > enter cabin
            Enter what?
            """)

        let finalState = try await engine.item("cabin")
        #expect(finalState.hasFlag(.isTouched))
    }

    // MARK: - Validation Testing

    @Test("Cannot enter without specifying target when no default available")
    func testCannotEnterWithoutTargetNoDefault() async throws {
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
        try await engine.execute("enter")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > enter
            There’s nothing here to enter.
            """)
    }

    @Test("Cannot enter target not in scope")
    func testCannotEnterTargetNotInScope() async throws {
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

        let remoteCabin = Item(
            id: "remoteCabin",
            .name("remote cabin"),
            .description("A cabin in another room."),
            .isEnterable,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteCabin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("enter cabin")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > enter cabin
            You can’t see any such thing.
            """)
    }

    @Test("Cannot enter non-enterable item")
    func testCannotEnterNonEnterableItem() async throws {
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

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("enter rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > enter rock
            You can’t enter the large rock.
            """)
    }

    @Test("Requires light to enter")
    func testRequiresLight() async throws {
        // Given: Dark room with enterable item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let tent = Item(
            id: "tent",
            .name("camping tent"),
            .description("A camping tent."),
            .isEnterable,
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: tent
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("enter tent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > enter tent
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Enter item that enables movement")
    func testEnterItemThatEnablesMovement() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit,
            .exits([.east: Exit(destination: "insideCabin", doorID: "door")])
        )

        let insideCabin = Location(
            id: "insideCabin",
            .name("Inside Cabin"),
            .description("You are inside a cozy cabin."),
            .inherentlyLit,
            .exits([.west: Exit(destination: "testRoom", doorID: "door")])
        )

        let door = Item(
            id: "door",
            .name("wooden door"),
            .description("A wooden door leading into the cabin."),
            .isEnterable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, insideCabin,
            items: door
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("enter door")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > enter door

            — Inside Cabin —

            You are inside a cozy cabin.
            """)

        // Verify player moved
        let playerLocation = await engine.playerLocationID
        #expect(playerLocation == "insideCabin")

        // Verify door was touched
        let finalDoorState = try await engine.item("door")
        #expect(finalDoorState.hasFlag(.isTouched))
    }

    @Test("Enter basic enterable item without movement")
    func testEnterBasicEnterableItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let booth = Item(
            id: "booth",
            .name("phone booth"),
            .description("An old phone booth."),
            .isEnterable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: booth
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("enter booth")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > enter booth
            Enter what?
            """)

        let finalState = try await engine.item("booth")
        #expect(finalState.hasFlag(.isTouched))
    }

    @Test("Enter sets touched flag on item")
    func testEnterSetsTouchedFlag() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let car = Item(
            id: "car",
            .name("old car"),
            .description("An old car."),
            .isEnterable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: car
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("enter car")

        // Then: Verify state changes
        let finalState = try await engine.item("car")
        #expect(finalState.hasFlag(.isTouched))

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > enter car
            Enter what?
            """)
    }

    @Test("Enter multiple different enterable items")
    func testEnterMultipleDifferentItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let house = Item(
            id: "house",
            .name("small house"),
            .description("A small house."),
            .isEnterable,
            .in(.location("testRoom"))
        )

        let cave = Item(
            id: "cave",
            .name("dark cave"),
            .description("A dark cave."),
            .isEnterable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: house, cave
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Enter house
        try await engine.execute("enter house")

        // Then
        let output1 = await mockIO.flush()
        expectNoDifference(
            output1,
            """
            > enter house
            Enter what?
            """)

        // When: Enter cave
        try await engine.execute("enter cave")

        // Then
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > enter cave
            Enter what?
            """)

        // Verify both items were touched
        let houseState = try await engine.item("house")
        let caveState = try await engine.item("cave")
        #expect(houseState.hasFlag(.isTouched))
        #expect(caveState.hasFlag(.isTouched))
    }

    @Test("Enter item with complex movement scenario")
    func testEnterItemWithComplexMovement() async throws {
        // Given
        let outside = Location(
            id: "outside",
            .name("Outside Building"),
            .inherentlyLit,
            .exits([.north: Exit(destination: "lobby", doorID: "entrance")])
        )

        let lobby = Location(
            id: "lobby",
            .name("Building Lobby"),
            .description("A spacious lobby."),
            .inherentlyLit,
            .exits([.south: Exit(destination: "outside", doorID: "entrance")])
        )

        let entrance = Item(
            id: "entrance",
            .name("main entrance"),
            .description("The main entrance to the building."),
            .isEnterable,
            .in(.location("outside"))
        )

        let game = MinimalGame(
            player: Player(in: "outside"),
            locations: outside, lobby,
            items: entrance
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("enter entrance")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > enter entrance

            — Building Lobby —

            A spacious lobby.
            """)

        // Verify player moved to lobby
        let playerLocation = await engine.playerLocationID
        #expect(playerLocation == "lobby")

        // Verify entrance was touched
        let finalEntranceState = try await engine.item("entrance")
        #expect(finalEntranceState.hasFlag(.isTouched))
    }

    @Test("Enter when there are multiple enterable items")
    func testEnterWithMultipleEnterableItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let tent = Item(
            id: "tent",
            .name("green tent"),
            .description("A green camping tent."),
            .isEnterable,
            .in(.location("testRoom"))
        )

        let hut = Item(
            id: "hut",
            .name("grass hut"),
            .description("A grass hut."),
            .isEnterable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: tent, hut
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Enter specific item
        try await engine.execute("enter tent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > enter tent
            Enter what?
            """)

        let finalTentState = try await engine.item("tent")
        #expect(finalTentState.hasFlag(.isTouched))
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = EnterActionHandler()
        // EnterActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = EnterActionHandler()
        #expect(handler.verbs.contains(.enter))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = EnterActionHandler()
        #expect(handler.requiresLight == true)
    }
}
