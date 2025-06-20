import CustomDump
import Testing

@testable import GnustoEngine

@Suite("TurnOffActionHandler Tests")
struct TurnOffActionHandlerTests {
    let handler = TurnOffActionHandler()

    @Test("TURN OFF turns off a light source in a dark room makes everything dark")
    func testTurnOffLightSource() async throws {
        let room = Location(
            id: "room",
            .name("Test Room"),
            .description("You are here.")
        )
        let lamp = Item(
            id: "lamp",
            .name("lamp"),
            .in(.player),
            .isDevice,
            .isLightSource,
            .isOn,
        )

        let game = MinimalGame(
            player: Player(in: "room"),
            locations: room,
            items: lamp
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("turn off lamp")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off lamp
            The lamp is now off. You are plunged into darkness.

            It is pitch black. You can’t see a thing.
            """)
        let finalItemState = try await engine.item("lamp")
        #expect(finalItemState.hasFlag(.isOn) == false)
        #expect(finalItemState.hasFlag(.isTouched) == true)
    }

    @Test("TURN OFF fails for non-light source")
    func testTurnOffNonLightSource() async throws {
        let room = Location(
            id: "room",
            .name("Test Room"),
            .description("You are here."),
            .inherentlyLit
        )
        let book = Item(
            id: "book",
            .name("book"),
            .in(.location(room.id))
        )

        let game = MinimalGame(
            player: Player(in: "room"),
            locations: room,
            items: book
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("turn off book")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn off book
            You can’t turn that off.
            """)
    }

    @Test("TURN OFF fails for non-existent item")
    func testTurnOffNonExistentItem() async throws {
        let room = Location(
            id: "room",
            .name("Test Room"),
            .description("You are here.")
        )

        let game = MinimalGame(
            player: Player(in: "room"),
            locations: room
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("turn off lamp")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn off lamp
            You can’t see any such thing.
            """)
    }

    @Test("Successfully turn off a light source in inventory")
    func testTurnOffLightSourceInInventory() async throws {
        let lamp = Item(
            id: "lamp",
            .name("brass lantern"),
            .description("A brass lantern."),
            .in(.player),
            .isDevice,
            .isLightSource,
            .isOn,
            .isTakable,
            .size(10),
        )
        let game = MinimalGame(items: lamp)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("turn off lamp")

        let finalItemState = try await engine.item("lamp")
        #expect(finalItemState.hasFlag(.isOn) == false)
        #expect(finalItemState.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn off lamp
            The brass lantern is now off.
            """)
    }

    @Test("Turn off light source making a room pitch black")
    func testTurnOffLightSourceCausesDarkness() async throws {
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("This room will become dark.")
        )
        let lamp = Item(
            id: "lamp",
            .name("brass lantern"),
            .description("A brass lantern."),
            .in(.location(darkRoom.id)),
            .isDevice,
            .isLightSource,
            .isTakable,
            .isOn,
            .size(10)
        )
        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: lamp
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        let initiallyLit = await engine.scopeResolver.isLocationLit(locationID: darkRoom.id)
        #expect(initiallyLit == true)

        // Act
        try await engine.execute("turn off lamp")

        let finalItemState = try await engine.item("lamp")
        #expect(finalItemState.hasFlag(.isOn) == false)
        #expect(finalItemState.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off lamp
            The brass lantern is now off. You are plunged into darkness.

            It is pitch black. You can’t see a thing.
            """)

        let finallyLit = await engine.scopeResolver.isLocationLit(locationID: darkRoom.id)
        #expect(finallyLit == false)
    }

    @Test("Try to turn off item already off")
    func testTurnOffItemAlreadyOff() async throws {
        let lamp = Item(
            id: "lamp",
            .name("brass lantern"),
            .description("A brass lantern."),
            .in(.player),
            .isDevice,
            .isLightSource,
            .isTakable,
            .size(10)
        )
        let game = MinimalGame(items: lamp)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("turn off lamp")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn off lamp
            It's already off.
            """)

        // Check state remains unchanged - touched should NOT be added if validation fails
        let finalItemState = try await engine.item("lamp")
        #expect(finalItemState.hasFlag(.isOn) == false)
        #expect(finalItemState.hasFlag(.isTouched) == false)
    }

    @Test("Try to turn off non-device item")
    func testTurnOffNonDeviceItem() async throws {
        let lamp = Item(
            id: "lamp",
            .name("brass lantern"),
            .description("A brass lantern."),
            .in(.player),
            .isTakable,
            .isOn,
            .size(10)
        )
        let game = MinimalGame(items: lamp)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("turn off lamp")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn off lamp
            You can’t turn that off.
            """)

        // Check state remains unchanged - touched should NOT be added if validation fails
        let finalItemState = try await engine.item("lamp")
        #expect(finalItemState.hasFlag(.isOn) == true)
        #expect(finalItemState.hasFlag(.isTouched) == false)
    }

    @Test("Try to turn off item not accessible")
    func testTurnOffItemNotAccessible() async throws {
        let lamp = Item(
            id: "lamp",
            .name("brass lantern"),
            .description("A brass lantern."),
            .in(.nowhere),
            .isDevice,
            .isLightSource,
            .isTakable,
            .isOn,
            .size(10)
        )
        let game = MinimalGame(items: lamp)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: Execute the command
        try await engine.execute("turn off lamp")

        // Assert: Check IOHandler output for the expected error message
        let output = await mockIO.flush()
        // The specific response message comes from GameEngine.report
        expectNoDifference(output, """
            > turn off lamp
            You can’t see any such thing.
            """)
    }

    @Test("Extinguish alias works correctly")
    func testExtinguishAlias() async throws {
        // Arrange
        let lamp = Item(
            id: "lamp",
            .name("brass lantern"),
            .in(.location("darkRoom")),
            .isDevice,
            .isLightSource,
            .isTakable,
            .isOn
        )
        let darkRoom = Location(
            id: "darkRoom",
            .name("Pitch Black Room"),
            .description("It's dark.")
        )
        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: lamp
        )
        // Use the real parser to test alias resolution
        let (engine, mockIO) = await GameEngine.test(
            blueprint: game
        )

        // Act
        try await engine.execute("extinguish lamp")

        // Assert
        let finalItemState = try await engine.item("lamp")
        #expect(finalItemState.hasFlag(.isOn) == false)
        #expect(finalItemState.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > extinguish lamp
            The brass lantern is now off. You are plunged into darkness.

            It is pitch black. You can’t see a thing.
            """)
    }

    @Test("Blow Out alias works correctly")
    func testBlowOutAlias() async throws {
        // Arrange
        let lamp = Item(
            id: "lamp",
            .name("brass lantern"),
            .in(.location("darkRoom")),
            .isDevice,
            .isLightSource,
            .isTakable,
            .isOn
        )
        let darkRoom = Location(
            id: "darkRoom",
            .name("Pitch Black Room"),
            .description("It's dark.")
        )
        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: lamp
        )
        // Use the real parser to test alias resolution
        let (engine, mockIO) = await GameEngine.test(
            blueprint: game
        )

        // Act
        try await engine.execute("blow out lamp")

        // Assert
        let finalItemState = try await engine.item("lamp")
        #expect(finalItemState.hasFlag(.isOn) == false)
        #expect(finalItemState.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > blow out lamp
            The brass lantern is now off. You are plunged into darkness.

            It is pitch black. You can’t see a thing.
            """)
    }
}
