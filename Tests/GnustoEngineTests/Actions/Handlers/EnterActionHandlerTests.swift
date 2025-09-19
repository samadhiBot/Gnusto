import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("EnterActionHandler Tests")
struct EnterActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("ENTER DIRECTOBJECT syntax works")
    func testEnterDirectObjectSyntax() async throws {
        // Given
        let outside = Location(
            id: "outside",
            .name("Outside"),
            .description("You are outside."),
            .inherentlyLit,
            .exits(
                .north("inside", via: "door")
            )
        )

        let inside = Location(
            id: "inside",
            .name("Inside"),
            .description("You are inside."),
            .inherentlyLit
        )

        let door = Item(
            id: "door",
            .name("wooden door"),
            .description("A sturdy wooden door."),
            .in("outside")
        )

        let game = MinimalGame(
            player: Player(in: "outside"),
            locations: outside, inside,
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
            --- Inside ---

            You are inside.
            """
        )

        // Verify player moved
        let playerLocation = await engine.player.location.id
        #expect(playerLocation == "inside")
    }

    @Test("GET IN DIRECTOBJECT syntax works")
    func testGetInDirectObjectSyntax() async throws {
        // Given
        let outside = Location(
            id: "outside",
            .name("Outside"),
            .inherentlyLit,
            .exits(
                .east("inside", via: "hatch")
            )
        )

        let inside = Location(
            id: "inside",
            .name("Inside"),
            .description("You are inside."),
            .inherentlyLit
        )

        let hatch = Item(
            id: "hatch",
            .name("escape hatch"),
            .description("A small escape hatch."),
            .in("outside")
        )

        let game = MinimalGame(
            player: Player(in: "outside"),
            locations: outside, inside,
            items: hatch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("get in hatch")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > get in hatch
            --- Inside ---

            You are inside.
            """
        )

        // Verify player moved
        let playerLocation = await engine.player.location.id
        #expect(playerLocation == "inside")
    }

    @Test("GO IN DIRECTOBJECT syntax works")
    func testGoInDirectObjectSyntax() async throws {
        // Given
        let outside = Location(
            id: "outside",
            .name("Outside"),
            .inherentlyLit,
            .exits(
                .west("inside", via: "entrance")
            )
        )

        let inside = Location(
            id: "inside",
            .name("Inside"),
            .description("You are inside."),
            .inherentlyLit
        )

        let entrance = Item(
            id: "entrance",
            .name("cave entrance"),
            .description("A dark cave entrance."),
            .in("outside")
        )

        let game = MinimalGame(
            player: Player(in: "outside"),
            locations: outside, inside,
            items: entrance
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("go in entrance")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > go in entrance
            --- Inside ---

            You are inside.
            """
        )

        // Verify player moved
        let playerLocation = await engine.player.location.id
        #expect(playerLocation == "inside")
    }

    @Test("GO THROUGH DIRECTOBJECT syntax works")
    func testGoThroughDirectObjectSyntax() async throws {
        // Given
        let outside = Location(
            id: "outside",
            .name("Outside"),
            .inherentlyLit,
            .exits(
                .south("inside", via: "portal")
            )
        )

        let inside = Location(
            id: "inside",
            .name("Inside"),
            .description("You are inside."),
            .inherentlyLit
        )

        let portal = Item(
            id: "portal",
            .name("shimmering portal"),
            .description("A magical portal."),
            .in("outside")
        )

        let game = MinimalGame(
            player: Player(in: "outside"),
            locations: outside, inside,
            items: portal
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("go through portal")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > go through portal
            --- Inside ---

            You are inside.
            """
        )

        // Verify player moved
        let playerLocation = await engine.player.location.id
        #expect(playerLocation == "inside")
    }

    // MARK: - Validation Testing

    @Test("Cannot enter without specifying target when no doors available")
    func testCannotEnterWithoutTargetNoDoors() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("enter")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > enter
            Multiple entrances present themselves. Which calls to you?
            """
        )
    }

    @Test("Auto-selects single enterable door when no target specified")
    func testAutoSelectsSingleEnterableDoor() async throws {
        // Given
        let outside = Location(
            id: "outside",
            .name("Outside"),
            .inherentlyLit,
            .exits(
                .north("inside", via: "door")
            )
        )

        let inside = Location(
            id: "inside",
            .name("Inside"),
            .description("You are inside."),
            .inherentlyLit
        )

        let door = Item(
            id: "door",
            .name("wooden door"),
            .description("A wooden door."),
            .in("outside")
        )

        let game = MinimalGame(
            player: Player(in: "outside"),
            locations: outside, inside,
            items: door
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
            --- Inside ---

            You are inside.
            """
        )

        // Verify player moved
        let playerLocation = await engine.player.location.id
        #expect(playerLocation == "inside")
    }

    @Test("Asks for clarification when multiple doors available")
    func testAsksForClarificationWithMultipleDoors() async throws {
        // Given
        let courtyard = Location(
            id: "courtyard",
            .name("Courtyard"),
            .inherentlyLit,
            .exits(
                .north("hall", via: "door1"),
                .south("garden", via: "door2")
            )
        )

        let hall = Location(
            id: "hall",
            .name("Hall"),
            .description("You are in a hall."),
            .inherentlyLit
        )

        let garden = Location(
            id: "garden",
            .name("Garden"),
            .description("You are in a garden."),
            .inherentlyLit
        )

        let door1 = Item(
            id: "door1",
            .name("oak door"),
            .description("A heavy oak door."),
            .in("courtyard")
        )

        let door2 = Item(
            id: "door2",
            .name("garden gate"),
            .description("A wrought iron gate."),
            .in("courtyard")
        )

        let game = MinimalGame(
            player: Player(in: "courtyard"),
            locations: courtyard, hall, garden,
            items: door1, door2
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
            Multiple entrances present themselves. Which calls to you?
            """
        )
    }

    @Test("Cannot enter target not in scope")
    func testCannotEnterTargetNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit,
            .exits(
                .east("somewhere", via: "remoteDoor")
            )
        )

        let remoteDoor = Item(
            id: "remoteDoor",
            .name("remote door"),
            .description("A door in another room."),
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteDoor
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
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot enter item that is not a door")
    func testCannotEnterNonDoorItem() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A large boulder."),
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            The large rock stubbornly resists your attempts to enter it.
            """
        )
    }

    @Test("Requires light to enter")
    func testRequiresLight() async throws {
        // Given: Dark room with door
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room."),
            .exits(
                .up("attic", via: "trapdoor")
            )
            // Note: No .inherentlyLit property
        )

        let attic = Location(
            id: "attic",
            .name("Attic"),
            .description("You are in an attic."),
            .inherentlyLit
        )

        let trapdoor = Item(
            id: "trapdoor",
            .name("wooden trapdoor"),
            .description("A wooden trapdoor in the ceiling."),
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom, attic,
            items: trapdoor
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("enter trapdoor")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > enter trapdoor
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Enter door sets touched flag and updates pronouns")
    func testEnterDoorSetsTouchedAndPronouns() async throws {
        // Given
        let outside = Location(
            id: "outside",
            .name("Outside"),
            .inherentlyLit,
            .exits(
                .north("inside", via: "door")
            )
        )

        let inside = Location(
            id: "inside",
            .name("Inside"),
            .description("You are inside."),
            .inherentlyLit
        )

        let door = Item(
            id: "door",
            .name("wooden door"),
            .description("A wooden door."),
            .in("outside")
        )

        let game = MinimalGame(
            player: Player(in: "outside"),
            locations: outside, inside,
            items: door
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("enter door")

        // Then: Verify door was touched
        let finalDoorState = await engine.item("door")
        #expect(await finalDoorState.hasFlag(.isTouched))

        // Verify movement occurred
        let playerLocation = await engine.player.location.id
        #expect(playerLocation == "inside")
    }

    @Test("Enter door delegates to GO command")
    func testEnterDoorDelegatesToGoCommand() async throws {
        // Given
        let hallway = Location(
            id: "hallway",
            .name("Hallway"),
            .description("A long hallway."),
            .inherentlyLit,
            .exits(
                .west("office", via: "door")
            )
        )

        let office = Location(
            id: "office",
            .name("Office"),
            .description("A small office."),
            .inherentlyLit
        )

        let door = Item(
            id: "door",
            .name("office door"),
            .description("A plain office door."),
            .in("hallway")
        )

        let game = MinimalGame(
            player: Player(in: "hallway"),
            locations: hallway, office,
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
            --- Office ---

            A small office.
            """
        )

        // Verify player moved to correct location
        let playerLocation = await engine.player.location.id
        #expect(playerLocation == "office")
    }

    @Test("Enter works with different door types")
    func testEnterWithDifferentDoorTypes() async throws {
        // Given
        let plaza = Location(
            id: "plaza",
            .name("Town Plaza"),
            .description("You are in the town plaza."),
            .inherentlyLit,
            .exits(
                .north("shop", via: "door"),
                .south("cave", via: "entrance"),
                .east("tower", via: "gate")
            )
        )

        let shop = Location(
            id: "shop",
            .name("Shop"),
            .description("You are in a shop."),
            .inherentlyLit,
            .exits(
                .south("plaza")
            )
        )

        let cave = Location(
            id: "cave",
            .name("Cave"),
            .description("You are in a cave."),
            .inherentlyLit
        )

        let tower = Location(
            id: "tower",
            .name("Tower"),
            .description("You are in a tower."),
            .inherentlyLit
        )

        let shopDoor = Item(
            id: "door",
            .name("shop door"),
            .description("A wooden shop door."),
            .in("plaza")
        )

        let caveEntrance = Item(
            id: "entrance",
            .name("cave entrance"),
            .description("A dark cave entrance."),
            .in("plaza")
        )

        let towerGate = Item(
            id: "gate",
            .name("tower gate"),
            .description("An iron gate."),
            .in("plaza")
        )

        let game = MinimalGame(
            player: Player(in: "plaza"),
            locations: plaza, shop, cave, tower,
            items: shopDoor, caveEntrance, towerGate
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Enter shop door
        try await engine.execute("enter door")

        // Then
        let output1 = await mockIO.flush()
        expectNoDifference(
            output1,
            """
            > enter door
            --- Shop ---

            You are in a shop.
            """
        )

        // Verify location
        let playerLocation1 = await engine.player.location.id
        #expect(playerLocation1 == "shop")

        // When: Go back to plaza and enter cave
        try await engine.execute("south")  // back to plaza
        try await engine.execute("enter entrance")

        // Then
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > south
            --- Town Plaza ---

            You are in the town plaza.

            There are a shop door, a cave entrance, and a tower gate here.

            > enter entrance
            --- Cave ---

            You are in a cave.
            """
        )

        // Verify location
        let playerLocation2 = await engine.player.location.id
        #expect(playerLocation2 == "cave")
    }

    @Test("Enter door not reachable fails gracefully")
    func testEnterUnreachableDoorFails() async throws {
        // Given: Door exists but is not reachable (in different location)
        let room1 = Location(
            id: "room1",
            .name("Room 1"),
            .inherentlyLit
        )

        let room2 = Location(
            id: "room2",
            .name("Room 2"),
            .description("You are in room 2."),
            .inherentlyLit,
            .exits(
                .east("room3", via: "door")
            )
        )

        let door = Item(
            id: "door",
            .name("wooden door"),
            .description("A wooden door."),
            .in("room2")  // Door is in room2, player is in room1
        )

        let game = MinimalGame(
            player: Player(in: "room1"),
            locations: room1, room2,
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
            Any such thing lurks beyond your reach.
            """
        )
    }

    // MARK: - Handler Properties Testing

    @Test("Handler exposes correct synonyms")
    func testHandlerSynonyms() async throws {
        let handler = EnterActionHandler()
        #expect(handler.synonyms.isEmpty)  // EnterActionHandler uses syntax rules, not synonyms
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = EnterActionHandler()
        #expect(handler.requiresLight == true)
    }

    @Test("Handler syntax rules are correct")
    func testHandlerSyntaxRules() async throws {
        let handler = EnterActionHandler()
        let expectedSyntax: [SyntaxRule] = [
            .match(.get, .in, .directObject),
            .match(.go, .in, .directObject),
            .match(.go, .through, .directObject),
            .match(.enter, .directObject),
        ]
        #expect(handler.syntax.count == expectedSyntax.count)

        // Check that all expected syntax rules are present
        for expectedRule in expectedSyntax {
            #expect(handler.syntax.contains(expectedRule))
        }
    }
}
