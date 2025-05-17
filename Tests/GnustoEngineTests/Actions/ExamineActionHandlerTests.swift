import CustomDump
import Testing

@testable import GnustoEngine

@Suite("ExamineActionHandler Tests")
struct ExamineActionHandlerTests {
    @Test func testExamineSimpleItem() async throws {
        let itemID: ItemID = "pebble"
        let item = Item(
            id: itemID,
            .name("small pebble"),
            .description("A smooth, grey pebble."),
            .in(.player)
        )
        let game = MinimalGame(items: [item])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let initialItemState = try await engine.item(itemID)
        #expect(initialItemState.attributes[.isTouched] != true)
        #expect(await engine.gameState.changeHistory.isEmpty)

        let command = Command(
            verb: .examine,
            directObject: .item(itemID),
            rawInput: "examine pebble"
        )
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "A smooth, grey pebble.")

        let finalItemState = try await engine.item(itemID)
        #expect(finalItemState.attributes[.isTouched] == true)

        let expectedChanges = expectedExamineChanges(
            itemID: itemID,
            initialAttributes: initialItemState.attributes
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test func testExamineItemWithDetailedDescriptionHandler() async throws {
        let itemID: ItemID = "locket"
        let item = Item(
            id: itemID,
            .name("engraved locket"),
            .description("A small, tarnished silver locket."),
            .in(.player)
        )
        let game = MinimalGame(items: [item])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let initialItemState = try await engine.item(itemID)
        #expect(initialItemState.attributes[.isTouched] != true)
        #expect(await engine.gameState.changeHistory.isEmpty)

        let command = Command(
            verb: .examine,
            directObject: .item(itemID),
            rawInput: "examine locket"
        )
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "A small, tarnished silver locket.")

        let finalItemState = try await engine.item(itemID)
        #expect(finalItemState.attributes[.isTouched] == true)

        let expectedChanges = expectedExamineChanges(
            itemID: itemID,
            initialAttributes: initialItemState.attributes
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test func testExamineItemInRoom() async throws {
        let itemID: ItemID = "statue"
        let roomID: LocationID = "garden"
        let item = Item(
            id: itemID,
            .name("stone statue"),
            .description("A weathered statue of a grue."),
            .in(.location(roomID))
        )
        let room = Location(
            id: roomID,
            .name("Garden"),
            .inherentlyLit
        )
        let game = MinimalGame(
            player: Player(in: roomID),
            locations: [room],
            items: [item]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let initialItemState = try await engine.item(itemID)
        #expect(initialItemState.attributes[.isTouched] != true)
        #expect(await engine.gameState.changeHistory.isEmpty)

        let command = Command(
            verb: .examine,
            directObject: .item(itemID),
            rawInput: "examine statue"
        )
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "A weathered statue of a grue.")

        let finalItemState = try await engine.item(itemID)
        #expect(finalItemState.attributes[.isTouched] == true)

        let expectedChanges = expectedExamineChanges(
            itemID: itemID,
            initialAttributes: initialItemState.attributes
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test func testExamineItemNotInScope() async throws {
        let itemID: ItemID = "hiddenGem"
        let item = Item(
            id: itemID,
            .name("hidden gem"),
            .description("Should not see this."),
            .in(.location("farAwayRoom"))
        )
        let startRoom = Location(
            id: .startRoom,
            .name("Start Room"),
            .inherentlyLit
        )
        let farRoom = Location(
            id: "farAwayRoom",
            .name("Far Room"),
            .inherentlyLit
        )
        let game = MinimalGame(
            locations: [startRoom, farRoom],
            items: [item],
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty)

        let command = Command(
            verb: .examine,
            directObject: .item(itemID),
            rawInput: "examine hidden gem"
        )
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t see any such thing.")

        #expect(await engine.gameState.changeHistory.isEmpty)
        let itemState = try await engine.item(itemID)
        #expect(itemState.attributes[.isTouched] != true)
    }

    @Test func testExamineTouchedItemNotInScope() async throws {
        let itemID: ItemID = "hiddenGem"
        let item = Item(
            id: itemID,
            .name("hidden gem"),
            .description("Should not see this."),
            .in(.location("farAwayRoom")),
            .isTouched
        )
        let startRoom = Location(
            id: .startRoom,
            .name("Start Room"),
            .inherentlyLit
        )
        let farRoom = Location(
            id: "farAwayRoom",
            .name("Far Room"),
            .inherentlyLit
        )
        let game = MinimalGame(
            locations: [startRoom, farRoom],
            items: [item],
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty)

        let command = Command(
            verb: .examine,
            directObject: .item(itemID),
            rawInput: "examine hidden gem"
        )
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t see the hidden gem.")

        #expect(await engine.gameState.changeHistory.isEmpty)
        let itemState = try await engine.item(itemID)
        #expect(itemState.attributes[.isTouched] == true)
    }

    @Test func testExamineNonExistentItem() async throws {
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let itemID: ItemID = "ghost"
        #expect(await engine.gameState.changeHistory.isEmpty)

        let command = Command(
            verb: .examine,
            directObject: .item(itemID),
            rawInput: "examine ghost"
        )
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t see any such thing.")

        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test func testExamineAmbiguousItem() async throws {
        let itemID1: ItemID = "redBall"
        let itemID2: ItemID = "blueBall"
        let item1 = Item(
            id: itemID1,
            .name("red ball"),
            .description("A red ball."),
            .in(.player),
            .adjectives("red"),
            .synonyms("ball")
        )
        let item2 = Item(
            id: itemID2,
            .name("blue ball"),
            .description("A blue ball."),
            .in(.player),
            .adjectives("blue"),
            .synonyms("ball")
        )
        let game = MinimalGame(
            items: [item1, item2],
        )
        let mockIO = await MockIOHandler()
        let parser = StandardParser()
        let engine = await GameEngine(
            game: game,
            parser: parser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        // Parse the raw input first
        let parseResult = parser.parse(
            input: "examine ball",
            vocabulary: await engine.gameState.vocabulary,
            gameState: await engine.gameState
        )

        // Assert
        #expect(
            throws: ParseError.ambiguity("Which do you mean: the blue ball or the red ball?")
        ) {
            try parseResult.get()
        }
    }

    @Test func testExamineSelf() async throws {
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty)

        let command = Command(
            verb: .examine,
            directObject: .player,
            rawInput: "examine self"
        )
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "You are your usual self.")

        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test func testExamineItemWithObjectActionOverride() async throws {
        let item = Item(
            id: "magicMirror",
            .name("magic mirror"),
            .description("A dusty old mirror."),
            .in(.player)
        )
        let definitionRegistry = DefinitionRegistry(
            itemActionHandlers: [
                "magicMirror": { engine, command in
                    ActionResult("You see your reflection in the magic mirror.")
                }
            ]
        )
        let game = MinimalGame(
            items: [item],
            definitionRegistry: definitionRegistry
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let initialItemState = try await engine.item("magicMirror")
        #expect(initialItemState.attributes[.isTouched] != true)
        #expect(await engine.gameState.changeHistory.isEmpty)

        let command = Command(
            verb: .examine,
            directObject: .item(item.id),
            rawInput: "examine mirror"
        )
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "You see your reflection in the magic mirror.")

        #expect(await engine.gameState.changeHistory.isEmpty)
        let finalItemState = try await engine.item("magicMirror")
        #expect(finalItemState.attributes[.isTouched] != true)
    }
}

extension ExamineActionHandlerTests {
    private func expectedExamineChanges(
        itemID: ItemID,
        initialAttributes: [AttributeID: StateValue]
    ) -> [StateChange] {
        var changes: [StateChange] = []

        // Item is touched
        if initialAttributes[.isTouched] != true {
            changes.append(
                StateChange(
                    entityID: .item(itemID),
                    attributeKey: .itemAttribute(.isTouched),
                    oldValue: nil,
                    newValue: true
                )
            )
        }

        // Pronoun "it" is set to this item
        // TODO: This might need to be more sophisticated if "them" is possible
        // or if the existing pronoun was different.
        changes.append(
            StateChange(
                entityID: .global,
                attributeKey: .pronounReference(pronoun: "it"),
                // Old value might be nil or another item, for simplicity in test we assume nil or different
                // A more robust test might capture the actual old pronoun state.
                oldValue: nil, // Assuming it wasn’t set or was different
                newValue: .entityReferenceSet([.item(itemID)]) // Use .entityReferenceSet
            )
        )
        return changes
    }
}
