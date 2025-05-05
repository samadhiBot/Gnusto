import GnustoEngine
import Testing
import CustomDump

@Suite("ExamineActionHandler Tests")
struct ExamineActionHandlerTests {
    @Test func testExamineSimpleItem() async throws {
        // Arrange
        let itemID: ItemID = "pebble"
        let item = Item(id: itemID, name: "small pebble", longDescription: "A smooth, grey pebble.")
        let (engine, _, ioHandler) = await GnustoEngineTestScaffold.setupEngine(
            items: [item],
            playerInventory: [itemID]
        )
        let handler = ExamineActionHandler()
        let initialItemState = await engine.item(with: itemID)
        #expect(initialItemState?.hasFlag(PropertyID.itemTouched) == false)

        // Act
        let command = Command(verbID: VerbID("examine"), directObject: itemID, rawInput: "examine pebble")
        let context = ActionContext(command: command, engine: engine, stateSnapshot: await engine.snapshotState())
        _ = try await handler.perform(context: context)

        // Assert Output
        let output = await ioHandler.flush()
        #expect(output.contains("A smooth, grey pebble."))

        // Assert State Change
        let finalItemState = await engine.item(with: itemID)
        #expect(finalItemState?.hasFlag(PropertyID.itemTouched) == true)

        // Assert Change History
        let expectedChanges = [
            StateChange(
                entityId: .item(itemID),
                propertyKey: .itemDynamicValue(key: .itemTouched),
                oldValue: .bool(false),
                newValue: .bool(true)
            ),
            StateChange(
                entityId: .global,
                propertyKey: .pronounReference(pronoun: "it"),
                oldValue: nil,
                newValue: .itemIDSet([itemID])
            ),
        ]
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test func testExamineItemWithDetailedDescriptionHandler() async throws {
        // Arrange
        let itemID: ItemID = "locket"
        let handlerID: DescriptionHandlerID = "locketDesc"
        let item = Item(
            id: itemID,
            name: "engraved locket",
            longDescription: "A small, tarnished silver locket.",
            descriptionHandlerId: handlerID
        )
        let registry = DefinitionRegistry()
        registry.registerDescriptionHandler(id: handlerID) { _, itemSnapshot, _, _ in
            "The locket is intricately engraved with the initials \"A.S\"."
        }
        let (engine, _, ioHandler) = await GnustoEngineTestScaffold.setupEngine(
            items: [item],
            playerInventory: [itemID],
            definitionRegistry: registry
        )
        let handler = ExamineActionHandler()
        #expect(await engine.item(with: itemID)?.hasFlag(PropertyID.itemTouched) == false)

        // Act
        let command = Command(verbID: VerbID("examine"), directObject: itemID, rawInput: "examine locket")
        let context = ActionContext(command: command, engine: engine, stateSnapshot: await engine.snapshotState())
        _ = try await handler.perform(context: context)

        // Assert Output (uses handler)
        let output = await ioHandler.flush()
        #expect(output.contains("The locket is intricately engraved with the initials \"A.S\"."))
        #expect(!output.contains("A small, tarnished silver locket."))

        // Assert State Change
        #expect(await engine.item(with: itemID)?.hasFlag(PropertyID.itemTouched) == true)
    }

    @Test func testExamineItemInRoom() async throws {
        // Arrange
        let itemID: ItemID = "statue"
        let roomID: LocationID = "garden"
        let item = Item(
            id: itemID,
            name: "stone statue",
            parent: .location(roomID),
            longDescription: "A weathered statue of a grue."
        )
        let (engine, _, ioHandler) = await GnustoEngineTestScaffold.setupEngine(
            items: [item],
            playerLocation: roomID
        )
        let handler = ExamineActionHandler()
        #expect(await engine.item(with: itemID)?.hasFlag(PropertyID.itemTouched) == false)

        // Act
        let command = Command(verbID: VerbID("examine"), directObject: itemID, rawInput: "examine statue")
        let context = ActionContext(command: command, engine: engine, stateSnapshot: await engine.snapshotState())
        _ = try await handler.perform(context: context)

        // Assert Output
        let output = await ioHandler.flush()
        #expect(output.contains("A weathered statue of a grue."))

        // Assert State Change
        #expect(await engine.item(with: itemID)?.hasFlag(PropertyID.itemTouched) == true)
    }

    @Test func testExamineItemNotInScope() async throws {
        // Arrange
        let itemID: ItemID = "hiddenGem"
        let item = Item(id: itemID, name: "hidden gem", parent: .location("farAwayRoom"), longDescription: "Should not see this.")
        let (engine, _, ioHandler) = await GnustoEngineTestScaffold.setupEngine(
            items: [item],
            playerLocation: "startRoom"
        )
        let handler = ExamineActionHandler()

        // Act
        let command = Command(verbID: VerbID("examine"), directObject: itemID, rawInput: "examine hidden gem")
        let context = ActionContext(command: command, engine: engine, stateSnapshot: await engine.snapshotState())
        let result = try await handler.perform(context: context)

        // Assert Output
        let output = await ioHandler.flush()
        #expect(output.contains("You see no hidden gem here."))

        // Assert State Change (should be none)
        #expect(result.changes.isEmpty)
        #expect(engine.gameState.changeHistory.isEmpty)
        #expect(await engine.item(with: itemID)?.hasFlag(PropertyID.itemTouched) == false)
    }

    @Test func testExamineNonExistentItem() async throws {
        // Arrange
        let (engine, _, ioHandler) = await GnustoEngineTestScaffold.setupEngine()
        let handler = ExamineActionHandler()
        let itemID: ItemID = "ghost"

        // Act
        let command = Command(verbID: VerbID("examine"), directObject: itemID, rawInput: "examine ghost")
        let context = ActionContext(command: command, engine: engine, stateSnapshot: await engine.snapshotState())
        let result = try await handler.perform(context: context)

        // Assert Output
        let output = await ioHandler.flush()
        #expect(output.contains("You see no ghost here."))

        // Assert State Change (should be none)
        #expect(result.changes.isEmpty)
        #expect(engine.gameState.changeHistory.isEmpty)
    }

    @Test func testExamineAmbiguousItem() async throws {
        // Arrange
        let itemID1: ItemID = "redBall"
        let itemID2: ItemID = "blueBall"
        let item1 = Item(id: itemID1, name: "red ball", adjectives: ["red"], noun: "ball", longDescription: "A red ball.")
        let item2 = Item(id: itemID2, name: "blue ball", adjectives: ["blue"], noun: "ball", longDescription: "A blue ball.")
        let (engine, _, ioHandler) = await GnustoEngineTestScaffold.setupEngine(
            items: [item1, item2],
            playerInventory: [itemID1, itemID2]
        )
        let handler = ExamineActionHandler()

        // Act
        let command = Command(verbID: VerbID("examine"), directObjectWord: "ball", rawInput: "examine ball")
        let context = ActionContext(command: command, engine: engine, stateSnapshot: await engine.snapshotState())
        let result = try await handler.perform(context: context)

        // Assert Output
        let output = await ioHandler.flush()
        #expect(output.contains("Which ball do you mean, the red ball or the blue ball?"))

        // Assert State Change (should be none)
        #expect(result.changes.isEmpty)
        #expect(engine.gameState.changeHistory.isEmpty)
        #expect(await engine.item(with: itemID1)?.hasFlag(PropertyID.itemTouched) == false)
        #expect(await engine.item(with: itemID2)?.hasFlag(PropertyID.itemTouched) == false)
    }

    @Test func testExamineLocationDescription() async throws {
        // Arrange
        let roomID: LocationID = "library"
        let room = Location(id: roomID, name: "Library", description: "Shelves line the walls.")
        let (engine, _, ioHandler) = await GnustoEngineTestScaffold.setupEngine(
            locations: [room],
            playerLocation: roomID
        )
        let handler = ExamineActionHandler()

        // Act
        // Simulate examining the current location (often implicit or via LOOK)
        // We can test the description logic directly here
        let description = await engine.getDescription(for: .location(id: roomID))

        // Assert
        #expect(description.contains("Shelves line the walls."))

        // Note: Examining a location typically doesn't use ExamineActionHandler
        // directly, but this tests the underlying description mechanism.
    }

    @Test func testExamineSelf() async throws {
        // Arrange
        let (engine, _, ioHandler) = await GnustoEngineTestScaffold.setupEngine()
        let handler = ExamineActionHandler()

        // Act
        let command = Command(verbID: VerbID("examine"), directObjectWord: "self", rawInput: "examine self")
        let context = ActionContext(command: command, engine: engine, stateSnapshot: await engine.snapshotState())
        _ = try await handler.perform(context: context)

        // Assert Output
        let output = await ioHandler.flush()
        #expect(output.contains("You are your usual self."))

        // Assert State Change (typically none for examining self)
        #expect(engine.gameState.changeHistory.isEmpty)
    }

    @Test func testExamineItemWithObjectActionOverride() async throws {
        // Arrange
        let itemID: ItemID = "magicMirror"
        let handlerID: ObjectActionHandlerID = "mirrorExamine"
        let item = Item(
            id: itemID,
            name: "magic mirror",
            longDescription: "A dusty old mirror.",
            objectActionHandlerId: handlerID
        )
        let registry = DefinitionRegistry()
        registry.registerObjectActionHandler(id: handlerID) { command, context, _, io, _ in
            guard command.verbID == VerbID("examine") else { return .notHandled }
            await io.print("The mirror shows a faint, ghostly image.")
            return .handled(ActionResult.empty)
        }
        let (engine, _, ioHandler) = await GnustoEngineTestScaffold.setupEngine(
            items: [item],
            playerInventory: [itemID],
            definitionRegistry: registry
        )
        let handler = ExamineActionHandler()
        #expect(await engine.item(with: itemID)?.hasFlag(PropertyID.itemTouched) == false)

        // Act
        let command = Command(verbID: VerbID("examine"), directObject: itemID, rawInput: "examine mirror")
        let context = ActionContext(command: command, engine: engine, stateSnapshot: await engine.snapshotState())
        let result = try await handler.perform(context: context)

        // Assert Output (Uses the override handler)
        let output = await ioHandler.flush()
        #expect(output.contains("The mirror shows a faint, ghostly image."))
        #expect(!output.contains("A dusty old mirror."))

        // Assert State Change (None, because the override didn't add .touched)
        #expect(result.changes.isEmpty)
        #expect(engine.gameState.changeHistory.isEmpty)
        #expect(await engine.item(with: itemID)?.hasFlag(PropertyID.itemTouched) == false)
    }

    // TODO: Restore and adapt this test if DescriptionHandlers need complex state checks
    //    @Test func testExamineItemWithStatefulDescriptionHandler() async throws {
    //        // Arrange
    //        let itemID: ItemID = "moodStone"
    //        let handlerID: DescriptionHandlerID = "stoneDesc"
    //        let item = Item(id: itemID, name: "mood stone", description: "A smooth stone.", descriptionHandlerId: handlerID)
    //        let registry = DefinitionRegistry()
    //
    //        // This handler changes description based on whether the stone is 'on'
    //        registry.registerDescriptionHandler(id: handlerID) { _, itemSnapshot, engine, _ in
    //            let isOn = itemSnapshot.hasFlag(.isOn) // Check the flag using the snapshot
    //            return isOn ? "The stone glows brightly." : "The stone is dark."
    //        }
    //
    //        let (engine, _, ioHandler) = await GnustoEngineTestScaffold.setupEngine(
    //            items: [item], // Initially off
    //            playerInventory: [itemID],
    //            definitionRegistry: registry
    //        )
    //        let handler = ExamineActionHandler()
    //
    //        // --- Test 1: Examine when Off ---
    //        var command = Command(verb: "examine", directObject: itemID)
    //        _ = try await handler.handle(command: command, engine: engine, io: ioHandler)
    //        var output = await ioHandler.flush()
    //        #expect(output.contains("The stone is dark."))
    //
    //        // --- Test 2: Turn On and Examine Again ---
    //        // Manually set the stone to 'on' (simulate a TURN ON action)
    //        try await engine.setDynamicItemValue(itemID: itemID, key: .isOn, value: .bool(true))
    //        #expect(await engine.item(with: itemID)?.hasFlag(.isOn) == true)
    //
    //        command = Command(verb: "examine", directObject: itemID)
    //        _ = try await handler.handle(command: command, engine: engine, io: ioHandler)
    //        output = await ioHandler.flush()
    //        #expect(output.contains("The stone glows brightly."))
    //    }
}
