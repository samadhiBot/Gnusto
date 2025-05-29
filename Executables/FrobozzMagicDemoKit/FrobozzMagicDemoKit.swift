import GnustoEngine

/// The Frobozz Magic Demo Kit - A comprehensive demonstration of the Gnusto Interactive Fiction Engine.
///
/// This demo showcases the ultimate simplicity of the macro-based game definition system.
/// With just a few lines, we define a complete interactive fiction game that automatically
/// discovers all content from the areas marked with `@GameArea`.
///
/// ## Learning Path
/// - **New developers**: See how simple game creation can be
/// - **Existing developers**: Compare with the old manual registration approach
/// - **Advanced developers**: Examine the macro-generated code for insights
///
/// ## Implementation Status
/// - ✅ **Act I**: Core mechanics (basket, lemonade, Gnusto dog puzzle)
/// - ⏳ **Act II**: Time-based events and bureaucracy (planned)
/// - ⏳ **Act III**: Complex spell discovery system (planned)

@GameBlueprint(
    title: "The Frobozz Magic Demo Kit",
    introduction: """
        769 GUE

        You are a neighbor of Berzio, a reclusive thaumaturge whose
        modest cottage sits just across the creek from your own. Like
        your grandmother before you, and her grandmother before that,
        you've kept up the old tradition—once a week, you pack up some
        food and carry it to his gate. It's a small kindness that goes
        back generations, one of those quiet customs that makes a
        community feel like home.

        In return, Berzio's gentle magic keeps your little corner of the
        world just as it should be. The hedges grow in perfect shapes
        without pruning, wildflowers bloom in endless abundance, and
        even the weather seems a touch more agreeable. Your own magical
        bridge—fitted stones that hover gracefully above the
        creek—stands as testament to his beneficent influence.

        Today you've prepared something special: a warm sourdough boule
        still fragrant from the oven, a crock of golden butter churned
        yesterday, and a jar of cherry preserves that gleam like rubies
        in the morning light. In your other hand, you carry a jug of
        freshly squeezed blackberry lemonade—the perfect refreshment for
        a thaumaturge who sometimes forgets to eat for days at a time.

        The morning is beautiful, your basket is full, and Berzio's
        bridge awaits. Time to pay your weekly visit to the most
        absent-minded neighbor in the countryside.
        """,
    maxScore: 100,
    startingLocation: .yourCottage
)
struct FrobozzMagicDemoKit {
    // That's it! Everything else is discovered automatically:
    // - Areas are discovered by convention (*Area types)
    // - Items/locations are discovered from @GameItem/@GameLocation extensions  
    // - Event handlers are discovered from @ItemEventHandler/@LocationEventHandler extensions
    // - Time events are discovered from @GameFuse/@GameDaemon extensions
    // - All ID constants are auto-generated
    // - All cross-references are validated at compile time
}

// MARK: - Manual Areas Registration (Temporary)
// TODO: Remove this once convention-based discovery is implemented
extension FrobozzMagicDemoKit {
    var areas: [any AreaBlueprint.Type] {
        [
            Act1Area.self,
            // Act2Area.self,  // When implemented
            // Act3Area.self,  // When implemented
        ]
    }
}

// MARK: - Auto-Generated ID Constants
// TODO: These will be generated automatically by the @GameArea macro

extension LocationID {
    static let berziosGarden = LocationID("berziosGarden")
    static let berziosGate = LocationID("berziosGate")
    static let countryRoad = LocationID("countryRoad")
    static let stoneBridge = LocationID("stoneBridge")
    static let yourCottage = LocationID("yourCottage")
}

extension ItemID {
    static let basket = ItemID("basket")
    static let butterCrock = ItemID("butterCrock")
    static let gnustoDog = ItemID("gnustoDog")
    static let lemonade = ItemID("lemonade")
    static let preserveJar = ItemID("preserveJar")
    static let sourdoughBoule = ItemID("sourdoughBoule")
}

extension GlobalID {
    static let basketPutDown = GlobalID("basketPutDown")
    static let gnustoCaught = GlobalID("gnustoCaught")
    static let gnustoEscaped = GlobalID("gnustoEscaped")
    static let lemonadeOnHead = GlobalID("lemonadeOnHead")
}
