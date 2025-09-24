import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("TieActionHandler Tests")
struct TieActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("TIE DIRECTOBJECT syntax works")
    func testTieDirectObjectSyntax() async throws {
        // Given
        let rope = Item(
            id: "rope",
            .name("thick rope"),
            .description("A thick climbing rope."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: rope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie rope")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tie rope
            You can't tie the thick rope.
            """
        )

        let finalState = await engine.item("rope")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("TIE DIRECTOBJECT TO INDIRECTOBJECT syntax works")
    func testTieToSyntax() async throws {
        // Given
        let rope = Item(
            id: "rope",
            .name("long rope"),
            .description("A long rope."),
            .isTakable,
            .in(.startRoom)
        )

        let post = Item(
            id: "post",
            .name("wooden post"),
            .description("A sturdy wooden post."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: rope, post
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie rope to post")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tie rope to post
            You can't tie the wooden post to the wooden post.
            """
        )

        let finalRope = await engine.item("rope")
        let finalPost = await engine.item("post")
        #expect(await finalRope.hasFlag(.isTouched) == true)
        #expect(await finalPost.hasFlag(.isTouched) == true)
    }

    @Test("TIE DIRECTOBJECT WITH INDIRECTOBJECT syntax works")
    func testTieWithSyntax() async throws {
        // Given
        let box = Item(
            id: "box",
            .name("cardboard box"),
            .description("A simple cardboard box."),
            .isTakable,
            .in(.startRoom)
        )

        let string = Item(
            id: "string",
            .name("ball of string"),
            .description("A ball of string."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: box, string
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie box with string")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tie box with string
            You can't tie the cardboard box with the ball of string.
            """
        )
    }

    @Test("FASTEN syntax works")
    func testFastenSyntax() async throws {
        // Given
        let belt = Item(
            id: "belt",
            .name("leather belt"),
            .description("A leather belt."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: belt
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("fasten belt")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > fasten belt
            You can't tie the leather belt.
            """
        )
    }

    @Test("BIND syntax works")
    func testBindSyntax() async throws {
        // Given
        let package = Item(
            id: "package",
            .name("small package"),
            .description("A small package."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: package
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("bind package")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > bind package
            You can't tie the small package.
            """
        )
    }

    @Test("TIE UP DIRECTOBJECT syntax works")
    func testTieUpSyntax() async throws {
        // Given
        let rope = Item(
            id: "rope",
            .name("heavy rope"),
            .description("A heavy rope."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: rope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie up rope")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tie up rope
            You can't tie the heavy rope.
            """
        )
    }

    @Test("TIE UP DIRECTOBJECT WITH INDIRECTOBJECT syntax works")
    func testTieUpWithSyntax() async throws {
        // Given
        let package = Item(
            id: "package",
            .name("gift package"),
            .description("A gift package."),
            .isTakable,
            .in(.startRoom)
        )

        let ribbon = Item(
            id: "ribbon",
            .name("silk ribbon"),
            .description("A silk ribbon."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: package, ribbon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie up package with ribbon")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tie up package with ribbon
            You can't tie the gift package with the silk ribbon.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot tie without specifying what")
    func testCannotTieWithoutWhat() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tie
            Tie what?
            """
        )
    }

    @Test("Cannot tie item not in scope")
    func testCannotTieItemNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteRope = Item(
            id: "remoteRope",
            .name("remote rope"),
            .description("A rope in another room."),
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteRope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie rope")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tie rope
            Any such thing remains frustratingly inaccessible.
            """
        )
    }

    @Test("Cannot tie to item not in scope")
    func testCannotTieToItemNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let rope = Item(
            id: "rope",
            .name("long rope"),
            .description("A long rope."),
            .in(.startRoom)
        )

        let remotePost = Item(
            id: "remotePost",
            .name("remote post"),
            .description("A post in another room."),
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: rope, remotePost
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie rope to post")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tie rope to post
            Any such thing remains frustratingly inaccessible.
            """
        )
    }

    @Test("Requires light to tie")
    func testRequiresLight() async throws {
        // Given: Dark room with rope
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let rope = Item(
            id: "rope",
            .name("thick rope"),
            .description("A thick rope."),
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: rope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie rope")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tie rope
            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Tie character produces character response")
    func testTieCharacter() async throws {
        // Given
        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .description("A wise old wizard."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: wizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie wizard")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tie wizard
            The old wizard's freedom is not yours to restrict with rope.
            """
        )

        // Verify character was touched
        let finalWizard = await engine.item("wizard")
        let wasTouched = await finalWizard.hasFlag(.isTouched)
        #expect(wasTouched == true)
    }

    @Test("Tie enemy produces enemy response")
    func testTieEnemy() async throws {
        // Given
        let game = MinimalGame(
            items: Lab.troll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie troll")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tie troll
            The fierce troll's freedom is not yours to restrict with rope.
            """
        )

        let finalTroll = await engine.item("troll")
        #expect(await finalTroll.hasFlag(.isTouched) == true)
    }

    @Test("Tie character to object produces character response")
    func testTieCharacterToObject() async throws {
        // Given
        let castleGuard = Item(
            id: "guard",
            .name("castle guard"),
            .description("A stern castle guard."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let post = Item(
            id: "post",
            .name("wooden post"),
            .description("A sturdy wooden post."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: castleGuard, post
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie guard to post")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tie guard to post
            You can't tie the wooden post to the wooden post.
            """
        )

        let finalGuard = await engine.item("guard")
        let finalPost = await engine.item("post")
        let guardTouched = await finalGuard.hasFlag(.isTouched)
        let postTouched = await finalPost.hasFlag(.isTouched)
        #expect(guardTouched == true)
        #expect(postTouched == true)
    }

    @Test("Tie enemy with rope produces enemy response")
    func testTieEnemyWithRope() async throws {
        // Given
        let orc = Item(
            id: "orc",
            .name("angry orc"),
            .description("An angry orc warrior."),
            .characterSheet(.init(isFighting: true)),
            .in(.startRoom)
        )

        let rope = Item(
            id: "rope",
            .name("strong rope"),
            .description("A strong rope."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: orc, rope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie orc with rope")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tie orc with rope
            Your rope would need to overcome the angry orc's violent
            objections first.

            The warrior attacks with pure murderous intent! You brace
            yourself for the impact, guard up, ready for the worst kind of
            fight.
            """
        )

        let finalOrc = await engine.item("orc")
        let finalRope = await engine.item("rope")
        #expect(await finalOrc.hasFlag(.isTouched) == true)
        #expect(await finalRope.hasFlag(.isTouched) == true)
    }

    @Test("Tie up character with rope produces character response")
    func testTieUpCharacterWithRope() async throws {
        // Given
        let merchant = Item(
            id: "merchant",
            .name("traveling merchant"),
            .description("A traveling merchant."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let rope = Item(
            id: "rope",
            .name("coarse rope"),
            .description("A coarse rope."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: merchant, rope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie up merchant with rope")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tie up merchant with rope
            The traveling merchant's freedom is not yours to restrict with
            rope.
            """
        )

        let finalMerchant = await engine.item("merchant")
        let finalRope = await engine.item("rope")
        #expect(await finalMerchant.hasFlag(.isTouched) == true)
        #expect(await finalRope.hasFlag(.isTouched) == true)
    }

    @Test("Cannot tie character to itself")
    func testCannotTieCharacterToItself() async throws {
        // Given
        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .description("A wise old wizard."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: wizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie wizard to wizard")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tie wizard to wizard
            You can't tie the old wizard to itself.
            """
        )
    }

    @Test("Cannot tie enemy to itself")
    func testCannotTieEnemyToItself() async throws {
        // Given
        let game = MinimalGame(
            items: Lab.troll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie troll to troll")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tie troll to troll
            You can't tie the fierce troll to itself.
            """
        )
    }

    @Test("Cannot tie character with itself")
    func testCannotTieCharacterWithItself() async throws {
        // Given
        let castleGuard = Item(
            id: "guard",
            .name("castle guard"),
            .description("A stern castle guard."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: castleGuard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie guard with guard")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tie guard with guard
            You can't tie the castle guard with itself.
            """
        )
    }

    @Test("Cannot tie enemy with itself")
    func testCannotTieEnemyWithItself() async throws {
        // Given
        let orc = Item(
            id: "orc",
            .name("angry orc"),
            .description("An angry orc warrior."),
            .characterSheet(
                CharacterSheet(isFighting: true)
            ),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: orc
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie orc with orc")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tie orc with orc
            You can't tie the angry orc with itself.

            The warrior attacks with pure murderous intent! You brace
            yourself for the impact, guard up, ready for the worst kind of
            fight.
            """
        )
    }

    @Test("Cannot tie character not in scope")
    func testCannotTieCharacterNotInScope() async throws {
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
        try await engine.execute("tie wizard")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tie wizard
            Any such thing remains frustratingly inaccessible.
            """
        )
    }

    @Test("Cannot tie enemy not in scope")
    func testCannotTieEnemyNotInScope() async throws {
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
        try await engine.execute("tie troll")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tie troll
            Any such thing remains frustratingly inaccessible.
            """
        )
    }

    @Test("Tie character to character produces target character response")
    func testTieCharacterToCharacter() async throws {
        // Given
        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .description("A wise old wizard."),
            .characterSheet(.wise),
            .in(.startRoom)
        )

        let castleGuard = Item(
            id: "guard",
            .name("castle guard"),
            .description("A stern castle guard."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: wizard, castleGuard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie wizard to guard")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tie wizard to guard
            The castle guard's freedom is not yours to restrict with rope.
            """
        )

        let finalWizard = await engine.item("wizard")
        let finalGuard = await engine.item("guard")
        #expect(await finalWizard.hasFlag(.isTouched) == true)
        #expect(await finalGuard.hasFlag(.isTouched) == true)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = TieActionHandler()
        #expect(handler.synonyms.contains(.tie))
        #expect(handler.synonyms.contains(.fasten))
        #expect(handler.synonyms.contains(.bind))
        #expect(handler.synonyms.count == 3)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = TieActionHandler()
        #expect(handler.requiresLight == true)
    }
}
