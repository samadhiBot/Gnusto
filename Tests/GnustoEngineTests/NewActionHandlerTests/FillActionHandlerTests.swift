import Foundation
import Testing

@testable import GnustoEngine

@Suite("FillActionHandler Tests")
struct FillActionHandlerTests {
    let handler = FillActionHandler()
    var game: MinimalGame!
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    @Before
    func setup() {
        let well = Item(
            id: "well",
            .name("well"),
            .description("A stone well."),
            .isDrinkable,
            .in(.location("room"))
        )
        let bottle = Item(
            id: "bottle",
            .name("glass bottle"),
            .description("A glass bottle."),
            .isContainer,
            .in(.location("room"))
        )
        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A wooden box."),
            .isContainer,
            .in(.location("room"))
        )

        game = MinimalGame(
            player: Player(in: "room", holding: "bottle"),
            locations: [Location(id: "room", .name("Room"))],
            items: [well, bottle, box]
        )
    }

    // MARK: - Syntax Rule Testing

    @Test("FILL BOTTLE syntax works")
    func testFillBottleSyntax() async throws {
        (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.update(item: "bottle") { $0.setFlag(.isOpen) }
        try await engine.execute("fill bottle")
        let output = await mockIO.flush()
        #expect(output.contains("You fill the glass bottle from the well."))
    }

    @Test("FILL BOTTLE FROM WELL syntax works")
    func testFillBottleFromWellSyntax() async throws {
        (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.update(item: "bottle") { $0.setFlag(.isOpen) }
        try await engine.execute("fill bottle from well")
        let output = await mockIO.flush()
        #expect(output.contains("You fill the glass bottle from the well."))
    }

    @Test("FILL BOTTLE WITH WELL syntax works")
    func testFillBottleWithWellSyntax() async throws {
        (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.update(item: "bottle") { $0.setFlag(.isOpen) }
        try await engine.execute("fill bottle with well")
        let output = await mockIO.flush()
        #expect(output.contains("You fill the glass bottle from the well."))
    }

    // MARK: - Validation Testing

    @Test("Fails when direct object is missing")
    func testValidationFailsWhenDirectObjectIsMissing() async throws {
        (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("fill")
        let output = await mockIO.flush()
        #expect(output.contains("Fill what?"))
    }

    @Test("Fails when target is not a container")
    func testValidationFailsWhenTargetIsNotAContainer() async throws {
        (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("fill well")
        let output = await mockIO.flush()
        #expect(output.contains("You can't fill that."))
    }

    @Test("Fails when container is closed")
    func testValidationFailsWhenContainerIsClosed() async throws {
        (engine, mockIO) = await GameEngine.test(blueprint: game)
        // Bottle is closed by default
        try await engine.execute("fill bottle")
        let output = await mockIO.flush()
        #expect(output.contains("The glass bottle is closed."))
    }

    @Test("Fails when source is not reachable")
    func testValidationFailsWhenSourceNotReachable() async throws {
        let remoteWell = Item(
            id: "remoteWell", .name("distant well"), .isDrinkable, .in(.location("otherRoom")))
        let otherRoom = Location(id: "otherRoom", .name("Other Room"))
        var blueprint = game.gameBlueprint
        blueprint.locations.append(otherRoom)
        blueprint.items.append(remoteWell)

        (engine, mockIO) = await GameEngine.test(blueprint: blueprint)
        try await engine.update(item: "bottle") { $0.setFlag(.isOpen) }

        try await engine.execute("fill bottle from well")
        let output = await mockIO.flush()
        #expect(output.contains("You can't see any distant well here."))
    }

    // MARK: - Processing Testing

    @Test("Fills from implicit water source in location")
    func testProcessFillsFromImplicitSource() async throws {
        (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.update(item: "bottle") { $0.setFlag(.isOpen) }

        try await engine.execute("fill bottle")
        let output = await mockIO.flush()
        #expect(output.contains("You fill the glass bottle from the well."))

        let bottle = try await engine.item("bottle")
        #expect(bottle.hasFlag(.isTouched) == true)
    }

    @Test("Fails when no implicit water source is available")
    func testProcessFailsWithNoImplicitSource() async throws {
        var blueprint = game.gameBlueprint
        blueprint.items.removeAll { $0.id == "well" }
        (engine, mockIO) = await GameEngine.test(blueprint: blueprint)
        try await engine.update(item: "bottle") { $0.setFlag(.isOpen) }

        try await engine.execute("fill bottle")
        let output = await mockIO.flush()
        #expect(output.contains("There is nothing suitable to fill it with here."))
    }

    @Test("Fails when explicit source is not drinkable")
    func testProcessFailsWithNonDrinkableSource() async throws {
        (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.update(item: "bottle") { $0.setFlag(.isOpen) }

        try await engine.execute("fill bottle from box")
        let output = await mockIO.flush()
        #expect(output.contains("You can't fill it from that!"))
    }

    @Test("Succeeds with explicit drinkable source")
    func testProcessSucceedsWithExplicitSource() async throws {
        (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.update(item: "bottle") { $0.setFlag(.isOpen) }

        try await engine.execute("fill bottle with well")
        let output = await mockIO.flush()
        #expect(output.contains("You fill the glass bottle from the well."))

        let bottle = try await engine.item("bottle")
        #expect(bottle.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("FILL action resolves to FillActionHandler")
    func testFillActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("fill bottle")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is FillActionHandler)
    }
}
