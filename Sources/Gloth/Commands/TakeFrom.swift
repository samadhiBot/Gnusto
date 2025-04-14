import Foundation

/// Generates phrases for taking an item from a container.
/// Example: "take the rusty key from the old wooden chest"
enum TakeFrom: Generator {
    static let itemObject: [String] = PutIn.itemObject
    static let containerObject: [String] = PutIn.containerObject
    static let itemMod: [String] = Take.objectMod
    static let containerMod: [String] = Take.objectMod

    static let takeVerb: [String] = [
        "take", "get", "remove", "retrieve", "grab", "extract", "pull",
    ]

    static let fromPrep: [String] = [
        "from",
    ]

    static func any() -> Phrase {
        var phrases: [Phrase] = []

        // Base pattern: Verb DO Prep IO
        phrases.append(
            Phrase([
                .verb(takeVerb.rnd),
                .directObject(itemObject.rnd),
                .preposition(fromPrep.rnd),
                .indirectObject(containerObject.rnd),
            ])
        )

        // --- Targeted DO/IO Training ---
        // Generate diverse examples with optional modifiers
        for _ in 0..<30 {
            let currentItem = itemObject.rnd
            let currentCont = containerObject.rnd
            let itemM1 = itemMod.maybeRnd()
            let itemM2 = (itemM1 != nil) ? itemMod.maybeRnd() : nil
            let contM1 = containerMod.maybeRnd()
            let contM2 = (contM1 != nil) ? containerMod.maybeRnd() : nil
            let currentPrep = fromPrep.rnd
            let currentVerb = takeVerb.rnd

            // Build components array explicitly, filtering nils
            var components: [Word] = []
            components.append(.verb(currentVerb))
            if let mod = itemM1 { components.append(.modifier(mod)) }
            if let mod = itemM2 { components.append(.modifier(mod)) }
            components.append(.directObject(currentItem))
            components.append(.preposition(currentPrep))
            if let mod = contM1 { components.append(.modifier(mod)) }
            if let mod = contM2 { components.append(.modifier(mod)) }
            components.append(.indirectObject(currentCont))

            phrases.append(Phrase(components))
        }

        return phrases.randomElement()!
    }
}
