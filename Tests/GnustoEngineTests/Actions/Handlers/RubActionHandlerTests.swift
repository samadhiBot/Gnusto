import CustomDump
import Testing

@testable import GnustoEngine

@Suite("RubActionHandler Tests")
struct RubActionHandlerTests {

    @Test("Rub validates missing direct object")
    func testRubValidatesMissingDirectObject() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When / Then
        try await engine.execute("rub")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > rub
            Rub what?
            """)
    }

    @Test("Rub validates item not reachable")
    func testRubValidatesItemNotReachable() async throws {
        // Given
        let distantSphere = Item(
            id: "distant_sphere",
            .name("distant sphere"),
            .in(.nowhere)
        )

        let game = MinimalGame(items: distantSphere)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When / Then
        try await engine.execute("rub distant sphere")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > rub distant sphere
            You can’t see any distant sphere here.
            """)
    }

    @Test("Rub character shows appropriate message")
    func testRubCharacterShowsAppropriateMessage() async throws {
        // Given
        let cat = Item(
            id: "cat",
            .name("cat"),
            .in(.location(.startRoom)),
            .isCharacter
        )

        let game = MinimalGame(items: cat)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rub cat")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > rub cat
            I don’t think the cat would appreciate being rubbed.
            """)
    }

    @Test("Rub clean item shows already clean message")
    func testRubCleanItemShowsAlreadyCleanMessage() async throws {
        // Given
        let mirror = Item(
            id: "mirror",
            .name("mirror"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: mirror)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rub mirror")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > rub mirror
            You rub the mirror. It feels smooth to the touch.
            """)
    }

    @Test("Rub lamp shows djinn message")
    func testRubLampShowsDjinnMessage() async throws {
        // Given
        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .in(.location(.startRoom)),
            .isTakable,
            .isLightSource
        )

        let game = MinimalGame(items: lamp)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rub lamp")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > rub lamp
            Rubbing the brass lamp doesn’t seem to do anything. No djinn appears.
            """)
    }

    @Test("Rub lantern shows djinn message")
    func testRubLanternShowsDjinnMessage() async throws {
        // Given
        let lantern = Item(
            id: "lantern",
            .name("old lantern"),
            .in(.location(.startRoom)),
            .isTakable,
            .isLightSource
        )

        let game = MinimalGame(items: lantern)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rub lantern")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > rub lantern
            Rubbing the old lantern doesn’t seem to do anything. No djinn appears.
            """)
    }

    @Test("Rub takable object shows smooth touch message")
    func testRubTakableObjectShowsSmoothTouchMessage() async throws {
        // Given
        let stone = Item(
            id: "stone",
            .name("smooth stone"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: stone)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rub stone")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > rub stone
            You rub the smooth stone. It feels smooth to the touch.
            """)
    }

    @Test("Rub fixed object shows nothing happens message")
    func testRubFixedObjectShowsNothingHappensMessage() async throws {
        // Given
        let wall = Item(
            id: "wall",
            .name("stone wall"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: wall)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rub wall")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > rub wall
            You rub the stone wall, but nothing interesting happens.
            """)
    }

    @Test("Rub updates state correctly")
    func testRubUpdatesStateCorrectly() async throws {
        // Given
        let orb = Item(
            id: "orb",
            .name("crystal orb"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: orb)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rub orb")

        // Then - Check state was updated
        let finalOrb = try await engine.item("orb")
        #expect(finalOrb.hasFlag(.isTouched))

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > rub orb
            You rub the crystal orb. It feels smooth to the touch.
            """)
    }
}
