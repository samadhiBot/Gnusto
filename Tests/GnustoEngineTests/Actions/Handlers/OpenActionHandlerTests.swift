import CustomDump
import Testing

@testable import GnustoEngine

@Suite("OpenActionHandler Tests")
struct OpenActionHandlerTests {
    // Helper function for expected state changes during a successful open
    private func expectedOpenChanges(
        itemID: ItemID,
        initialAttributes: [ItemAttributeID: StateValue]?
    ) -> [StateChange] {
        var changes: [StateChange] = []

        // Change 1: isOpen becomes true
        changes.append(
            StateChange(
                entityID: .item(itemID),
                attribute: .itemAttribute(.isOpen),
                oldValue: initialAttributes?[.isOpen],  // Check initial state
                newValue: true,
            )
        )

        // Change 2: Item touched (if needed)
        if initialAttributes?[.isTouched] != true {
            changes.append(
                StateChange(
                    entityID: .item(itemID),
                    attribute: .itemAttribute(.isTouched),
                    oldValue: initialAttributes?[.isTouched],
                    newValue: true,
                )
            )
        }

        // Change 3: Pronoun "it"
        changes.append(
            StateChange(
                entityID: .global,
                attribute: .pronounReference(pronoun: "it"),
                oldValue: nil,  // Assume no prior "it" for simplicity
                newValue: .entityReferenceSet([.item(itemID)])
            )
        )

        return changes
    }

    @Test("Open item successfully")
    func testOpenItemSuccessfully() async throws {
        // Arrange
        let closedBox = Item(
            id: "box",
            .name("wooden box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpenable
            // Starts closed (no .isOpen attribute)
        )

        let game = MinimalGame(items: closedBox)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Initial state check
        let initialBoxState = try await engine.item("box")
        #expect(!initialBoxState.hasFlag(.isOpen), "Box should start closed")
        #expect(!initialBoxState.hasFlag(.isTouched), "Box should start untouched")
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act: Call the engine's execute method
        try await engine.execute("open box")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> open box\n\nYou open the wooden box.")

        // Assert Change History
        let expectedChanges = expectedOpenChanges(
            itemID: "box",
            initialAttributes: initialBoxState.attributes
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)

        // Optional: Verify final state via snapshot if needed for complex scenarios,
        // but primarily rely on change history for handler correctness.
        let finalBoxState = try await engine.item("box")
        #expect(finalBoxState.hasFlag(.isOpen) == true, "Box should be open")
        #expect(finalBoxState.hasFlag(.isTouched) == true, "Box should be touched")
    }

    @Test("Open item that is already touched")
    func testOpenItemAlreadyTouched() async throws {
        // Arrange: Item is openable, closed, and already touched
        let closedBox = Item(
            id: "box",
            .name("wooden box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpenable,
            .isTouched  // Already touched
        )

        let game = MinimalGame(items: closedBox)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Initial state check
        let initialBoxState = try await engine.item("box")
        #expect(!initialBoxState.hasFlag(.isOpen), "Box should start closed")
        #expect(initialBoxState.hasFlag(.isTouched), "Box should start touched")
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act: Call the engine's execute method
        try await engine.execute("open box")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> open box\n\nYou open the wooden box.")

        // Assert Change History
        let expectedChanges = expectedOpenChanges(
            itemID: "box", initialAttributes: initialBoxState.attributes)
        // Should not include .isTouched change as it was already true
        #expect(expectedChanges.count == 2)  // isOpen + pronoun
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)

        // Optional: Verify final state
        let finalBoxState = try await engine.item("box")
        #expect(finalBoxState.hasFlag(.isOpen) == true, "Box should be open")
        #expect(finalBoxState.hasFlag(.isTouched) == true, "Box should still be touched")
    }

    @Test("Open fails with no direct object")
    func testOpenFailsWithNoObject() async throws {
        // Arrange
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("open")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> open\n\nOpen what?")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Open fails item not accessible")
    func testOpenFailsItemNotAccessible() async throws {
        // Arrange
        let box = Item(
            id: "box",
            .in(.nowhere),
            .isOpenable
            // Don't need .isOpen here, it's not reachable anyway
        )
        let game = MinimalGame(items: box)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("open box")

        // Assert Output
        let output = await mockIO.flush()
        // Updated expected message for inaccessible items
        expectNoDifference(output, "> open box\n\nYou can't see any such thing.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Open fails item not openable")
    func testOpenFailsItemNotOpenable() async throws {
        // Arrange
        let rock = Item(
            id: "rock",
            .name("heavy rock"),
            .in(.location(.startRoom))
        )  // No .openable

        let game = MinimalGame(items: rock)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("open rock")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> open rock\n\nYou can't open the heavy rock.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Open fails item already open")
    func testOpenFailsItemAlreadyOpen() async throws {
        // Arrange
        let openBox = Item(
            id: "box",
            .name("wooden box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpenable,
            .isOpen  // Already open
        )

        let game = MinimalGame(items: openBox)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("open box")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> open box\n\nThe wooden box is already open.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Open fails item is locked")
    func testOpenFailsItemIsLocked() async throws {
        // Arrange
        let lockedChest = Item(
            id: "chest",
            .name("iron chest"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpenable,
            .isLocked  // Locked
        )  // Locked

        let game = MinimalGame(items: lockedChest)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("open chest")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> open chest\n\nThe iron chest is locked.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)
    }
}
