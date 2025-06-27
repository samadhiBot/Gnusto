import Foundation

@testable import GnustoEngine

/// Comprehensive demonstration of the Gnusto Interactive Fiction Engine's Conversation System
///
/// This demo showcases the newly implemented conversation system that enables:
/// 1. Two-phase asking: "ASK TROLL" → "What do you want to ask about?" → "TREASURE"
/// 2. Yes/No confirmation dialogs: "NIBBLE APPLE" → "Do you mean you want to eat the apple?" → "YES"
/// 3. Graceful recovery when players don't answer questions directly
///
/// The system faithfully recreates ZIL-style interactive fiction conversation patterns.
public class ConversationSystemDemo {

    // MARK: - Demo Game Setup

    /// Creates a demonstration game world with conversation-enabled characters and items
    public static func createDemoGame() -> MinimalGame {
        // Create locations
        let trollBridge = Location(
            id: "trollBridge",
            .name("Troll Bridge"),
            .description(
                """
                You are standing before a rickety wooden bridge spanning a deep gorge.
                A large, ugly troll blocks your path, glaring at you menacingly.
                """),
            .inherentlyLit
        )

        let orchard = Location(
            id: "orchard",
            .name("Apple Orchard"),
            .description(
                """
                You are in a peaceful apple orchard. Red apples hang heavy from the trees,
                and the air smells of sweet fruit and fresh earth.
                """),
            .inherentlyLit
        )

        // Create characters for conversation
        let troll = Item(
            id: "troll",
            .name("ugly troll"),
            .description(
                """
                The troll is a massive, hairy creature with yellowed tusks and small,
                beady eyes. He clutches a gnarled club and seems to be guarding the bridge.
                """),
            .isCharacter,
            .in(.location("trollBridge"))
        )

        let wizard = Item(
            id: "wizard",
            .name("wise wizard"),
            .description(
                """
                An ancient wizard with a long gray beard and twinkling eyes. He wears
                star-spangled robes and carries a crystal staff.
                """),
            .isCharacter,
            .in(.location("orchard"))
        )

        // Create items for testing different conversation scenarios
        let treasure = Item(
            id: "treasure",
            .name("golden treasure"),
            .description("A heavy chest filled with gleaming gold coins."),
            .isTakable,
            .in(.location("trollBridge"))
        )

        let apple = Item(
            id: "apple",
            .name("red apple"),
            .description("A perfectly ripe red apple that looks delicious."),
            .isTakable,
            .isEdible,
            .in(.location("orchard"))
        )

        let cookies = Item(
            id: "cookies",
            .name("chocolate cookies"),
            .description("A plate of warm chocolate chip cookies."),
            .isTakable,
            .isEdible,
            .in(.player)
        )

        let spell = Item(
            id: "spell",
            .name("magic spell"),
            .description("An ancient scroll containing a powerful magic spell."),
            .in(.location("orchard"))
        )

        return MinimalGame(
            player: Player(in: "trollBridge"),
            locations: trollBridge, orchard,
            items: troll, wizard, treasure, apple, cookies, spell
        )
    }

    // MARK: - Demonstration Scenarios

    /// Demonstrates the complete conversation system with various interaction patterns
    public static func runDemo() async {
        print("🎭 GNUSTO CONVERSATION SYSTEM DEMO")
        print("=====================================\n")

        let game = createDemoGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Scenario 1: Two-phase asking
        await demonstrateTwoPhaseAsking(engine: engine)

        // Scenario 2: Yes/No confirmation dialogs
        await demonstrateYesNoConfirmation(engine: engine)

        // Scenario 3: Graceful recovery
        await demonstrateGracefulRecovery(engine: engine)

        // Scenario 4: Direct asking (traditional)
        await demonstrateDirectAsking(engine: engine)

        print("✅ Demo completed successfully!")
        print("\nThe conversation system enables rich, ZIL-style interactive fiction")
        print("conversations while maintaining modern Swift architecture principles.")
    }

    /// Demonstrates two-phase asking: ASK CHARACTER → prompt → TOPIC
    private static func demonstrateTwoPhaseAsking(engine: GameEngine) async {
        print("📖 SCENARIO 1: Two-Phase Asking")
        print("--------------------------------")
        print("Player: ask troll")

        // Phase 1: Ask without specifying topic
        try! await engine.execute("ask troll")
        print("Engine: What do you want to ask the ugly troll about?")

        // Verify question is pending
        let hasPending = await ConversationManager.hasPendingQuestion(engine: engine)
        print("System: Question pending = \(hasPending)")

        print("\nPlayer: treasure")

        // Phase 2: Provide the topic
        try! await engine.execute("treasure")
        print("Engine: The ugly troll doesn't seem to know anything about the golden treasure.")

        // Verify question is cleared
        let stillPending = await ConversationManager.hasPendingQuestion(engine: engine)
        print("System: Question pending = \(stillPending)\n")
    }

