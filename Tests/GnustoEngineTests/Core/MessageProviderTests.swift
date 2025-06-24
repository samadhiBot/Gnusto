import Foundation
import Testing

@testable import GnustoEngine

/// Tests for the MessageProvider localization system.
@Suite("MessageProvider Tests")
struct MessageProviderTests {
    @Test("MessageProvider provides English messages")
    func testMessageProvider() async throws {
        let provider = MessageProvider()

        #expect(provider.languageCode == "en")

        // Test system messages
        #expect(provider.roomIsDark() == "It is pitch black. You can't see a thing.")
        #expect(provider.nowDark() == "You are plunged into darkness.")
        #expect(provider.nowLit() == "You can see your surroundings now.")

        // Test action response messages
        #expect(provider.playerCannotCarryMore() == "Your hands are full.")
        #expect(provider.itemNotTakable(item: "the rock") == "You can't take the rock.")
        #expect(provider.itemAlreadyOpen(item: "the door") == "The door is already open.")

        // Test parse error messages
        #expect(provider.emptyInput() == "I beg your pardon?")
        #expect(provider.parseUnknownVerb(verb: "xyzzy") == "I don't know the verb 'xyzzy'.")
        #expect(provider.itemNotInScope(noun: "lamp") == "You can't see any lamp here.")

        // Test custom messages
        #expect(provider.custom(message: "🤡 Hello world!") == "Hello world!")

        // Test prerequisite messages
        #expect(provider.prerequisiteNotMet(message: "🤡 ") == "You can't do that.")
        #expect(provider.prerequisiteNotMet(message: "🤡 Too heavy!") == "Too heavy!")
    }

    class TestMessageProvider: MessageProvider, @unchecked Sendable {
        override func roomIsDark() -> String {
            "The oppressive darkness surrounds you."
        }

        override func playerCannotCarryMore() -> String {
            "You're carrying too much already."
        }

        override func itemNotTakable(item: String) -> String {
            "You cannot pick up \(item)."
        }
    }

    @Test("Custom MessageProvider can override specific messages")
    func testCustomMessageProvider() async throws {
        let provider = TestMessageProvider()

        // Test overridden messages
        #expect(provider.roomIsDark() == "The oppressive darkness surrounds you.")
        #expect(provider.playerCannotCarryMore() == "You're carrying too much already.")
        #expect(provider.itemNotTakable(item: "the sword") == "You cannot pick up the sword.")

        // Test non-overridden messages still use defaults
        #expect(provider.nowDark() == "You are plunged into darkness.")
        #expect(provider.emptyInput() == "I beg your pardon?")
    }

    final class SpanishMessageProvider: MessageProvider, @unchecked Sendable {
        init() {
            super.init(languageCode: "es")
        }

        override func roomIsDark() -> String {
            "Está completamente oscuro. No puedes ver nada."
        }

        override func nowDark() -> String {
            "Te sumerges en la oscuridad."
        }

        override func nowLit() -> String {
            "Ahora puedes ver tu entorno."
        }

        override func playerCannotCarryMore() -> String {
            "Tienes las manos llenas."
        }

        override func itemNotTakable(item: String) -> String {
            "No puedes tomar \(item)."
        }

        override func emptyInput() -> String {
            "¿Perdón?"
        }

        override func parseUnknownVerb(verb: String) -> String {
            "No conozco el verbo '\(verb)'."
        }

        override func custom(message: String) -> String {
            message
        }
    }

    @Test("Spanish MessageProvider provides Spanish messages")
    func testSpanishMessageProvider() async throws {
        let provider = SpanishMessageProvider()

        #expect(provider.languageCode == "es")

        // Test Spanish messages
        #expect(provider.roomIsDark() == "Está completamente oscuro. No puedes ver nada.")
        #expect(provider.playerCannotCarryMore() == "Tienes las manos llenas.")
        #expect(provider.itemNotTakable(item: "la espada") == "No puedes tomar la espada.")
        #expect(provider.emptyInput() == "¿Perdón?")

        // Test fallback to English for unimplemented
        #expect(provider.itemNotDroppable(item: "the rock") == "You can't drop the rock.")
    }
}

