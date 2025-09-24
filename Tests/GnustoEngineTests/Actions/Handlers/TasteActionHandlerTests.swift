import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("TasteActionHandler Tests")
struct TasteActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("TASTE DIRECTOBJECT syntax works")
    func testTasteDirectObjectSyntax() async throws {
        // Given
        let apple = Item(
            id: "apple",
            .name("moldy apple"),
            .description("A withered moldy apple."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: apple
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("taste apple")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > taste apple
            The flavor of the moldy apple will not be making any culinary
            history.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot taste without specifying target")
    func testCannotTasteWithoutTarget() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("taste")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > taste
            You taste nothing worth noting.
            """
        )
    }

    @Test("Cannot taste target not in scope")
    func testCannotTasteTargetNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteCake = Item(
            id: "remoteCake",
            .name("remote cake"),
            .description("A cake in another room."),
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteCake
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("taste cake")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > taste cake
            You cannot reach any such thing from here.
            """
        )
    }

    @Test("Taste works in dark room")
    func testTasteWorksInDarkRoom() async throws {
        // Given: Dark room with an object to taste
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let bread = Item(
            id: "bread",
            .name("stale bread"),
            .description("A piece of stale bread."),
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: bread
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("taste bread")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > taste bread
            You cannot reach any such thing from here.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Taste object in room")
    func testTasteObjectInRoom() async throws {
        // Given
        let berry = Item(
            id: "berry",
            .name("wild berry"),
            .description("A small wild berry."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: berry
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("taste berry")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > taste berry
            The flavor of the wild berry will not be making any culinary
            history.
            """
        )
    }

    @Test("Taste character gives appropriate message")
    func testTasteCharacter() async throws {
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
        try await engine.execute(
            "taste the wizard",
            "lick the wizard",
            "taste the wizard",
        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > taste the wizard
            The old wizard is a person, not a delicacy to be sampled.

            > lick the wizard
            The old wizard is a person, not a delicacy to be sampled.

            > taste the wizard
            Tasting the old wizard would end your relationship and possibly
            your freedom.
            """
        )

        let finalState = await engine.item("wizard")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Taste enemy gives appropriate message")
    func testTasteEnemy() async throws {
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
        try await engine.execute(
            "lick the necromancer",
            "taste the necromancer",
            "lick the necromancer",
        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > lick the necromancer
            That's a level of intimacy the furious necromancer would answer
            with sharp steel.

            The furious necromancer attacks with pure murderous intent! You
            brace yourself for the impact, guard up, ready for the worst
            kind of fight.

            > taste the necromancer
            That's a level of intimacy the furious necromancer would answer
            with sharp steel.

            The counterblow comes wild and desperate, the furious
            necromancer hammering through your guard to bruise rather than
            break. Pain flickers and dies. Your body has more important
            work.

            > lick the necromancer
            Tasting the furious necromancer ranks among history's worst
            battle strategies.

            The counterblow comes wild and desperate, the furious
            necromancer hammering through your guard to bruise rather than
            break. Pain flickers and dies. Your body has more important
            work.
            """
        )

        let finalState = await engine.item("necromancer")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Taste self")
    func testTasteSelf() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute(
            "taste myself",
            "lick myself",
            "lick myself",
        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > taste myself
            Your auto-gustatory exploration yields no surprising flavors.

            > lick myself
            You taste vaguely of determination and poor life choices.

            > lick myself
            You sample your own flavor. The results are predictably salty.
            """
        )
    }

    @Test("Taste object in open container")
    func testTasteObjectInOpenContainer() async throws {
        // Given
        let bowl = Item(
            id: "bowl",
            .name("fruit bowl"),
            .description("A bowl filled with fruit."),
            .isContainer,
            .isOpenable,
            .isOpen,
            .in(.startRoom)
        )

        let orange = Item(
            id: "orange",
            .name("moldy orange"),
            .description("A moldy orange."),
            .in(.item("bowl"))
        )

        let game = MinimalGame(
            items: bowl, orange
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute(
            "taste the moldy orange",
            "lick the orange",
            "taste moldy orange",
        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > taste the moldy orange
            The flavor of the moldy orange will not be making any culinary
            history.

            > lick the orange
            The flavor of the moldy orange will not be making any culinary
            history.

            > taste moldy orange
            The moldy orange tastes remarkably like you'd expect the moldy
            orange to taste.
            """
        )
    }

    @Test("Taste sequence of different foods")
    func testTasteSequenceOfDifferentFoods() async throws {
        // Given
        let cookie = Item(
            id: "cookie",
            .name("ancient cookie"),
            .description("An ancient cookie."),
            .in(.startRoom)
        )

        let milk = Item(
            id: "milk",
            .name("glass of lumpy milk"),
            .description("A warm glass of milk."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: cookie, milk
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute(
            "lick the cookie",
            "taste the milk"
        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > lick the cookie
            The flavor of the ancient cookie will not be making any
            culinary history.

            > taste the milk
            The flavor of the glass of lumpy milk will not be making any
            culinary history.
            """
        )
    }

    @Test("Different taste syntax variations")
    func testDifferentTasteSyntaxVariations() async throws {
        // Given
        let slime = Item(
            id: "slime",
            .name("bubbling slime"),
            .description("A scoop of bubbling slime."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: slime
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute(
            "taste the slime",
            "lick the slime"
        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > taste the slime
            The flavor of the bubbling slime will not be making any
            culinary history.

            > lick the slime
            The flavor of the bubbling slime will not be making any
            culinary history.
            """
        )
    }

    @Test("Taste unusual objects")
    func testTasteUnusualObjects() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("smooth rock"),
            .description("A smooth stone."),
            .in(.startRoom)
        )

        let metal = Item(
            id: "metal",
            .name("copper coin"),
            .description("A tarnished copper coin."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: rock, metal
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute(
            "taste rock",
            "lick coin"
        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > taste rock
            The flavor of the smooth rock will not be making any culinary
            history.

            > lick coin
            The flavor of the copper coin will not be making any culinary
            history.
            """
        )
    }

    @Test("Multiple taste attempts")
    func testMultipleTasteAttempts() async throws {
        // Given
        let slop = Item(
            id: "slop",
            .name("bowl of slop"),
            .description("A warm bowl of slop."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: slop
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute(
            "taste the slop",
            "taste the slop",
            "lick the slop"
        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > taste the slop
            The flavor of the bowl of slop will not be making any culinary
            history.

            > taste the slop
            The flavor of the bowl of slop will not be making any culinary
            history.

            > lick the slop
            The bowl of slop tastes remarkably like you'd expect the bowl
            of slop to taste.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = TasteActionHandler()
        #expect(handler.synonyms.contains(.taste))
        #expect(handler.synonyms.contains(.lick))
        #expect(handler.synonyms.count == 2)
    }

    @Test("Handler does not require light")
    func testDoesNotRequireLight() async throws {
        let handler = TasteActionHandler()
        #expect(handler.requiresLight == false)
    }
}
