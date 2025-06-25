import Testing
import CustomDump
@testable import GnustoEngine

@Suite("EnterActionHandler Tests")
struct EnterActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("ENTER syntax works")
    func testEnterSyntax() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)

        let boat = Item(
            id: "boat",
            .name("small boat"),
            .description("A small boat is here."),
            .isVehicle,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: boat
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("enter boat")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > enter boat
            You are now in the small boat.
            """)

        #expect(await engine.gameState.player.parent == .item("boat"))
    }

    @Test("GET IN syntax works")
    func testGetInSyntax() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)

        let car = Item(
            id: "car",
            .name("rusty car"),
            .description("A rusty car sits here."),
            .isVehicle,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: car
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("get in car")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > get in car
            You are now in the rusty car.
            """)

        #expect(await engine.gameState.player.parent == .item("car"))
    }

    // MARK: - Validation Testing

    @Test("Cannot enter without specifying target")
    func testCannotEnterWithoutTarget() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let game = MinimalGame(player: Player(in: "testRoom"), locations: testRoom)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("enter")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > enter
            What do you want to enter?
            """)
    }

    @Test("Cannot enter item not in scope")
    func testCannotEnterItemNotInScope() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let anotherRoom = Location(id: "anotherRoom", .name("Another Room"), .inherentlyLit)
        let remoteBoat = Item(id: "remoteBoat", .name("remote boat"), .isVehicle, .in(.location("anotherRoom")))

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteBoat
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("enter boat")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > enter boat
            You can't see any such thing.
            """)
    }

    @Test("Requires light to enter items")
    func testRequiresLight() async throws {
        // Given
        let darkRoom = Location(id: "darkRoom", .name("Dark Room"))
        let boat = Item(id: "boat", .name("small boat"), .isVehicle, .in(.location("darkRoom")))

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: boat
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("enter boat")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > enter boat
            It is pitch black. You can't see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Cannot enter a non-vehicle item")
    func testCannotEnterNonVehicle() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let box = Item(id: "box", .name("large box"), .isContainer, .in(.location("testRoom")))

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("enter box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > enter box
            You can't enter that.
            """)
    }

    @Test("Cannot enter a closed item")
    func testCannotEnterClosedItem() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let submarine = Item(
            id: "submarine",
            .name("yellow submarine"),
            .isVehicle,
            .isContainer, // Must be a container to be closable
            // Note: .isOpen is false
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: submarine
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("enter submarine")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > enter submarine
            The yellow submarine is closed.
            """)
    }

    @Test("Cannot enter an item when already inside it")
    func testCannotEnterWhenAlreadyInside() async throws {
        // Given
        let boat = Item(id: "boat", .name("small boat"), .isVehicle)
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit, .with(boat))

        let game = MinimalGame(
            player: Player(in: "boat"),
            locations: testRoom,
            items: boat
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("enter boat")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > enter boat
            You are already in the small boat.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = EnterActionHandler()
        #expect(handler.verbs.contains(.enter))
        #expect(handler.verbs.contains(.getIn))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = EnterActionHandler()
        #expect(handler.requiresLight == true)
    }
}
