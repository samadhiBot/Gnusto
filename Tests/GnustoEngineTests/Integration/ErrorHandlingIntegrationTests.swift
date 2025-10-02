import CustomDump
import Foundation
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("Error Handling and Edge Case Integration Tests")
struct ErrorHandlingIntegrationTests {

    // MARK: - Parser Error Handling Tests

    @Test("Parser handles completely invalid commands gracefully")
    func testParserInvalidCommands() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Various invalid command formats
        try await engine.execute(
            "",  // Empty command
            "   ",  // Whitespace only
            "!@#$%",  // Special characters
            "verylongwordthatdoesnotexistanywhere",  // Unknown verb
        )

        // Then: Should handle gracefully with appropriate messages
        await mockIO.expectOutput(
            """
            I beg your pardon?

            > !@#$%
            The universe awaits your command.

            > verylongwordthatdoesnotexistanywhere
            I lack the knowledge necessary to
            verylongwordthatdoesnotexistanywhere anything.
            """
        )
    }

    @Test("Parser handles ambiguous references correctly")
    func testParserAmbiguousReferences() async throws {
        // Given
        let redBook = Item("redBook")
            .name("book")
            .adjectives("red")
            .description("A red book.")
            .isTakable
            .in(.startRoom)

        let blueBook = Item("blueBook")
            .name("book")
            .adjectives("blue")
            .description("A blue book.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: redBook, blueBook
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Using ambiguous reference
        try await engine.execute("take book")

        // Then: Should request clarification
        await mockIO.expectOutput(
            """
            > take book
            Which do you mean, the blue book or the red book?
            """
        )
    }

    // MARK: - Item Interaction Error Tests

    @Test("Container interactions handle invalid operations")
    func testContainerErrorHandling() async throws {
        // Given
        let closedBox = Item("closedBox")
            .name("wooden box")
            .description("A sturdy wooden box.")
            .isContainer
            .isOpenable
            .isTakable
            .in(.startRoom)
            // Starts closed

        let heavyRock = Item("heavyRock")
            .name("heavy rock")
            .description("An immovable boulder.")
            .in(.startRoom)
            // Not takable

        let game = MinimalGame(
            items: closedBox, heavyRock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Invalid operations
        try await engine.execute(
            "look in wooden box",  // Container is closed
            "take heavy rock",  // Item not takable
            "put heavy rock in wooden box"  // Multiple issues
        )

        // Then: Should provide appropriate error messages
        await mockIO.expectOutput(
            """
            > look in wooden box
            The wooden box is closed.

            > take heavy rock
            The heavy rock stubbornly resists your attempts to take it.

            > put heavy rock in wooden box
            The wooden box is closed.
            """
        )
    }

    @Test("Capacity limits are enforced correctly")
    func testCapacityLimitErrorHandling() async throws {
        // Given
        let smallBag = Item("smallBag")
            .name("small bag")
            .description("A very small bag.")
            .isContainer
            .isOpenable
            .isOpen
            .isTakable
            .capacity(2)
            .in(.player)

        let largeBook = Item("largeBook")
            .name("large book")
            .description("An enormous tome.")
            .isTakable
            .size(5)  // Too big for the bag
            .in(.player)

        let game = MinimalGame(
            items: smallBag, largeBook
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Trying to exceed capacity
        try await engine.execute("put large book in small bag")

        // Then: Should reject with capacity message
        await mockIO.expectOutput(
            """
            > put large book in small bag
            The large book won't fit in the small bag.
            """
        )
    }

    // MARK: - Player State Error Tests

    @Test("Player carry capacity limits work correctly")
    func testPlayerCarryCapacityLimits() async throws {
        // Given
        // Create many items to exceed typical carry capacity
        var items: [Item] = []
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        for i in 1...20 {
            items.append(
                Item(ItemID("item\(i)"))
                    .name("\(formatter.string(from: i as NSNumber) ?? "nth") heavy item")
                    .description("A heavy item.")
                    .isTakable
                    .size(10)  // Large items
                    .in(.startRoom)
            )
        }

        let game = MinimalGame(
            items: items[0], items[1], items[2], items[3], items[4],
            items[5], items[6], items[7], items[8], items[9],
            items[10], items[11], items[12], items[13], items[14],
            items[15], items[16], items[17], items[18], items[19]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Trying to take all items
        try await engine.execute("take all")

        // Then: Should eventually hit capacity limits
        await mockIO.expectOutput(
            """
            > take all
            You take the 1st heavy item, the 10th heavy item, the 11th
            heavy item, the 12th heavy item, the 13th heavy item, the 14th
            heavy item, the 15th heavy item, the 16th heavy item, the 17th
            heavy item, and the 18th heavy item.
            """
        )
    }

    @Test("Movement errors are handled appropriately")
    func testMovementErrorHandling() async throws {
        // Given
        let isolatedRoom = Location("isolatedRoom")
            .name("Isolated Room")
            .description("A room with no exits.")
            .inherentlyLit
            // No exits defined

        let game = MinimalGame(
            player: Player(in: "isolatedRoom"),
            locations: isolatedRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Trying to move in impossible directions
        try await engine.execute("go north")
        try await engine.execute("go east")
        try await engine.execute("go to nowhere")

        // Then: Should provide appropriate error messages
        await mockIO.expectOutput("""
            > go north
            That way lies only disappointment.

            > go east
            Your path does not extend in that direction.

            > go to nowhere
            Which direction?
            """)
    }

    // MARK: - Light Source Error Tests

    @Test("Darkness handling works correctly")
    func testDarknessErrorHandling() async throws {
        // Given
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")
            // No inherent lighting

        let hiddenItem = Item("hiddenItem")
            .name("hidden treasure")
            .description("Treasure hidden in the darkness.")
            .isTakable
            .in("darkRoom")

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: hiddenItem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Trying to interact with items in darkness
        try await engine.execute("look")
        try await engine.execute("take hidden treasure")
        try await engine.execute("examine hidden treasure")

        // Then: Should indicate darkness prevents actions
        await mockIO.expectOutput(
            """
            > look
            The darkness here is absolute, consuming all light and hope of
            sight.

            > take hidden treasure
            This is the kind of dark that swallows shapes and edges,
            leaving only breath and heartbeat to prove you exist.

            > examine hidden treasure
            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.
            """
        )
    }

    // MARK: - Device Interaction Error Tests

    @Test("Device operations handle invalid states")
    func testDeviceErrorHandling() async throws {
        // Given
        let brokenDevice = Item("brokenDevice")
            .name("broken machine")
            .description("A machine that doesn't work.")
            .isTakable
            .in(.startRoom)
            // Device but cannot be turned on/off

        let game = MinimalGame(
            items: brokenDevice
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Trying device operations on non-functional device
        try await engine.execute(
            "turn on broken machine",
            "turn off broken machine"
        )

        // Then: Should indicate device doesn't respond
        await mockIO.expectOutput(
            """
            > turn on broken machine
            It remains stubbornly inert despite your ministrations.

            > turn off broken machine
            No amount of fiddling will turn that off.
            """
        )
    }

    // MARK: - Resource Exhaustion Tests

    @Test("Game handles extremely long command gracefully")
    func testLongCommandHandling() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Extremely long command
        try await engine.execute("take the bewilderingly and unbelievably long named item")

        // Then: Should handle without crashing
        await mockIO.expectOutput(
            """
            > take the bewilderingly and unbelievably long named item
            Take what?
            """
        )
    }

    // MARK: - State Consistency Tests

    @Test("Game maintains consistency after error conditions")
    func testStateConsistencyAfterErrors() async throws {
        // Given
        let testItem = Item("testItem")
            .name("test item")
            .description("A test item.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(items: testItem)

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Mix of valid and invalid commands
        try await engine.execute(
            "invalid command",
            "take test item",  // Valid
            "go nowhere",  // Invalid
            "inventory"  // Valid
        )

        // Then: Valid commands should still work after errors
        await mockIO.expectOutput(
            """
            > invalid command
            The art of invalid-ing remains a mystery to me.

            > take test item
            Got it.

            > go nowhere
            Which direction?

            > inventory
            You are carrying:
            - A test item
            """
        )

        // And: Game state should be consistent
        let item = await engine.item("testItem")
        #expect(await item.parent == .player)
    }

    // MARK: - Edge Case Command Parsing

    @Test("Parser handles edge case command formats")
    func testEdgeCaseCommandParsing() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Various edge case formats
        try await engine.execute(
            "look.",  // With punctuation
            "LOOK",  // All caps
            "l",  // Abbreviation
            "look look look"  // Repeated words
        )

        // Then: Should parse or reject gracefully
        let output = await mockIO.flush()
        // At least one look command should work
        expectNoDifference(
            output,
            """
            > look.
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            > LOOK
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            > l
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            > look look look
            Any such thing lurks beyond your reach.
            """
        )
    }

    // MARK: - Boundary Value Tests

    @Test("Game handles boundary values correctly")
    func testBoundaryValues() async throws {
        // Given
        let zeroSizeItem = Item("zeroSize")
            .name("ethereal item")
            .description("An item with no physical presence.")
            .isTakable
            .size(0)
            .in(.startRoom)

        let hugeSizeItem = Item("hugeSize")
            .name("enormous item")
            .description("An impossibly large item.")
            .isTakable
            .size(Int.max)
            .in(.startRoom)

        let game = MinimalGame(
            items: zeroSizeItem, hugeSizeItem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Interacting with boundary value items
        try await engine.execute(
            "take ethereal item",
            "take enormous item"
        )

        // Then: Should handle boundary values appropriately
        await mockIO.expectOutput(
            """
            > take ethereal item
            Taken.

            > take enormous item
            Your hands are full and your pockets protest.
            """
        )

        // Huge item might be rejected for size
        let etherealItem = await engine.item("zeroSize")
        #expect(await etherealItem.parent == .player)
    }

    // MARK: - Concurrent Operation Error Tests

    @Test("Game handles rapid command sequence correctly")
    func testRapidCommandSequence() async throws {
        // Given
        let item = Item("item")
            .name("test item")
            .description("A test item.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: item
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Rapid sequence of commands
        try await engine.execute(
            "take test item",
            "drop test item",
            "take test item",
            "examine test item",
            "drop test item"
        )

        // Then: All commands should execute in order correctly
        await mockIO.expectOutput(
            """
            > take test item
            Taken.

            > drop test item
            Relinquished.

            > take test item
            Acquired.

            > examine test item
            A test item.

            > drop test item
            Relinquished.
            """
        )

        // Final state should be consistent
        let finalItem = await engine.item("item")
        let finalParent = await finalItem.parent
        if case .location(let parentLocation) = finalParent {
            #expect(parentLocation.id == .startRoom)
        }
    }
}
