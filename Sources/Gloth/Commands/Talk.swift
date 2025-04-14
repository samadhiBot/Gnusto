import Foundation

/// Generates phrases related to talking or communicating.
enum Talk: Generator {
    /// Generates a random phrase for talking.
    ///
    /// Examples:
    /// - "talk to the old wizard"
    /// - "tell guard about the key"
    /// - "say hello"
    /// - "ask the merchant about the sword"
    static func any() -> Phrase {
        // Reuse recipients from Give
        let recipientList = Give.recipient
        let recipientMod = Attack.enemyMod
        // Reuse items as potential topics
        let topicList = Take.takeableObject
        let topicMod = Take.objectMod

        return any(
            // --- Simple Talk To ---
            phrase( // talk to the [mod] recipient
                .verb(talkVerb.rnd),
                .preposition(toPrep),
                .determiner("the"),
                .modifier(recipientMod.rnd),
                .directObject(recipientList.rnd)
            ),
            phrase( // talk to recipient
                .verb(talkVerb.rnd),
                .preposition(toPrep),
                .directObject(recipientList.rnd)
            ),

            // --- Ask Recipient About ---
            phrase( // ask the [mod] recipient about the [mod] topic
                .verb(askVerb),
                .determiner("the"),
                .modifier(recipientMod.rnd),
                .directObject(recipientList.rnd),
                .preposition(aboutPrep),
                .determiner("the"),
                .modifier(topicMod.rnd),
                .indirectObject(topicList.rnd)
            ),
            phrase( // ask recipient about topic
                .verb(askVerb),
                .directObject(recipientList.rnd),
                .preposition(aboutPrep),
                .indirectObject(topicList.rnd)
            ),

            // --- Tell Recipient About ---
            phrase( // tell the [mod] recipient about the [mod] topic
                .verb(tellVerb),
                .determiner("the"),
                .modifier(recipientMod.rnd),
                .directObject(recipientList.rnd),
                .preposition(aboutPrep),
                .determiner("the"),
                .modifier(topicMod.rnd),
                .indirectObject(topicList.rnd)
            ),
            phrase( // tell recipient about topic
                .verb(tellVerb),
                .directObject(recipientList.rnd),
                .preposition(aboutPrep),
                .indirectObject(topicList.rnd)
            ),

            // --- Say Phrase ---
            phrase( // say [phrase]
                .verb(sayVerb),
                .directObject(simplePhrase.rnd)
            ),
            phrase( // say [phrase] to [recipient]
                .verb(sayVerb),
                .directObject(simplePhrase.rnd),
                .preposition(toPrep),
                .indirectObject(recipientList.rnd)
            )
        )
    }
}

// MARK: - Samples

extension Talk {
    // --- Verbs ---
    static var talkVerb: [String] { ["talk", "speak"] }
    static var askVerb: String { "ask" }
    static var tellVerb: String { "tell" }
    static var sayVerb: String { "say" }

    // --- Prepositions ---
    static var toPrep: String { "to" }
    static var aboutPrep: String { "about" }

    /// Simple phrases for the "say" command.
    static var simplePhrase: [String] {
        [
            // Greetings & Farewells
            "hello",
            "hi",
            "greetings",
            "good morning",
            "good afternoon",
            "good evening",
            "farewell",
            "goodbye",
            "bye",
            // Yes/No & Agreement/Disagreement
            "yes",
            "no",
            "okay",
            "ok",
            "alright",
            "maybe",
            "perhaps",
            "agree",
            "disagree",
            // Exclamations & Short Commands (meta)
            "help",
            "wait",
            "thanks",
            "thank you",
            "sorry",
            "excuse me",
            "look",
            "listen",
            // Common IF tropes/keywords
            "xyzzy",
            "plugh",
            "plover",
            "password",
            "open sesame",
            "abracadabra",
            "magic word",
        ]
    }

    // Note: Recipient and Topic lists/modifiers reused from Give/Take/Attack
}
