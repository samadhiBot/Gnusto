import CustomDump
import Testing

@testable import GnustoEngine

@Suite("ExamineActionHandler Tests")
struct ExamineActionHandlerTests {
    @Test func testExamineSimpleItem() async throws {
        let itemID: ItemID = "pebble"
        let item = Item(
            id: itemID,
            name: "small pebble",
            description: "A smooth, grey pebble.",
            parent: .player
        )
        let game = MinimalGame(items: [item])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let initialItemState = await engine.item(itemID)
        #expect(initialItemState?.attributes[.isTouched] != true)
        #expect(await engine.gameState.changeHistory.isEmpty)

        let command = Command(
            verbID: VerbID("examine"),
            directObject: itemID,
            rawInput: "examine pebble"
        )
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "A smooth, grey pebble.")

        let finalItemState = await engine.item(itemID)
        #expect(finalItemState?.attributes[.isTouched] == true)

        let expectedChanges = expectedExamineChanges(
            itemID: itemID,
            initialAttributes: initialItemState?.attributes
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test func testExamineItemWithDetailedDescriptionHandler() async throws {
        let itemID: ItemID = "locket"
        let item = Item(
            id: itemID,
            name: "engraved locket",
            description: "A small, tarnished silver locket.",
            parent: .player
        )
        let game = MinimalGame(items: [item])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let initialItemState = await engine.item(itemID)
        #expect(initialItemState?.attributes[.isTouched] != true)
        #expect(await engine.gameState.changeHistory.isEmpty)

        let command = Command(verbID: VerbID("examine"), directObject: itemID, rawInput: "examine locket")
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "A small, tarnished silver locket.")

        let finalItemState = await engine.item(itemID)
        #expect(finalItemState?.attributes[.isTouched] == true)

        let expectedChanges = expectedExamineChanges(
            itemID: itemID,
            initialAttributes: initialItemState?.attributes
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test func testExamineItemInRoom() async throws {
        let itemID: ItemID = "statue"
        let roomID: LocationID = "garden"
        let item = Item(
            id: itemID,
            name: "stone statue",
            description: "A weathered statue of a grue.",
            parent: .location(roomID)
        )
        let room = Location(id: roomID, name: "Garden")
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
        let initialItemState = await engine.item(itemID)
        #expect(initialItemState?.attributes[.isTouched] != true)
        #expect(await engine.gameState.changeHistory.isEmpty)

        let command = Command(verbID: VerbID("examine"), directObject: itemID, rawInput: "examine statue")
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "A weathered statue of a grue.")

        let finalItemState = await engine.item(itemID)
        #expect(finalItemState?.attributes[.isTouched] == true)

        let expectedChanges = expectedExamineChanges(
            itemID: itemID,
            initialAttributes: initialItemState?.attributes
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test func testExamineItemNotInScope() async throws {
        let itemID: ItemID = "hiddenGem"
        let item = Item(
            id: itemID,
            name: "hidden gem",
            description: "Should not see this.",
            parent: .location("farAwayRoom")
        )
        let startRoom = Location(id: "startRoom", name: "Start Room")
        let farRoom = Location(id: "farAwayRoom", name: "Far Room")
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

        let command = Command(verbID: VerbID("examine"), directObject: itemID, rawInput: "examine hidden gem")
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "You see no hidden gem here.")

        #expect(await engine.gameState.changeHistory.isEmpty)
        let itemState = await engine.item(itemID)
        #expect(itemState?.attributes[.isTouched] != true)
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

        let command = Command(verbID: VerbID("examine"), directObject: itemID, rawInput: "examine ghost")
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "You see no ghost here.")

        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test func testExamineAmbiguousItem() async throws {
        let itemID1: ItemID = "redBall"
        let itemID2: ItemID = "blueBall"
        let item1 = Item(
            id: itemID1,
            name: "red ball",
            description: "A red ball.",
            parent: .player,
            attributes: [
                .adjectives: "red",
                .synonyms: "ball",
            ],
        )
        let item2 = Item(
            id: itemID2,
            name: "blue ball",
            description: "A blue ball.",
            parent: .player,
            attributes: [
                .adjectives: .stringSet(["blue"]),
                .synonyms: .stringSet(["ball"])
            ],
        )
        let game = MinimalGame(
            items: [item1, item2],
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
            verbID: VerbID("examine"),
            directObject: "ball",
            rawInput: "examine ball"
        )
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "Which ball do you mean, the red ball or the blue ball?")

        #expect(await engine.gameState.changeHistory.isEmpty)
        let item1State = await engine.item(itemID1)
        let item2State = await engine.item(itemID2)
        #expect(item1State?.attributes[.isTouched] != true)
        #expect(item2State?.attributes[.isTouched] != true)
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
            verbID: VerbID("examine"),
            directObject: "self",
            rawInput: "examine self"
        )
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "You are your usual self.")

        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test func testExamineItemWithObjectActionOverride() async throws {
        let itemID: ItemID = "magicMirror"
        let item = Item(
            id: itemID,
            name: "magic mirror",
            description: "A dusty old mirror.",
            parent: .player
        )
        let game = MinimalGame(
            items: [item],
            dynamicAttributeRegistry: DynamicAttributeRegistry()
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let initialItemState = await engine.item(itemID)
        #expect(initialItemState?.attributes[.isTouched] != true)
        #expect(await engine.gameState.changeHistory.isEmpty)

        let command = Command(verbID: VerbID("examine"), directObject: itemID, rawInput: "examine mirror")
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "A dusty old mirror.")

        #expect(await engine.gameState.changeHistory.isEmpty)
        let finalItemState = await engine.item(itemID)
        #expect(finalItemState?.attributes[.isTouched] != true)
    }
}

extension ExamineActionHandlerTests {
    private func expectedExamineChanges(
        itemID: ItemID,
        initialAttributes: [AttributeID: StateValue]?
    ) -> [StateChange] {
        var changes = [
            StateChange(
                entityID: .global,
                attributeKey: .pronounReference(pronoun: "it"),
                oldValue: nil,
                newValue: .itemIDSet([itemID])
            )
        ]
        if initialAttributes?[.isTouched] != true {
            changes.insert(
                StateChange(
                    entityID: .item(itemID),
                    attributeKey: .itemAttribute(.isTouched),
                    oldValue: initialAttributes?[.isTouched],
                    newValue: true,
                ), at: 0
            )
        }
        return changes
    }
}
