import GnustoEngine

/// Item definitions for Act I: "The Helpful Neighbor"
///
/// This extension demonstrates the new macro-based approach to defining items.
/// Each item is marked with `@GameItem` and gets its ID auto-generated
/// from the property name. Cross-references to locations and other items
/// are validated at compile time.
extension Act1Area {
    
    /// The basket containing food items - demonstrates container mechanics
    @GameItem
    static let basket = Item(
        .name("wicker basket"),
        .description("""
            A sturdy wicker basket lined with cheerful gingham cloth—the
            perfect size for carrying neighborly offerings. The weave is tight
            and even, speaking of skilled craftsmanship, and the handles are
            worn smooth from years of faithful service. It feels comfortably
            familiar in your hands, like an old friend ready for another
            journey.
            """),
        .in(.location(.yourCottage)),  // Auto-validated reference
        .capacity(5),
        .isContainer,
        .isOpenable,
        .isTakable
    )

    /// Fresh sourdough bread
    @GameItem
    static let sourdoughBoule = Item(
        .name("sourdough boule"),
        .adjectives("warm", "fresh"),
        .description("""
            A round loaf of sourdough bread, still warm from your oven this
            morning. Its crust gleams golden-brown and perfectly crispy, while
            the wonderful aroma makes your mouth water even though you baked it
            yourself. The surface bears those telltale bubbles and blisters that
            mark truly excellent bread—Berzio will be delighted.
            """),
        .in(.item(.basket)),  // Auto-validated container reference
        .isTakable,
        .size(2)
    )

    /// Butter crock - will be important in later acts
    @GameItem
    static let butterCrock = Item(
        .name("butter crock"),
        .adjectives("fresh"),
        .description("""
            A small ceramic crock filled with fresh, creamy butter churned
            just yesterday. The butter gleams with that rich, golden color that
            speaks of quality cream from contented cows. It's perfectly
            spreadable and carries the sweet, clean taste of the countryside.
            """),
        .in(.item(.basket)),
        .isTakable,
        .size(1)
    )

    /// Cherry preserves - sweet and delicious
    @GameItem
    static let preserveJar = Item(
        .name("jar of cherry preserves"),
        .adjectives("ruby", "gleaming"),
        .synonyms("preserves", "jam"),
        .description("""
            A glass jar filled with ruby-red cherry preserves that gleam like
            precious gems in the light. The fruit was picked at perfect ripeness
            and transformed into this concentrated sweetness that will pair
            beautifully with fresh bread. The jar still bears a hand-written
            label in your grandmother's careful script.
            """),
        .in(.item(.basket)),
        .isTakable,
        .size(1)
    )

    /// The famous lemonade jug that can be balanced on the head
    @GameItem
    static let lemonade = Item(
        .name("lemonade jug"),
        .adjectives("glass", "freshly", "squeezed", "blackberry"),
        .synonyms("jug"),
        .description("""
            A clear glass jug filled with freshly squeezed blackberry lemonade.
            The deep purple liquid catches the light beautifully, and tiny
            bubbles of natural carbonation dance toward the surface. It's
            perfectly balanced for carrying—or, with careful concentration,
            for balancing on your head in the time-honored tradition of
            countryside folk.
            """),
        .in(.location(.yourCottage)),
        .isTakable,
        .isWearable,  // Can be balanced on head!
        .size(3)
    )

    /// Gnusto the dog - the star of the puzzle
    @GameItem
    static let gnustoDog = Item(
        .name("small terrier"),
        .adjectives("energetic", "little", "small"),
        .synonyms("dog", "gnusto", "terrier"),
        .description("""
            This is Gnusto, Berzio's energetic little terrier. She's a compact
            bundle of enthusiasm with bright, intelligent eyes and a tail that
            never seems to stop wagging. Her coat is a warm brown with patches
            of white, and she has the alert, eager expression of a dog who's
            always ready for adventure—or mischief. Right now she's clearly
            delighted to be free and seems determined to "help" with everything
            you're trying to do.
            """),
        .in(.location(.berziosGate)),
        .isTakable,  // Can be caught and carried
        .isAnimal,
        .size(4)
    )
} 