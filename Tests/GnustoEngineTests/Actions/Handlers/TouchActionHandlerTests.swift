import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("TouchActionHandler Tests")
struct TouchActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("TOUCH DIRECTOBJECT syntax works")
    func testTouchDirectObjectSyntax() async throws {
        // Given
        let vase = Item(
            id: "vase",
            .name("ceramic vase"),
            .description("A delicate ceramic vase."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: vase
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("touch vase")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > touch vase
            Your tactile investigation of the ceramic vase yields no
            surprises.
            """
        )

        let finalState = await engine.item("vase")
        let wasTouched = await finalState.hasFlag(.isTouched)
        #expect(wasTouched == true)
    }

    // MARK: - Validation Testing

    @Test("Cannot touch without specifying target")
    func testCannotTouchWithoutTarget() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("touch")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > touch
            Touch what?
            """
        )
    }

    @Test("Cannot touch target not in scope")
    func testCannotTouchTargetNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteObject = Item(
            id: "remoteObject",
            .name("remote object"),
            .description("An object in another room."),
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteObject
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("touch object")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > touch object
            You cannot reach any such thing from here.
            """
        )
    }

    @Test("Requires light to touch")
    func testRequiresLight() async throws {
        // Given: Dark room with an object to touch
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let statue = Item(
            id: "statue",
            .name("marble statue"),
            .description("A cold marble statue."),
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: statue
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("touch statue")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > touch statue
            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Touch object in room")
    func testTouchObjectInRoom() async throws {
        // Given
        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A sturdy wooden table."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("touch table")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > touch table
            Your tactile investigation of the wooden table yields no
            surprises.
            """
        )

        let finalState = await engine.item("table")
        let wasTouched = await finalState.hasFlag(.isTouched)
        #expect(wasTouched == true)
    }

    @Test("Touch held item")
    func testTouchHeldItem() async throws {
        // Given
        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A shiny gold coin."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("touch coin")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > touch coin
            Your tactile investigation of the gold coin yields no
            surprises.
            """
        )

        let finalState = await engine.item("coin")
        let wasTouched = await finalState.hasFlag(.isTouched)
        #expect(wasTouched == true)
    }

    @Test("Touch object in open container")
    func testTouchObjectInOpenContainer() async throws {
        // Given
        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A wooden storage box."),
            .isContainer,
            .isOpenable,
            .isOpen,
            .in(.startRoom)
        )

        let gem = Item(
            id: "gem",
            .name("sparkling gem"),
            .description("A beautiful gem."),
            .in(.item("box"))
        )

        let game = MinimalGame(
            items: box, gem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("touch gem")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > touch gem
            Your tactile investigation of the sparkling gem yields no
            surprises.
            """
        )

        let finalState = await engine.item("gem")
        let wasTouched = await finalState.hasFlag(.isTouched)
        #expect(wasTouched == true)
    }

    @Test("Touching sets isTouched flag")
    func testTouchingSetsTouchedFlag() async throws {
        // Given
        let crystal = Item(
            id: "crystal",
            .name("blue crystal"),
            .description("A mysterious blue crystal."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: crystal
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // Verify initial state
        let initialState = await engine.item("crystal")
        let initiallyTouched = await initialState.hasFlag(.isTouched)
        #expect(initiallyTouched == false)

        // When
        try await engine.execute("touch crystal")

        // Then
        let finalState = await engine.item("crystal")
        let finallyTouched = await finalState.hasFlag(.isTouched)
        #expect(finallyTouched == true)
    }

    @Test("Touch multiple objects in sequence")
    func testTouchMultipleObjects() async throws {
        // Given
        let wall = Item(
            id: "wall",
            .name("stone wall"),
            .description("A rough stone wall."),
            .in(.startRoom)
        )

        let door = Item(
            id: "door",
            .name("oak door"),
            .description("A heavy oak door."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: wall, door
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute(
            "touch wall",
            "feel door"
        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > touch wall
            Your tactile investigation of the stone wall yields no
            surprises.

            > feel door
            Your tactile investigation of the oak door yields no surprises.
            """
        )

        let wallState = await engine.item("wall")
        let doorState = await engine.item("door")
        let wallTouched = await wallState.hasFlag(.isTouched)
        let doorTouched = await doorState.hasFlag(.isTouched)
        #expect(wallTouched == true)
        #expect(doorTouched == true)
    }

    @Test("Touch already touched object still responds")
    func testTouchAlreadyTouchedObject() async throws {
        // Given
        let orb = Item(
            id: "orb",
            .name("glowing orb"),
            .description("A mysterious glowing orb."),
            .isTouched,  // Already touched
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: orb
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("touch orb")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > touch orb
            Your tactile investigation of the glowing orb yields no
            surprises.
            """
        )

        let finalState = await engine.item("orb")
        let wasTouched = await finalState.hasFlag(.isTouched)
        #expect(wasTouched == true)
    }

    @Test("Touch character produces character response")
    func testTouchCharacter() async throws {
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
        try await engine.execute("touch wizard")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > touch wizard
            Physical contact with the old wizard requires permission not
            yet granted.
            """
        )

        let finalWizard = await engine.item("wizard")
        let wasTouched = await finalWizard.hasFlag(.isTouched)
        #expect(wasTouched == true)
    }

    @Test("Touch enemy produces enemy response")
    func testTouchEnemy() async throws {
        // Given
        let game = MinimalGame(
            items: Lab.troll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("feel troll")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > feel troll
            Physical contact with the fierce troll requires permission not
            yet granted.
            """
        )

        let finalTroll = await engine.item("troll")
        let wasTouched = await finalTroll.hasFlag(.isTouched)
        #expect(wasTouched == true)
    }

    @Test("Touch self produces self response")
    func testTouchSelf() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("touch me")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > touch me
            Your hand meets your body. You remain stubbornly solid.
            """
        )
    }

    @Test("Cannot touch character not in scope")
    func testCannotTouchCharacterNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteWizard = Item(
            id: "remoteWizard",
            .name("remote wizard"),
            .description("A wizard in another room."),
            .characterSheet(.default),
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteWizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("touch wizard")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > touch wizard
            You cannot reach any such thing from here.
            """
        )
    }

    @Test("Cannot touch enemy not in scope")
    func testCannotTouchEnemyNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteTroll = Item(
            id: "remoteTroll",
            .name("remote troll"),
            .description("A troll in another room."),
            .characterSheet(
                CharacterSheet(isFighting: true)
            ),
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteTroll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("feel troll")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > feel troll
            You cannot reach any such thing from here.
            """
        )
    }

    @Test("Touch character in dark room requires light")
    func testTouchCharacterRequiresLight() async throws {
        // Given: Dark room with character
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .description("A wise old wizard."),
            .characterSheet(.wise),
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: wizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("touch wizard")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > touch wizard
            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.
            """
        )
    }

    @Test("Touch enemy in dark room requires light")
    func testTouchEnemyRequiresLight() async throws {
        // Given: Dark room with enemy
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: Lab.troll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("feel troll")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > feel troll
            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.
            """
        )
    }

    @Test("Touch character when carrying them")
    func testTouchCharacterWhenCarrying() async throws {
        // Given
        let fairy = Item(
            id: "fairy",
            .name("tiny fairy"),
            .description("A tiny magical fairy."),
            .characterSheet(.default),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: fairy
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("touch fairy")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > touch fairy
            Physical contact with the tiny fairy requires permission not
            yet granted.
            """
        )

        let finalFairy = await engine.item("fairy")
        let wasTouched = await finalFairy.hasFlag(.isTouched)
        #expect(wasTouched == true)
    }

    @Test("Touch multiple character types in sequence")
    func testTouchMultipleCharacterTypes() async throws {
        // Given
        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .description("A wise old wizard."),
            .characterSheet(.wise),
            .in(.startRoom)
        )

        let statue = Item(
            id: "statue",
            .name("marble statue"),
            .description("A cold marble statue."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: wizard, Lab.troll, statue
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute(
            "touch wizard",
            "feel troll",
            "touch statue"
        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > touch wizard
            Physical contact with the old wizard requires permission not
            yet granted.

            > feel troll
            Physical contact with the fierce troll requires permission not
            yet granted.

            > touch statue
            The marble statue feels exactly as it looks--solidly real and
            utterly ordinary.
            """
        )

        let wizardState = await engine.item("wizard")
        let trollState = await engine.item("troll")
        let statueState = await engine.item("statue")

        let wizardTouched = await wizardState.hasFlag(.isTouched)
        let trollTouched = await trollState.hasFlag(.isTouched)
        let statueTouched = await statueState.hasFlag(.isTouched)

        #expect(wizardTouched == true)
        #expect(trollTouched == true)
        #expect(statueTouched == true)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = TouchActionHandler()
        #expect(handler.synonyms.contains(.touch))
        #expect(handler.synonyms.contains(.feel))
        #expect(handler.synonyms.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = TouchActionHandler()
        #expect(handler.requiresLight == true)
    }
}
