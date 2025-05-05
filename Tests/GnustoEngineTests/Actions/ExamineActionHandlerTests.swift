import GnustoEngine
import Testing
import CustomDump
@testable import GnustoEngine

@MainActor
@Suite("ExamineActionHandler Tests")
struct ExamineActionHandlerTests {
    private func expectedExamineChanges(
        itemID: ItemID,
        initialAttributes: [AttributeID: StateValue]?
    ) -> [StateChange] {
        var changes: [StateChange] = []

        if initialAttributes?[.isTouched] != .bool(true) {
            changes.append(
                StateChange(
                    entityId: .item(itemID),
                    propertyKey: .itemAttribute(.isTouched),
                    oldValue: initialAttributes?[.isTouched] ?? .bool(false),
                    newValue: true,
                )
            )
        }

        changes.append(
             StateChange(
                 entityId: .global,
                 propertyKey: .pronounReference(pronoun: "it"),
                 oldValue: nil,
                 newValue: .itemIDSet([itemID])
             )
        )
        return changes
    }

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
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let initialItemState = engine.item(itemID)
        #expect(initialItemState?.hasFlag(.isTouched) == false)
        #expect(engine.gameState.changeHistory.isEmpty)

        let command = Command(verbID: VerbID("examine"), directObject: itemID, rawInput: "examine pebble")
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "A smooth, grey pebble.")

        let finalItemState = engine.item(itemID)
        #expect(finalItemState?.hasFlag(.isTouched) == true)

        let expectedChanges = expectedExamineChanges(
            itemID: itemID,
            initialAttributes: initialItemState?.attributes
        )
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test func testExamineItemWithDetailedDescriptionHandler() async throws {
        let itemID: ItemID = "locket"
        let item = Item(
            id: itemID,
            name: "engraved locket",
            description: "A small, tarnished silver locket.",
            attributes: [
                .descriptionHandlerID: handlerID
            ]
        )
        let descriptionHandler: DescriptionHandler = { _, itemSnapshot, _, _ in
            "The locket is intricately engraved with the initials \"A.S\"."
        }
        let registry = DefinitionRegistry(
            descriptionHandlers: [handlerID: descriptionHandler]
        )
        let game = MinimalGame(items: [item], initialPlayerInventory: [itemID])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO,
            definitionRegistry: registry
        )
        let initialItemState = engine.item(itemID)
        #expect(initialItemState?.hasFlag(.isTouched) == false)
        #expect(engine.gameState.changeHistory.isEmpty)

        let command = Command(verbID: VerbID("examine"), directObject: itemID, rawInput: "examine locket")
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "The locket is intricately engraved with the initials \"A.S\".")

        let finalItemState = engine.item(itemID)
        #expect(finalItemState?.hasFlag(.isTouched) == true)

        let expectedChanges = expectedExamineChanges(
            itemID: itemID,
            initialAttributes: initialItemState?.attributes
        )
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
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
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let initialItemState = engine.item(itemID)
        #expect(initialItemState?.hasFlag(.isTouched) == false)
        #expect(engine.gameState.changeHistory.isEmpty)

        let command = Command(verbID: VerbID("examine"), directObject: itemID, rawInput: "examine statue")
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "A weathered statue of a grue.")

        let finalItemState = engine.item(itemID)
        #expect(finalItemState?.hasFlag(.isTouched) == true)

        let expectedChanges = expectedExamineChanges(
            itemID: itemID,
            initialAttributes: initialItemState?.attributes
        )
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
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
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty)

        let command = Command(verbID: VerbID("examine"), directObject: itemID, rawInput: "examine hidden gem")
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "You see no hidden gem here.")

        #expect(engine.gameState.changeHistory.isEmpty)
        #expect(await engine.item(itemID)?.hasFlag(.isTouched) == false)
    }

    @Test func testExamineNonExistentItem() async throws {
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let itemID: ItemID = "ghost"
        #expect(engine.gameState.changeHistory.isEmpty)

        let command = Command(verbID: VerbID("examine"), directObject: itemID, rawInput: "examine ghost")
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "You see no ghost here.")

        #expect(engine.gameState.changeHistory.isEmpty)
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
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty)

        let command = Command(
            verbID: VerbID("examine"),
            directObject: "ball",
            rawInput: "examine ball"
        )
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "Which ball do you mean, the red ball or the blue ball?")

        #expect(engine.gameState.changeHistory.isEmpty)
        #expect(await engine.item(itemID1)?.hasFlag(.isTouched) == false)
        #expect(await engine.item(itemID2)?.hasFlag(.isTouched) == false)
    }

    @Test func testExamineSelf() async throws {
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty)

        let command = Command(
            verbID: VerbID("examine"),
            directObject: "self",
            rawInput: "examine self"
        )
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "You are your usual self.")

        #expect(engine.gameState.changeHistory.isEmpty)
    }

    @Test func testExamineItemWithObjectActionOverride() async throws {
        let itemID: ItemID = "magicMirror"
        let item = Item(
            id: itemID,
            name: "magic mirror",
            description: "A dusty old mirror.",
            parent: .player
        )
//        var dynamicPropertyRegistry = DynamicPropertyRegistry()
//        dynamicPropertyRegistry.registerItemCompute(key: <#T##AttributeID#>, handler: <#T##DynamicPropertyRegistry.ItemComputeHandler##DynamicPropertyRegistry.ItemComputeHandler##(Item, GameState) async throws -> StateValue#>)
//        let objectHandler: ObjectActionHandler = { command, context, itemID, io, engine in
//            guard command.verbID == VerbID("examine") else { return .objectAction(.notHandled) }
//            await io.print("The mirror shows a faint, ghostly image.")
//            return .objectAction(.handled(ActionResult.empty))
//        }
//        let registry = DefinitionRegistry(
//            objectActionHandlers: [itemID: objectHandler]
//        )
        let game = MinimalGame(
            items: [item],
            dynamicPropertyRegistry: DynamicPropertyRegistry()
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let initialItemState = engine.item(itemID)
        #expect(initialItemState?.hasFlag(.isTouched) == false)
        #expect(engine.gameState.changeHistory.isEmpty)

        let command = Command(verbID: VerbID("examine"), directObject: itemID, rawInput: "examine mirror")
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "The mirror shows a faint, ghostly image.")

        #expect(engine.gameState.changeHistory.isEmpty)
        #expect(await engine.item(itemID)?.hasFlag(.isTouched) == false)
    }
}
