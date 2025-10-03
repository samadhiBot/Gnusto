import CustomDump
import Foundation
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("GameEngine Pronoun Update Tests")
struct GameEnginePronounTests {

    // MARK: - Basic Pronoun Update Tests

    @Test("examine command sets 'it' pronoun for single item")
    func testExamineCommandSetsItPronoun() async throws {
        let testItem = Item("testItem")
            .name("test item")
            .description("A simple test item.")
            .in(.startRoom)

        let game = MinimalGame(items: testItem)

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Examining an item
        try await engine.execute("examine test item")

        // Then: Pronoun should be set to refer to the item
        let pronoun = await engine.gameState.pronoun
        #expect(pronoun != nil)

        if case .it(let reference) = pronoun {
            #expect(reference == .item(testItem))
        } else {
            #expect(Bool(false), "Expected .it pronoun, got \(String(describing: pronoun))")
        }

        await mockIO.expect(
            """
            > examine test item
            A simple test item.
            """
        )
    }

    @Test("take command sets 'it' pronoun for single item")
    func testTakeCommandSetsItPronoun() async throws {
        let coin = Item("coin")
            .name("gold coin")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Taking an item
        try await engine.execute("take gold coin")

        // Then: Pronoun should be set to refer to the item
        let pronoun = await engine.gameState.pronoun
        #expect(pronoun != nil)

        if case .it(let reference) = pronoun {
            #expect(reference == .item(coin))
        } else {
            #expect(Bool(false), "Expected .it pronoun, got \(String(describing: pronoun))")
        }

        await mockIO.expect(
            """
            > take gold coin
            Taken.
            """
        )
    }

    @Test("commands with multiple objects set 'them' pronoun")
    func testMultipleObjectsSetThemPronoun() async throws {
        let coin1 = Item("coin1")
            .name("copper coin")
            .isTakable
            .in(.startRoom)

        let coin2 = Item("coin2")
            .name("silver coin")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: coin1, coin2
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Taking multiple items
        try await engine.execute("take copper coin and silver coin")

        // Then: Pronoun should be set to 'them' referring to both items
        let pronoun = await engine.gameState.pronoun
        #expect(pronoun != nil)

        if case .them(let references) = pronoun {
            #expect(references.contains(.item(coin1)))
            #expect(references.contains(.item(coin2)))
        } else {
            #expect(Bool(false), "Expected .them pronoun, got \(String(describing: pronoun))")
        }

        await mockIO.expect(
            """
            > take copper coin and silver coin
            You take the copper coin and the silver coin.
            """
        )
    }

    // MARK: - Pronoun Resolution Tests

