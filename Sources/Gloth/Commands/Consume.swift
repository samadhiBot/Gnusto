import Foundation

/// Generates phrases related to consuming items (eating or drinking).
enum Consume: Generator {
    /// Generates a random phrase for consuming an item.
    ///
    /// Examples:
    /// - "eat the stale bread"
    /// - "drink the bubbling potion"
    /// - "taste mushroom"
    /// - "gulp water"
    static func any() -> Phrase {
        any(
            // Eat phrases
            phrase(
                .verb(eatVerb.rnd),
                .determiner("the"),
                .modifier(foodMod.rnd),
                .directObject(foodObject.rnd)
            ),
            phrase(
                .verb(eatVerb.rnd),
                .directObject(foodObject.rnd) // No modifier
            ),
            phrase(
                .verb(eatVerb.rnd),
                .determiner("a"),
                .modifier(foodMod.rnd),
                .directObject(foodObject.rnd)
            ),
            phrase(
                .verb(eatVerb.rnd),
                .determiner("a"),
                .directObject(foodObject.rnd) // No modifier
            ),
            // Drink phrases
            phrase(
                .verb(drinkVerb.rnd),
                .determiner("the"),
                .modifier(drinkMod.rnd),
                .directObject(drinkObject.rnd)
            ),
            phrase(
                .verb(drinkVerb.rnd),
                .directObject(drinkObject.rnd) // No modifier
            ),
            phrase(
                .verb(drinkVerb.rnd),
                .determiner("a"),
                .modifier(drinkMod.rnd),
                .directObject(drinkObject.rnd)
            ),
            phrase(
                .verb(drinkVerb.rnd),
                .determiner("a"),
                .directObject(drinkObject.rnd) // No modifier
            )
        )
    }
}

// MARK: - Samples

extension Consume {
    /// Sample verbs for eating.
    static var eatVerb: [String] {
        [
            "bite",
            "chew",
            "consume",
            "devour",
            "eat",
            "gulp", // Can apply to food too
            "scarf",
            "taste",
        ]
    }

    /// Sample verbs for drinking.
    static var drinkVerb: [String] {
        [
            "drink",
            "gulp",
            "imbibe",
            "swallow",
            "taste", // Can apply to drinks too
        ]
    }

    /// Sample modifiers for food items.
    static var foodMod: [String] {
        [
            "chewy",
            "cooked",
            "delicious",
            "dried",
            "fresh",
            "hard",
            "moldy",
            "raw",
            "rotten",
            "salty",
            "savory",
            "smoked",
            "spicy",
            "stale",
            "sweet",
            "tasty",
        ]
    }

    /// Sample modifiers for drinkable items.
    static var drinkMod: [String] {
        [
            "bubbling",
            "chilled",
            "clear",
            "cloudy",
            "cool",
            "fizzy",
            "flat",
            "fragrant",
            "fresh",
            "glowing",
            "hot",
            "icy",
            "murky",
            "sparkling",
            "warm",
        ]
    }

    /// Sample edible objects.
    static var foodObject: [String] {
        [
            "apple",
            "biscuit",
            "bread",
            "cake",
            "candy",
            "cheese",
            "chicken",
            "chocolate",
            "cookie",
            "cracker",
            "fish",
            "fruit",
            "jerky",
            "loaf",
            "meat",
            "mushroom",
            "nut",
            "pie",
            "ration",
            "salami", // From Attack
            "steak",
            "stew",
            "turnip",
            "vegetable",
        ]
    }

    /// Sample drinkable objects.
    static var drinkObject: [String] {
        [
            "ale",
            "beer",
            "broth",
            "elixir",
            "juice",
            "liquid",
            "mead",
            "milk",
            "nectar",
            "poison",
            "potion",
            "rum",
            "soup",
            "spirits",
            "tea",
            "tonic",
            "water", // From Take
            "whiskey",
            "wine",
        ]
    }
}
