import Foundation

/// Generates phrases for giving an item to a recipient (person/container).
/// Example: "give the shiny apple to the old man"
enum GiveTo: Generator {
    static let itemObject: [String] = PutIn.itemObject // Reference PutIn
    // Using containerObject for recipient for now
    static let recipientObject: [String] = PutIn.containerObject // Reference PutIn
    static let itemMod: [String] = Take.objectMod // Reference Take for general mods
    static let recipientMod: [String] = Take.objectMod // Reference Take for general mods

    static let giveVerb: [String] = [
        "give", "hand", "pass", "offer", "present", "deliver",
    ]

    static let toPrep: [String] = [
        "to",
    ]

    static func any() -> Phrase {
        var phrases: [Phrase] = []

        // Base pattern: Verb DO Prep IO
        phrases.append(
            Phrase([
                .verb(giveVerb.rnd),
                .directObject(itemObject.rnd),
                .preposition(toPrep.rnd),
                .indirectObject(recipientObject.rnd),
            ])
        )

        // --- Targeted DO/IO Training ---
        // Generate diverse examples with optional modifiers
        for _ in 0..<30 {
            let currentItem = itemObject.rnd
            let currentRecipient = recipientObject.rnd
            let itemM1 = itemMod.maybeRnd()
            let itemM2 = (itemM1 != nil) ? itemMod.maybeRnd() : nil
            let recM1 = recipientMod.maybeRnd()
            let recM2 = (recM1 != nil) ? recipientMod.maybeRnd() : nil
            let currentPrep = toPrep.rnd
            let currentVerb = giveVerb.rnd

            // Build components array explicitly, filtering nils
            var components: [Word] = []
            components.append(.verb(currentVerb))
            if let mod = itemM1 { components.append(.modifier(mod)) }
            if let mod = itemM2 { components.append(.modifier(mod)) }
            components.append(.directObject(currentItem))
            components.append(.preposition(currentPrep))
            if let mod = recM1 { components.append(.modifier(mod)) }
            if let mod = recM2 { components.append(.modifier(mod)) }
            components.append(.indirectObject(currentRecipient))

            phrases.append(Phrase(components))
        }

        return phrases.randomElement()!
    }
}
