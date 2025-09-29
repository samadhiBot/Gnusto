import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("SmellActionHandler Tests")
struct SmellActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("SMELL DIRECTOBJECT syntax works")
    func testSmellDirectObjectSyntax() async throws {
        // Given
        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .description("A shiny brass lamp."),
            .isTakable,
            .isLightSource,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("smell lamp")

        // Then
        await mockIO.expectOutput(
            """
            > smell lamp
            The brass lamp smells exactly as you'd expect, which is to say,
            not particularly noteworthy.
            """
        )

        let finalState = await engine.item("lamp")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - Validation Testing

    @Test("Cannot smell non-existent item")
    func testCannotSmellNonExistentItem() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("smell nonexistent")

        // Then
        await mockIO.expectOutput(
            """
            > smell nonexistent
            Any such thing remains frustratingly inaccessible.
            """
        )
    }

    @Test("Cannot smell item not in reach")
    func testCannotSmellItemNotInReach() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let distantItem = Item(
            id: "distantItem",
            .name("distant statue"),
            .description("A statue in another room."),
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: distantItem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("smell statue")

        // Then
        await mockIO.expectOutput(
            """
            > smell statue
            Any such thing remains frustratingly inaccessible.
            """
        )
    }

    @Test("Cannot smell non-item")
    func testCannotSmellNonItem() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("smell the sky")

        // Then
        await mockIO.expectOutput(
            """
            > smell the sky
            You detect no olfactory surprises.
            """
        )
    }

    @Test("Require no light to smell")
    func testRequiresNoLight() async throws {
        // Given: Dark room with item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let statue = Item(
            id: "statue",
            .name("stone statue"),
            .description("A carved stone statue."),
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: statue
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("smell the dark room")

        // Then
        await mockIO.expectOutput(
            """
            > smell the dark room
            You detect no olfactory surprises.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Smell character gives appropriate message")
    func testSmellCharacter() async throws {
        // Given
        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .description("A wise old wizard."),
            .characterSheet(.wise),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: wizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("smell the wizard")

        // Then
        await mockIO.expectOutput(
            """
            > smell the wizard
            The old wizard's personal aroma remains their private business.
            """
        )

        let finalState = await engine.item("wizard")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Smell enemy gives appropriate message")
    func testSmellEnemy() async throws {
        // Given
        let necromancer = Item(
            id: "necromancer",
            .name("furious necromancer"),
            .description("An angry old necromancer."),
            .characterSheet(
                CharacterSheet(isFighting: true)
            ),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: necromancer
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("smell the necromancer")

        // Then
        await mockIO.expectOutput(
            """
            > smell the necromancer
            You detect nothing unusual about the furious necromancer's
            scent.

            No weapons between you--just the furious necromancer's
            aggression and your desperation! You collide in a tangle of
            strikes and blocks.
            """
        )

        let finalState = await engine.item("necromancer")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Sniff without object")
    func testSniffWithoutObject() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("sniff")

        // Then
        await mockIO.expectOutput(
            """
            > sniff
            Nothing remarkable greets your nostrils.
            """
        )
    }

    @Test("Sniff self")
    func testSniffSelf() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("sniff myself")

        // Then
        await mockIO.expectOutput(
            """
            > sniff myself
            Your personal aroma falls within acceptable parameters.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = SmellActionHandler()
        #expect(handler.synonyms.contains(.smell))
        #expect(handler.synonyms.contains(.sniff))
        #expect(handler.synonyms.count == 2)
    }

    @Test("Handler does not require light")
    func testDoesNotRequireLight() async throws {
        let handler = SmellActionHandler()
        #expect(handler.requiresLight == false)
    }
}