    @Test("'it' pronoun resolves correctly in subsequent commands")
    func testItPronounResolution() async throws {
        let lamp = Item("lamp")
            .name("brass lamp")
            .description("A shiny brass lamp.")
            .isTakable
            .isLightSource
            .isDevice
            .in(.startRoom)

        let game = MinimalGame(
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Examining item then using 'it' pronoun
        try await engine.execute(
            "examine brass lamp",
            "take it",
            "turn it on"
        )

        // Then: All commands should work correctly
        await mockIO.expect(
            """
            > examine brass lamp
            A shiny brass lamp.

            > take it
            Taken.

            > turn it on
            You successfully turn on the brass lamp.
            """
        )

        // And: Final state should be correct
        let finalLamp = await lamp.proxy(engine)
        #expect(await finalLamp.parent == .player)
        #expect(await finalLamp.isProvidingLight)
    }

    @Test("'them' pronoun resolves correctly in subsequent commands")
    func testThemPronounResolution() async throws {
        let coin1 = Item("coin1")
            .name("copper coin")
            .isTakable
            .in(.startRoom)

        let coin2 = Item("coin2")
            .name("silver coin")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: coin1, coin2
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Examining multiple items then using 'them' pronoun
        try await engine.execute(
            "examine copper coin and silver coin",
            "take them"
        )

        // Then: Both commands should work
        await mockIO.expect(
            """
            > examine copper coin and silver coin
            - Copper coin: The copper coin reveals itself to be exactly
              what it appears -- nothing more, nothing less.
            - Silver coin: The silver coin stubbornly remains ordinary
              despite your thorough examination.

            > take them
            You take the copper coin and the silver coin.
            """
        )

        // And: Both items should be held by player
        let finalCoin1 = await engine.item(coin1.id)
        let finalCoin2 = await engine.item(coin2.id)
        #expect(await finalCoin1.parent == .player)
        #expect(await finalCoin2.parent == .player)
    }

    // MARK: - Pronoun Overwriting Tests

    @Test("new pronoun references overwrite previous ones")
    func testPronounOverwriting() async throws {
        let lamp = Item("lamp")
            .name("lamp")
            .description("A lamp.")
            .isTakable
            .in(.startRoom)

        let coin = Item("coin")
            .name("coin")
            .description("A coin.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: lamp, coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Examining first item, then second item
        try await engine.execute(
            "examine lamp",
            "examine coin",
            "take it"
        )  // Should take the coin

        // Then: "it" should refer to the most recently examined item
        await mockIO.expect(
            """
            > examine lamp
            A lamp.

            > examine coin
            A coin.

            > take it
            Taken.
            """
        )

        // And: Coin should be taken, lamp should remain in room
        let finalCoin = await engine.item(coin.id)
        let finalLamp = await engine.item(lamp.id)
        let startRoom = await engine.location(.startRoom)

        #expect(await finalCoin.parent == .player)
        #expect(await finalLamp.parent == .location(startRoom))

        // And: Final pronoun should refer to the coin
        let pronoun = await engine.gameState.pronoun
        if case .it(let reference) = pronoun {
            #expect(reference == .item(coin))
        } else {
            #expect(Bool(false), "Expected .it pronoun referring to coin")
        }
    }

    @Test("multiple objects overwrite single object pronouns")
    func testMultipleObjectsOverwriteSingle() async throws {
        let lamp = Item("lamp")
            .name("lamp")
            .isTakable
            .in(.startRoom)

        let coin1 = Item("coin1")
            .name("copper coin")
            .isTakable
            .in(.startRoom)

        let coin2 = Item("coin2")
            .name("silver coin")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: lamp, coin1, coin2
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: First examining single item, then multiple items
        try await engine.execute(
            "examine lamp",  // Sets 'it'
            "examine copper coin and silver coin",  // Sets 'them'
            "take them"  // Should work with 'them'
        )

        // Then: Commands should work correctly
        await mockIO.expect(
            """
            > examine lamp
            The lamp reveals itself to be exactly what it appears --
            nothing more, nothing less.

            > examine copper coin and silver coin
            - Copper coin: The copper coin stubbornly remains ordinary
              despite your thorough examination.
            - Silver coin: Your scrutiny of the silver coin yields no
              hidden depths or secret purposes.

            > take them
            You take the copper coin and the silver coin.
            """
        )

        // And: Pronoun should now be 'them' referring to the coins
        let pronoun = await engine.gameState.pronoun
        if case .them(let references) = pronoun {
            #expect(references.contains(.item(coin1)))
            #expect(references.contains(.item(coin2)))
        } else {
            #expect(Bool(false), "Expected .them pronoun referring to coins")
        }
    }

    // MARK: - Pronoun Clearing Tests

    @Test("commands with no direct objects clear pronouns")
    func testCommandsWithNoDirectObjectsClearPronouns() async throws {
        let testItem = Item("testItem")
            .name("test item")
            .in(.startRoom)

        let game = MinimalGame(items: testItem)

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: First setting a pronoun, then executing command with no objects
        try await engine.execute("examine test item")  // Sets pronoun

        // Verify pronoun is set
        let pronounAfterExamine = await engine.gameState.pronoun
        #expect(pronounAfterExamine != nil)

        try await engine.execute("look")  // No direct object - should clear pronoun

        // Then: Pronoun should be cleared
        let pronounAfterLook = await engine.gameState.pronoun
        #expect(pronounAfterLook == nil)

        await mockIO.expect(
            """
            > examine test item
            The test item reveals itself to be exactly what it appears --
            nothing more, nothing less.

            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            Present in this location is a test item.
            """
        )
    }

    // MARK: - Character Pronoun Tests

    @Test("female character sets female grammar gender")
    func testFemaleCharacterSetsFemaleGrammarGender() async throws {
        let game = MinimalGame(items: Lab.princess)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Examining a female character
        try await engine.execute("examine princess")

        // Then: Should set 'her' pronoun
        let pronoun = await engine.gameState.pronoun
        if case .her(let reference) = pronoun {
            #expect(reference == .item(Lab.princess))
        } else {
            #expect(Bool(false), "Expected .her pronoun, got \(String(describing: pronoun))")
        }

        await mockIO.expect(
            """
            > examine princess
            A beautiful princess.
            """
        )
    }

    @Test("male character sets 'him' pronoun")
    func testMaleCharacterSetsHimPronoun() async throws {
        let game = MinimalGame(items: Lab.knight)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Examining a male character
        try await engine.execute("examine knight")

        // Then: Should set 'him' pronoun
        let pronoun = await engine.gameState.pronoun
        if case .him(let reference) = pronoun {
            #expect(reference == .item(Lab.knight))
        } else {
            #expect(Bool(false), "Expected .him pronoun, got \(String(describing: pronoun))")
        }

        await mockIO.expect(
            """
            > examine knight
            A noble knight.
            """
        )
    }

    @Test("neuter character sets 'it' pronoun")
    func testNeuterCharacterSetsItPronoun() async throws {
        let golem = Item("golem")
            .name("stone golem")
            .description("A massive stone construct.")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: golem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Examining a neuter character
        try await engine.execute("examine stone golem")

        // Then: Should set 'it' pronoun
        let pronoun = await engine.gameState.pronoun
        if case .it(let reference) = pronoun {
            #expect(reference == .item(golem))
        } else {
            #expect(Bool(false), "Expected .it pronoun, got \(String(describing: pronoun))")
        }

        await mockIO.expect(
            """
            > examine stone golem
            A massive stone construct.
            """
        )
    }

    @Test("plural character sets 'them' pronoun")
    func testPluralCharacterSetsThemPronoun() async throws {
        let swarm = Item("swarm")
            .name("bee swarm")
            .description("A buzzing swarm of bees.")
            .characterSheet(.init(classification: .plural))
            .in(.startRoom)

        let game = MinimalGame(
            items: swarm
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Examining a plural character
        try await engine.execute("examine bee swarm")

        // Then: Should set 'them' pronoun
        let pronoun = await engine.gameState.pronoun
        if case .them(let references) = pronoun {
            #expect(references == [.item(swarm)])
        } else {
            #expect(Bool(false), "Expected .them pronoun, got \(String(describing: pronoun))")
        }

        await mockIO.expect(
            """
            > examine bee swarm
            A buzzing swarm of bees.
            """
        )
    }

    @Test("character gender pronouns work with mixed item types")
    func testCharacterGenderPronounsWithMixedItemTypes() async throws {
        let princess = Item("princess")
            .name("princess")
            .description("A beautiful princess.")
            .characterSheet(.init(classification: .feminine))
            .in(.startRoom)

        let knight = Item("knight")
            .name("knight")
            .description("A noble knight.")
            .characterSheet(.init(classification: .masculine))
            .in(.startRoom)

        let lamp = Item("lamp")
            .name("brass lamp")
            .description("A polished brass lamp.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: princess, knight, lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Examining characters with different genders and regular items
        try await engine.execute("examine princess")  // Sets 'her'
        try await engine.execute("examine knight")  // Sets 'him'
        try await engine.execute("examine lamp")  // Sets 'it'

        // Then: Final pronoun should be 'it' for the lamp
        let finalPronoun = await engine.gameState.pronoun
        if case .it(let reference) = finalPronoun {
            #expect(reference == .item(lamp))
        } else {
            #expect(Bool(false), "Expected .it pronoun referring to lamp")
        }

        await mockIO.expect(
            """
            > examine princess
            A beautiful princess.

            > examine knight
            A noble knight.

            > examine lamp
            A polished brass lamp.
            """
        )
    }

    @Test("plural item sets 'them' pronoun")
    func testPluralItemSetsThemPronoun() async throws {
        let grapes = Item("grapes")
            .name("grapes")
            .description("A bunch of purple grapes.")
            .isPlural
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: grapes
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Examining a plural item
        try await engine.execute("examine grapes")

        // Then: Should set 'them' pronoun (even for single plural item)
        let pronoun = await engine.gameState.pronoun
        if case .them(let references) = pronoun {
            #expect(references == [.item(grapes)])
        } else {
            #expect(Bool(false), "Expected .them pronoun, got \(String(describing: pronoun))")
        }

        await mockIO.expect(
            """
            > examine grapes
            A bunch of purple grapes.
            """
        )
    }

    // MARK: - Pronoun Resolution in Complex Scenarios

    @Test("pronoun resolution works with containers")
    func testPronounResolutionWithContainers() async throws {
        let box = Item("box")
            .name("wooden box")
            .description("A sturdy wooden box.")
            .isContainer
            .isOpenable
            .isOpen
            .in(.startRoom)

        let gem = Item("gem")
            .name("red gem")
            .description("A brilliant red gem.")
            .isTakable
            .in(.item("box"))

        let game = MinimalGame(
            items: box, gem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Examining container, then item inside, then using pronouns
        try await engine.execute(
            "examine box",
            "examine gem",
            "take it"
        )  // Should take the gem

        // Then: Commands should work correctly
        await mockIO.expect(
            """
            > examine box
            A sturdy wooden box. In the wooden box you can see a red gem.

            > examine gem
            A brilliant red gem.

            > take it
            Taken.
            """
        )

        // And: Gem should be held by player
        let finalGem = await engine.item(gem.id)
        #expect(await finalGem.parent == .player)

        // And: Pronoun should refer to the gem
        let pronoun = await engine.gameState.pronoun
        if case .it(let reference) = pronoun {
            #expect(reference == .item(gem))
        } else {
            #expect(Bool(false), "Expected .it pronoun referring to gem")
        }
    }

    @Test("pronoun persistence across multiple command types")
    func testPronounPersistenceAcrossCommandTypes() async throws {
        let book = Item("book")
            .name("ancient book")
            .description("An old leather-bound book.")
            .isTakable
            .isReadable
            .in(.startRoom)

        let game = MinimalGame(
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Using various command types with the same object
        try await engine.execute("examine ancient book")  // Sets pronoun
        try await engine.execute("take it")  // Uses pronoun
        try await engine.execute("read it")  // Uses pronoun again

        // Then: All commands should work
        await mockIO.expect(
            """
            > examine ancient book
            An old leather-bound book.

            > take it
            Taken.

            > read it
            The ancient book offers no text for your eager eyes to decode.
            """
        )

        // And: Book should be held by player
        let finalBook = await engine.item(book.id)
        #expect(await finalBook.parent == .player)
    }

    // MARK: - Edge Cases

    @Test("pronoun updates work when no objects initially present")
    func testPronounUpdatesWithNoInitialObjects() async throws {
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Executing command with no objects
        try await engine.execute("look")

        // Then: Pronoun should be cleared/nil
        let pronoun = await engine.gameState.pronoun
        #expect(pronoun == nil)
    }

    @Test("pronoun system handles disambiguation correctly")
    func testPronounSystemWithDisambiguation() async throws {
        let redBook = Item("redBook")
            .name("red book")
            .isTakable
            .in(.startRoom)

        let blueBook = Item("blueBook")
            .name("blue book")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: redBook, blueBook
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Using ambiguous command then clarifying
        try await engine.execute("examine book")  // Should trigger disambiguation
        try await engine.execute("the red book")  // Should clarify and set pronoun
        try await engine.execute("take it")  // Should take the red book

        // Then: Disambiguation and pronoun resolution should work
        await mockIO.expect(
            """
            > examine book
            Which do you mean: the blue book or the red book?

            > the red book
            The red book reveals itself to be exactly what it appears --
            nothing more, nothing less.

            > take it
            Got it.
            """
        )

        // And: Red book should be taken
        let finalRedBook = await engine.item(redBook.id)
        #expect(await finalRedBook.parent == .player)

        // And: Pronoun should refer to red book
        let pronoun = await engine.gameState.pronoun
        if case .it(let reference) = pronoun {
            #expect(reference == .item(redBook))
        } else {
            #expect(Bool(false), "Expected .it pronoun referring to red book")
        }
    }

    // MARK: - Pronoun Error Handling Tests

    @Test("using unset pronoun shows appropriate error")
    func testUsingUnsetPronoun() async throws {
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Using pronoun without setting it first
        try await engine.execute("take it")

        // Then: Should show appropriate error
        await mockIO.expect(
            """
            > take it
            I don't know what 'it' refers to.
            """
        )
    }

    @Test("using pronoun that refers to out-of-scope item")
    func testUsingPronounReferringToOutOfScopeItem() async throws {
        let room1 = Location("room1")
            .name("Room 1")
            .east("room2")
            .inherentlyLit

        let room2 = Location("room2")
            .name("Room 2")
            .west("room1")
            .inherentlyLit

        let item = Item("item")
            .name("test item")
            .description("A test item.")
            .isTakable
            .in("room1")

        let game = MinimalGame(
            player: Player(in: "room1"),
            locations: room1, room2,
            items: item
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Examining item in room1, then moving to room2, then using pronoun
        try await engine.execute("examine test item")  // Sets pronoun
        try await engine.execute("go east")  // Move to room2
        try await engine.execute("take it")  // Try to use pronoun

        // Then: Should show appropriate error since item is no longer in scope
        await mockIO.expect(
            """
            > examine test item
            A test item.

            > go east
            --- Room 2 ---

            This location is still under construction. The game developers
            apologize for any inconvenience.

            > take it
            I don't know what 'it' refers to.
            """
        )
    }

    // MARK: - Integration Tests

    @Test("complex pronoun scenario with multiple command types")
    func testComplexPronounScenario() async throws {
        let lamp = Item("lamp")
            .name("brass lamp")
            .description("A polished brass lamp.")
            .isTakable
            .isLightSource
            .isDevice
            .in(.startRoom)

        let coin1 = Item("coin1")
            .name("copper coin")
            .isTakable
            .in(.startRoom)

        let coin2 = Item("coin2")
            .name("silver coin")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: lamp, coin1, coin2
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Complex sequence of commands with different pronoun types
        try await engine.execute("examine lamp")  // Sets 'it' to lamp
        try await engine.execute("take it")  // Takes lamp
        try await engine.execute("examine copper coin and silver coin")  // Sets 'them' to coins
        try await engine.execute("take them")  // Takes both coins
        try await engine.execute("turn on lamp")  // Sets 'it' back to lamp
        try await engine.execute("examine it")  // Examines lamp

        // Then: All commands should work correctly
        await mockIO.expect(
            """
            > examine lamp
            A polished brass lamp.

            > take it
            Taken.

            > examine copper coin and silver coin
            - Copper coin: The copper coin stubbornly remains ordinary
              despite your thorough examination.
            - Silver coin: Your scrutiny of the silver coin yields no
              hidden depths or secret purposes.

            > take them
            You take the copper coin and the silver coin.

            > turn on lamp
            You successfully turn on the brass lamp.

            > examine it
            A polished brass lamp.
            """
        )

        // And: Final states should be correct
        let finalLamp = await engine.item(lamp.id)
        let finalCoin1 = await engine.item(coin1.id)
        let finalCoin2 = await engine.item(coin2.id)

        #expect(await finalLamp.parent == .player)
        #expect(await finalLamp.hasFlag(.isOn) == true)
        #expect(await finalCoin1.parent == .player)
        #expect(await finalCoin2.parent == .player)

        // And: Final pronoun should refer to lamp (last single object)
        let pronoun = await engine.gameState.pronoun
        if case .it(let reference) = pronoun {
            #expect(reference == .item(lamp))
        } else {
            #expect(Bool(false), "Expected .it pronoun referring to lamp")
        }
    }

    @Test("pronoun updates work across game saves and loads")
    func testPronounUpdatesAcrossSaveLoad() async throws {
        let testItem = Item("testItem")
            .name("test item")
            .description("A simple test item.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(items: testItem)

        let testHandler = TestFilesystemHandler()
        let (engine, _) = await GameEngine.test(
            blueprint: game,
            filesystemHandler: testHandler
        )

        // When: Setting pronoun, saving, then loading
        try await engine.execute("examine test item")  // Sets pronoun

        // Verify pronoun is set before save
        let pronounBeforeSave = await engine.gameState.pronoun
        #expect(pronounBeforeSave != nil)

        let saveURL = try await engine.saveGame(saveName: "pronoun_test")
        #expect(saveURL.gnustoPath == "~/Gnusto/MinimalGame/pronoun_test.gnusto")

        // Clear pronoun
        try await engine.execute("look")  // Clears pronoun
        #expect(await engine.gameState.pronoun == nil)

        // Restore
        try await engine.restoreGame(saveName: "pronoun_test")

        // Then: Pronoun should be restored
        let pronounAfterLoad = await engine.gameState.pronoun
        if case .it(let reference) = pronounAfterLoad {
            #expect(reference == .item(testItem))
        } else {
            #expect(Bool(false), "Expected .it pronoun with lamp reference")
        }
    }
}
