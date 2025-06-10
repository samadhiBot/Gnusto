import Foundation
import Testing

@testable import GnustoEngine

/// Tests for the MessageProvider localization system.
@Suite("MessageProvider Tests")
struct MessageProviderTests {
    @Test("StandardMessageProvider provides English messages")
    func testStandardMessageProvider() async throws {
        let provider = StandardMessageProvider()

        #expect(provider.languageCode == "en")

        // Test system messages
        #expect(provider.message(for: .roomIsDark) == "It is pitch black. You can't see a thing.")
        #expect(provider.message(for: .nowDark) == "You are plunged into darkness.")
        #expect(provider.message(for: .nowLit) == "You can see your surroundings now.")

        // Test action response messages
        #expect(provider.message(for: .playerCannotCarryMore) == "Your hands are full.")
        #expect(provider.message(for: .itemNotTakable(item: "the rock")) == "You can't take the rock.")
        #expect(provider.message(for: .itemAlreadyOpen(item: "the door")) == "The door is already open.")

        // Test parse error messages
        #expect(provider.message(for: .emptyInput) == "I beg your pardon?")
        #expect(provider.message(for: .parseUnknownVerb(verb: "xyzzy")) == "I don't know the verb 'xyzzy'.")
        #expect(provider.message(for: .itemNotInScope(noun: "lamp")) == "You can't see any 'lamp' here.")

        // Test custom messages
        #expect(provider.message(for: .custom(message: "Hello world!")) == "Hello world!")

        // Test prerequisite messages
        #expect(provider.message(for: .prerequisiteNotMet(message: "")) == "You can't do that.")
        #expect(provider.message(for: .prerequisiteNotMet(message: "Too heavy!")) == "Too heavy!")
    }

    struct TestMessageProvider: MessageProvider {
        let languageCode = "en"

        /// Standard provider for fallback to default messages
        private let standard = StandardMessageProvider()

        func message(for key: MessageKey) -> String {
            switch key {
            case .roomIsDark:
                "The oppressive darkness surrounds you."
            case .playerCannotCarryMore:
                "You're carrying too much already."
            case .itemNotTakable(let item):
                "You cannot pick up \(item)."
            default:
                standard.message(for: key)
            }
        }
    }

    @Test("Custom MessageProvider can override specific messages")
    func testCustomMessageProvider() async throws {
        let provider = TestMessageProvider()

        // Test overridden messages
        #expect(provider.message(for: .roomIsDark) == "The oppressive darkness surrounds you.")
        #expect(provider.message(for: .playerCannotCarryMore) == "You're carrying too much already.")
        #expect(provider.message(for: .itemNotTakable(item: "the sword")) == "You cannot pick up the sword.")

        // Test non-overridden messages still use defaults
        #expect(provider.message(for: .nowDark) == "You are plunged into darkness.")
        #expect(provider.message(for: .emptyInput) == "I beg your pardon?")
    }

    struct SpanishMessageProvider: MessageProvider {
        let languageCode = "es"

        /// Standard provider for fallback to default messages
        private let standard = StandardMessageProvider()

        func message(for key: MessageKey) -> String {
            switch key {
            case .roomIsDark:
                "Está completamente oscuro. No puedes ver nada."
            case .nowDark:
                "Te sumerges en la oscuridad."
            case .nowLit:
                "Ahora puedes ver tu entorno."
            case .playerCannotCarryMore:
                "Tienes las manos llenas."
            case .itemNotTakable(let item):
                "No puedes tomar \(item)."
            case .emptyInput:
                "¿Perdón?"
            case .parseUnknownVerb(let verb):
                "No conozco el verbo '\(verb)'."
            case .custom(let message):
                message
            default:
                // Fallback to English for unimplemented messages
                standard.message(for: key)
            }
        }
    }

    @Test("Spanish MessageProvider provides Spanish messages")
    func testSpanishMessageProvider() async throws {
        let provider = SpanishMessageProvider()

        #expect(provider.languageCode == "es")

        // Test Spanish messages
        #expect(provider.message(for: .roomIsDark) == "Está completamente oscuro. No puedes ver nada.")
        #expect(provider.message(for: .playerCannotCarryMore) == "Tienes las manos llenas.")
        #expect(provider.message(for: .itemNotTakable(item: "la espada")) == "No puedes tomar la espada.")
        #expect(provider.message(for: .emptyInput) == "¿Perdón?")

        // Test fallback to English for unimplemented
        #expect(provider.message(for: .itemNotDroppable(item: "the rock")).contains("can't drop"))
    }

    @Test("MessageKey hashable and equality works correctly")
    func testMessageKeyEquality() async throws {
        let key1: MessageKey = .roomIsDark
        let key2: MessageKey = .roomIsDark
        let key3: MessageKey = .nowDark

        #expect(key1 == key2)
        #expect(key1 != key3)

        let key4: MessageKey = .itemNotTakable(item: "rock")
        let key5: MessageKey = .itemNotTakable(item: "rock")
        let key6: MessageKey = .itemNotTakable(item: "stone")

        #expect(key4 == key5)
        #expect(key4 != key6)

        // Test in Set/Dictionary
        let keySet: Set<MessageKey> = [key1, key2, key3, key4, key5, key6]
        #expect(keySet.count == 4) // key1==key2 and key4==key5, so 4 unique keys
    }
}

