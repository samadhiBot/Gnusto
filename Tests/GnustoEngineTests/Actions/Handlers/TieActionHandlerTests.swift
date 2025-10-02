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
        let rope = Item("rope")
            .name("thick rope")
            .description("A thick climbing rope.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: rope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie rope")

        // Then
        await mockIO.expectOutput(
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
        let rope = Item("rope")
            .name("long rope")
            .description("A long rope.")
            .isTakable
            .in(.startRoom)

        let post = Item("post")
            .name("wooden post")
            .description("A sturdy wooden post.")
            .in(.startRoom)

        let game = MinimalGame(
            items: rope, post
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie rope to post")

        // Then
        await mockIO.expectOutput(
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
        let box = Item("box")
            .name("cardboard box")
            .description("A simple cardboard box.")
            .isTakable
            .in(.startRoom)

        let string = Item("string")
            .name("ball of string")
            .description("A ball of string.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: box, string
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie box with string")

        // Then
        await mockIO.expectOutput(
            """
            > tie box with string
            You can't tie the cardboard box with the ball of string.
            """
        )
    }

    @Test("FASTEN syntax works")
    func testFastenSyntax() async throws {
        // Given
        let belt = Item("belt")
            .name("leather belt")
            .description("A leather belt.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: belt
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("fasten belt")

        // Then
        await mockIO.expectOutput(
            """
            > fasten belt
            You can't tie the leather belt.
            """
        )
    }

    @Test("BIND syntax works")
    func testBindSyntax() async throws {
        // Given
        let package = Item("package")
            .name("small package")
            .description("A small package.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: package
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("bind package")

        // Then
        await mockIO.expectOutput(
            """
            > bind package
            You can't tie the small package.
            """
        )
    }

    @Test("TIE UP DIRECTOBJECT syntax works")
    func testTieUpSyntax() async throws {
        // Given
        let rope = Item("rope")
            .name("heavy rope")
            .description("A heavy rope.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: rope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie up rope")

        // Then
        await mockIO.expectOutput(
            """
            > tie up rope
            You can't tie the heavy rope.
            """
        )
    }

    @Test("TIE UP DIRECTOBJECT WITH INDIRECTOBJECT syntax works")
    func testTieUpWithSyntax() async throws {
        // Given
        let package = Item("package")
            .name("gift package")
            .description("A gift package.")
            .isTakable
            .in(.startRoom)

        let ribbon = Item("ribbon")
            .name("silk ribbon")
            .description("A silk ribbon.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: package, ribbon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie up package with ribbon")

        // Then
        await mockIO.expectOutput(
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
        await mockIO.expectOutput(
            """
            > tie
            Tie what?
            """
        )
    }

    @Test("Cannot tie item not in scope")
    func testCannotTieItemNotInScope() async throws {
        // Given
        let anotherRoom = Location("anotherRoom")
            .name("Another Room")
            .inherentlyLit

        let remoteRope = Item("remoteRope")
            .name("remote rope")
            .description("A rope in another room.")
            .in("anotherRoom")

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteRope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie rope")

        // Then
        await mockIO.expectOutput(
            """
            > tie rope
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot tie to item not in scope")
    func testCannotTieToItemNotInScope() async throws {
        // Given
        let anotherRoom = Location("anotherRoom")
            .name("Another Room")
            .inherentlyLit

        let rope = Item("rope")
            .name("long rope")
            .description("A long rope.")
            .in(.startRoom)

        let remotePost = Item("remotePost")
            .name("remote post")
            .description("A post in another room.")
            .in("anotherRoom")

        let game = MinimalGame(
            locations: anotherRoom,
            items: rope, remotePost
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie rope to post")

        // Then
        await mockIO.expectOutput(
            """
            > tie rope to post
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Requires light to tie")
    func testRequiresLight() async throws {
        // Given: Dark room with rope
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")
        // Note: No .inherentlyLit property

        let rope = Item("rope")
            .name("thick rope")
            .description("A thick rope.")
            .in("darkRoom")

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: rope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie rope")

        // Then
        await mockIO.expectOutput(
            """
            > tie rope
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Tie character produces character response")
    func testTieCharacter() async throws {
        // Given
        let wizard = Item("wizard")
            .name("old wizard")
            .description("A wise old wizard.")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: wizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie wizard")

        // Then
        await mockIO.expectOutput(
            """
            > tie wizard
            Binding the old wizard would transform you from adventurer to
            kidnapper.
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
        await mockIO.expectOutput(
            """
            > tie troll
            Binding the fierce troll would transform you from adventurer to
            kidnapper.
            """
        )

        let finalTroll = await engine.item("troll")
        #expect(await finalTroll.hasFlag(.isTouched) == true)
    }

    @Test("Tie character to object produces character response")
    func testTieCharacterToObject() async throws {
        // Given
        let castleGuard = Item("guard")
            .name("castle guard")
            .description("A stern castle guard.")
            .characterSheet(.default)
            .in(.startRoom)

        let post = Item("post")
            .name("wooden post")
            .description("A sturdy wooden post.")
            .in(.startRoom)

        let game = MinimalGame(
            items: castleGuard, post
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie guard to post")

        // Then
        await mockIO.expectOutput(
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
        let orc = Item("orc")
            .name("angry orc")
            .description("An angry orc warrior.")
            .characterSheet(.init(isFighting: true))
            .in(.startRoom)

        let rope = Item("rope")
            .name("strong rope")
            .description("A strong rope.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: orc, rope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie orc with rope")

        // Then
        await mockIO.expectOutput(
            """
            > tie orc with rope
            The angry orc would resist binding with extreme prejudice.
            
            No weapons between you--just the warrior's aggression and your
            desperation! You collide in a tangle of strikes and blocks.
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
        let merchant = Item("merchant")
            .name("traveling merchant")
            .description("A traveling merchant.")
            .characterSheet(.default)
            .in(.startRoom)

        let rope = Item("rope")
            .name("coarse rope")
            .description("A coarse rope.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: merchant, rope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie up merchant with rope")

        // Then
        await mockIO.expectOutput(
            """
            > tie up merchant with rope
            Binding the traveling merchant would transform you from
            adventurer to kidnapper.
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
        let wizard = Item("wizard")
            .name("old wizard")
            .description("A wise old wizard.")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: wizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie wizard to wizard")

        // Then
        await mockIO.expectOutput(
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
        await mockIO.expectOutput(
            """
            > tie troll to troll
            You can't tie the fierce troll to itself.
            """
        )
    }

    @Test("Cannot tie character with itself")
    func testCannotTieCharacterWithItself() async throws {
        // Given
        let castleGuard = Item("guard")
            .name("castle guard")
            .description("A stern castle guard.")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: castleGuard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie guard with guard")

        // Then
        await mockIO.expectOutput(
            """
            > tie guard with guard
            You can't tie the castle guard with itself.
            """
        )
    }

    @Test("Cannot tie enemy with itself")
    func testCannotTieEnemyWithItself() async throws {
        // Given
        let orc = Item("orc")
            .name("angry orc")
            .description("An angry orc warrior.")
            .characterSheet(
                CharacterSheet(isFighting: true)
            )
            .in(.startRoom)

        let game = MinimalGame(
            items: orc
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie orc with orc")

        // Then
        await mockIO.expectOutput(
            """
            > tie orc with orc
            You can't tie the angry orc with itself.
            
            No weapons between you--just the warrior's aggression and your
            desperation! You collide in a tangle of strikes and blocks.
            """
        )
    }

    @Test("Cannot tie character not in scope")
    func testCannotTieCharacterNotInScope() async throws {
        // Given
        let anotherRoom = Location("anotherRoom")
            .name("Another Room")
            .inherentlyLit

        let remoteWizard = Item("remoteWizard")
            .name("remote wizard")
            .description("A wizard in another room.")
            .characterSheet(.default)
            .in("anotherRoom")

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteWizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie wizard")

        // Then
        await mockIO.expectOutput(
            """
            > tie wizard
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot tie enemy not in scope")
    func testCannotTieEnemyNotInScope() async throws {
        // Given
        let anotherRoom = Location("anotherRoom")
            .name("Another Room")
            .inherentlyLit

        let remoteTroll = Item("remoteTroll")
            .name("remote troll")
            .description("A troll in another room.")
            .characterSheet(
                CharacterSheet(isFighting: true)
            )
            .in("anotherRoom")

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteTroll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie troll")

        // Then
        await mockIO.expectOutput(
            """
            > tie troll
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Tie character to character produces target character response")
    func testTieCharacterToCharacter() async throws {
        // Given
        let wizard = Item("wizard")
            .name("old wizard")
            .description("A wise old wizard.")
            .characterSheet(.wise)
            .in(.startRoom)

        let castleGuard = Item("guard")
            .name("castle guard")
            .description("A stern castle guard.")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: wizard, castleGuard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie wizard to guard")

        // Then
        await mockIO.expectOutput(
            """
            > tie wizard to guard
            Binding the castle guard would transform you from adventurer to
            kidnapper.
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
