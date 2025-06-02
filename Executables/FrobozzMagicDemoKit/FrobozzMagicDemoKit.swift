import GnustoEngine

/// The Frobozz Magic Demo Kit - A comprehensive demonstration of the Gnusto Interactive Fiction Engine.
///
/// This demo showcases engine features through a three-act narrative about the accidental discovery
/// of the GNUSTO spell. Act I demonstrates core mechanics, while Acts II and III will show
/// progressively more advanced features.
///
/// ## Learning Path
/// - **New developers**: Focus on Act I for basics
/// - **Intermediate developers**: Study the progression to Act II
/// - **Advanced developers**: Examine the complete integration in Act III
///
/// ## Current Implementation Status
/// - ✅ **Act I**: Core mechanics and basic puzzle solving
/// - ⏳ **Act II**: Time-based events and custom behaviors (planned)
/// - ⏳ **Act III**: Complex systems integration (planned)
struct FrobozzMagicDemoKit: GameBlueprint {
    // MARK: - Game Metadata

    var constants: GameConstants {
        GameConstants(
            storyTitle: "The Frobozz Magic Demo Kit",
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
            release: "Demo v0.1.0",
            maximumScore: 100
        )
    }

    let player = Player(in: .yourCottage)
}
