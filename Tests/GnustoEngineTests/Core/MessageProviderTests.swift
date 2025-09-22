import CustomDump
import Foundation
import GnustoTestSupport
import Testing

@testable import GnustoEngine

/// Tests for the Messenger protocol and its implementations.
@Suite("Messenger Tests")
struct MessengerTests {

    @Test("StandardMessenger provides standard IF responses")
    func testStandardMessenger() async throws {
        let messenger = StandardMessenger(
            randomNumberGenerator: SeededRandomNumberGenerator()
        )

        // Test basic messages
        expectNoDifference(
            messenger.roomIsDark(),
            "The darkness here is absolute, consuming all light and hope of sight."
        )
        expectNoDifference(
            messenger.taken(),
            "Got it.\n"
        )
        expectNoDifference(
            messenger.itemNotInScope("lamp"),
            "You search in vain for any lamp here."
        )
        expectNoDifference(
            messenger.playerCannotCarryMore(),
            "Your hands are full and your pockets protest."
        )

        // Test action responses
        expectNoDifference(
            messenger.cannotDoYourself(Command(verb: .push)),
            "Self-pushing remains beyond your capabilities."
        )
        expectNoDifference(
            messenger.attackNonCharacter("the table"),
            "Perhaps try a less combative approach with the table."
        )
    }

    @Test("Custom messenger can override specific methods")
    func testCustomMessenger() async throws {
        let messenger = TestHorrorMessenger(
            randomNumberGenerator: SeededRandomNumberGenerator()
        )

        // Test overridden methods
        expectNoDifference(
            messenger.roomIsDark(),
            "The oppressive darkness surrounds you, whispering ancient secrets."
        )
        expectNoDifference(
            messenger.taken(),
            "You clutch it with trembling fingers."
        )

        // Test inherited methods
        expectNoDifference(
            messenger.playerCannotCarryMore(),
            "Your burden has reached its practical limit."
        )
        expectNoDifference(
            messenger.itemNotInScope("book"),
            "The book you seek is conspicuously absent."
        )
    }

    @Test("Protocol extension provides complete message coverage")
    func testProtocolExtensionCompleteness() async throws {
        let messenger = StandardMessenger(
            randomNumberGenerator: SeededRandomNumberGenerator()
        )

        // Test a sampling of different message categories to ensure
        // protocol extensions provide reasonable defaults

        // Conversation messages
        expectNoDifference(
            messenger.conversationNeverMind(),
            "Never mind."
        )
        expectNoDifference(
            messenger.askWhom(),
            "Ask whom?"
        )

        // Action messages
        expectNoDifference(
            messenger.blow(),
            "You exhale dramatically into the void."
        )
        expectNoDifference(
            messenger.jump(),
            "You jump on the spot, gravity's brief adversary."
        )

        // Error messages
        expectNoDifference(
            messenger.verbUnknown("frobnicate"),
            "I lack the knowledge necessary to frobnicate anything."
        )
        expectNoDifference(
            messenger.emptyInput(),
            "Silence speaks volumes, but accomplishes little."
        )

        // System messages
        expectNoDifference(
            messenger.briefMode(),
            "Brief mode is now on. Full location descriptions will\nbe shown only when you first enter a location."
        )
        expectNoDifference(
            messenger.timePasses(),
            "The universe's clock ticks inexorably forward."
        )
    }
}

// MARK: - Test Support

/// Test messenger for horror-themed games that overrides specific methods.
private class TestHorrorMessenger: StandardMessenger, @unchecked Sendable {
    override func roomIsDark() -> String {
        "The oppressive darkness surrounds you, whispering ancient secrets."
    }

    override func taken() -> String {
        "You clutch it with trembling fingers."
    }

    // All other methods inherit protocol extension defaults
}