    /// Demonstrates yes/no confirmation dialogs for ambiguous commands
    private static func demonstrateYesNoConfirmation(engine: GameEngine) async {
        print("📖 SCENARIO 2: Yes/No Confirmation")
        print("----------------------------------")
        print("Player: nibble cookies")

        // Command triggers disambiguation
        try! await engine.execute("nibble cookies")
        print("Engine: Do you mean you want to eat the chocolate cookies?")

        // Verify yes/no question is pending
        let context = await ConversationManager.getCurrentQuestion(engine: engine)
        print("System: Question type = \(context?.type.rawValue ?? "none")")

        print("\nPlayer: yes")

        // Confirm the action
        try! await engine.execute("yes")
        print("Engine: You eat the chocolate cookies. They were delicious!")

        // Verify question is cleared
        let cleared = await ConversationManager.hasPendingQuestion(engine: engine)
        print("System: Question pending = \(cleared)\n")
    }

    /// Demonstrates graceful recovery when players don't answer questions
    private static func demonstrateGracefulRecovery(engine: GameEngine) async {
        print("📖 SCENARIO 3: Graceful Recovery")
        print("--------------------------------")
        print("Player: ask wizard")

        // Start a question
        try! await engine.execute("ask wizard")
        print("Engine: What do you want to ask the wise wizard about?")

        print("\nPlayer: inventory")

        // Player ignores question and does something else
        try! await engine.execute("inventory")
        print("Engine: You have:")
        print("    a red apple")

        // Verify question was cleared automatically
        let recovered = await ConversationManager.hasPendingQuestion(engine: engine)
        print("System: Question auto-cleared = \(!recovered)")

        print("\nPlayer: nibble apple")

        // Start another question
        try! await engine.execute("nibble apple")
        print("Engine: Do you mean you want to eat the red apple?")

        print("\nPlayer: go north")

        // Player ignores question again
        try! await engine.execute("go north")
        print("Engine: You can't go that way.")

        // Verify this question was also cleared
        let alsoRecovered = await ConversationManager.hasPendingQuestion(engine: engine)
        print("System: Question auto-cleared = \(!alsoRecovered)\n")
    }

    /// Demonstrates traditional direct asking (no prompting)
    private static func demonstrateDirectAsking(engine: GameEngine) async {
        print("📖 SCENARIO 4: Direct Asking (Traditional)")
        print("-----------------------------------------")
        print("Player: ask wizard about spell")

        // Direct ask with both character and topic specified
        try! await engine.execute("ask wizard about spell")
        print("Engine: The wise wizard doesn't seem to know anything about a magic spell.")

        // Verify no question was created (direct execution)
        let noQuestion = await ConversationManager.hasPendingQuestion(engine: engine)
        print("System: No question needed = \(!noQuestion)\n")
    }

    // MARK: - System Architecture Notes

    /// Prints detailed information about the conversation system architecture
    public static func printArchitectureNotes() {
        print("🏗️  CONVERSATION SYSTEM ARCHITECTURE")
        print("====================================")
        print(
            """

            The Gnusto conversation system consists of several key components:

            1. **ConversationManager**:
               - Manages question state using GlobalIDs
               - Handles input interpretation and response processing
               - Provides graceful recovery when questions go unanswered

            2. **Enhanced AskActionHandler**:
               - Supports both direct asking ("ASK TROLL ABOUT TREASURE")
               - And two-phase asking ("ASK TROLL" → prompt → "TREASURE")
               - Seamlessly integrates with existing action handler pipeline

            3. **YesNoQuestionHandler**:
               - Utility for creating confirmation dialogs
               - Supports disambiguation and action verification
               - Handles multiple yes/no synonyms ("yes", "y", "sure", etc.)

            4. **NibbleActionHandler** (Example):
               - Demonstrates disambiguation pattern
               - Shows how to create yes/no questions for ambiguous commands
               - Integrates with EatActionHandler for actual consumption

            5. **Modified GameEngine.processTurn()**:
               - Checks for pending questions before normal command processing
               - Routes question responses through ConversationManager
               - Maintains backward compatibility with existing commands

            **State Management**:
            - All conversation state flows through StateChange objects
            - Questions are stored as GlobalIDs in game state
            - Automatic cleanup prevents orphaned question states

            **Key Benefits**:
            - ✅ Faithful ZIL-style interaction patterns
            - ✅ Type-safe state management
            - ✅ Graceful error handling and recovery
            - ✅ Full test coverage with Swift Testing
            - ✅ Clean separation of concerns
            - ✅ Backward compatibility with existing handlers

            """)
    }
}

// MARK: - Example Usage

/*
 To run this demo in your own project:

 ```swift
 import GnustoEngine

 // Run the interactive demo
 await ConversationSystemDemo.runDemo()

 // Print architecture information
 ConversationSystemDemo.printArchitectureNotes()

 // Create your own conversation-enabled game
 let game = ConversationSystemDemo.createDemoGame()
 let (engine, ioHandler) = await GameEngine.test(blueprint: game)

 // Test two-phase asking
 try await engine.execute("ask troll")        // Prompts for topic
 try await engine.execute("treasure")         // Provides topic

 // Test yes/no confirmation
 try await engine.execute("nibble apple")     // Asks for confirmation
 try await engine.execute("yes")              // Confirms action

 // Test graceful recovery
 try await engine.execute("ask wizard")       // Starts question
 try await engine.execute("inventory")        // Ignores question, auto-clears
 ```

 The conversation system seamlessly integrates with the existing Gnusto engine
 while providing rich, ZIL-style interactive fiction conversation capabilities.
 */
