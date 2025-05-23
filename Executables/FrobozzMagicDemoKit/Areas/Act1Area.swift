import GnustoEngine

/// Act I: "The Helpful Neighbor" - Core Engine Mechanics Demonstration
///
/// This area demonstrates the foundational features of the Gnusto Interactive Fiction Engine:
/// - Basic `Location` and `Item` definitions
/// - Container mechanics and item properties
/// - Simple `ItemEventHandler` and `LocationEventHandler` usage
/// - Standard action handling and scope resolution
///
/// ## Story Summary
/// You're bringing food to your neighbor Berzio when his excited dog Gnusto escapes from the gate.
/// The puzzle involves managing your full hands while catching the dog, demonstrating item juggling
/// mechanics and the engine's scope and interaction systems.
///
/// ## Engine Features Showcased
/// - Location exits and navigation
/// - Container items with capacity limits
/// - Item properties (takable, wearable, etc.)
/// - Event handlers with naming conventions
/// - State tracking and conditional responses
/// - Parser interactions and disambiguation
struct Act1Area: AreaBlueprint {

    // MARK: - Locations

    /// Your house - the starting location where the journey begins
    let yourHouse = Location(
        id: .yourHouse,
        .name("Your House"),
        .description("""
            Your cozy cottage sits comfortably beside the winding country road. A cheerful garden
            surrounds the house, with vegetables and herbs growing in neat rows. To the east, a
            magical stone bridge spans the creek that separates your property from the road.
            """),
        .exits([
            .east: Exit(destination: .stoneBridge)
        ]),
        .inherentlyLit
    )

    /// The magical bridge showing signs of Berzio's hunger
    let stoneBridge = Location(
        id: .stoneBridge,
        .name("Stone Bridge"),
        .description("""
            The bridge spanning the creek is one of Berzio's magical creations, formed from
            fitted stones that hover slightly above the water. Usually it's perfectly stable,
            but today you can feel it wobble and bob slightly under your feet. Feeble sparks
            crackle between the stones - telltale signs that Berzio hasn't been eating properly.

            The bridge connects your house to the west with the country road to the east.
            """),
        .exits([
            .west: Exit(destination: .yourHouse),
            .east: Exit(destination: .countryRoad)
        ]),
        .inherentlyLit
    )

    /// The lovely country road between houses
    let countryRoad = Location(
        id: .countryRoad,
        .name("Country Road"),
        .description("""
            This section of the winding country road is particularly lovely. Ancient oak trees
            line both sides, their branches forming a natural canopy overhead. Wild flowers
            bloom in abundance along the verges, and the hedges grow in perfectly maintained
            shapes - all thanks to Berzio's beneficent magical influence.

            Your stone bridge lies to the west, while Berzio's gate can be seen to the north.
            """),
        .exits([
            .west: Exit(destination: .stoneBridge),
            .north: Exit(destination: .berziosGate)
        ]),
        .inherentlyLit
    )

    /// Berzio's gate - where the main puzzle takes place
    let berziosGate = Location(
        id: .berziosGate,
        .name("Berzio's Gate"),
        .description("""
            You stand before the wrought-iron gate that leads into Berzio's garden. The gate
            is beautifully crafted, with intricate patterns that seem to shift slightly when
            you're not looking directly at them. A worn brass latch holds it closed.

            Through the gate, you can see Berzio's peaceful garden with its herb plots and
            magical apparatus. The country road continues to the south.
            """),
        .exits([
            .south: Exit(destination: .countryRoad),
            .north: Exit(destination: .berziosGarden)
        ]),
        .inherentlyLit
    )

    /// Berzio's garden - the goal location
    let berziosGarden = Location(
        id: .berziosGarden,
        .name("Berzio's Garden"),
        .description("""
            You've successfully entered Berzio's peaceful garden. Herb plots are arranged in
            mystical patterns, and various pieces of magical apparatus sit on wooden tables.
            A path leads to Berzio's cottage, where warm light glows in the windows.

            Little Gnusto bounces around happily, clearly delighted to be back in her proper home.
            """),
        .exits([
            .south: Exit(destination: .berziosGate)
        ]),
        .inherentlyLit
    )

    // MARK: - Items

    /// The basket containing food items - demonstrates container mechanics
    let basket = Item(
        id: .basket,
        .name("wicker basket"),
        .description("""
            A sturdy wicker basket with a gingham cloth lining. It's the perfect size for
            carrying food offerings to neighbors. The basket feels comfortably familiar in your hands.
            """),
        .in(.location(.yourHouse)),
        .capacity(5),
        .isContainer,
        .isOpenable,
        .isTakable
    )

    /// Fresh sourdough bread
    let sourdoughBoule = Item(
        id: .sourdoughBoule,
        .name("sourdough boule"),
        .adjectives("warm", "fresh"),
        .description("""
            A round loaf of sourdough bread, still warm from the oven. Its crust is golden-brown
            and perfectly crispy, and the wonderful aroma makes your mouth water.
            """),
        .in(.item(.basket)),
        .isTakable,
        .size(2)
    )

    /// Butter crock - will be important in later acts
    let butterCrock = Item(
        id: .butterCrock,
        .name("butter crock"),
        .adjectives("fresh"),
        .description("""
            A small ceramic crock filled with fresh, creamy butter. The butter is perfectly
            spreadable and has a rich, golden color that speaks of quality cream.
            """),
        .in(.item(.basket)),
        .isTakable,
        .size(1)
    )

    /// Cherry preserves - another ingredient for the future discovery
    let preserveJar = Item(
        id: .preserveJar,
        .name("preserve jar"),
        .synonyms("jar", "preserves"),
        .adjectives("cherry"),
        .description("""
            A glass jar filled with ruby-red cherry preserves. The preserves gleam like jewels
            in the light, and you can see whole cherry pieces suspended in the thick, sweet mixture.
            """),
        .in(.item(.basket)),
        .isTakable,
        .size(1)
    )

    /// Blackberry lemonade - the key to the puzzle solution
    let lemonade = Item(
        id: .lemonade,
        .name("lemonade jug"),
        .synonyms("jug", "glass"),
        .adjectives("blackberry"),
        .description("""
            A clear glass jug filled with freshly squeezed blackberry lemonade. The deep purple
            liquid has a lovely fruity aroma, and condensation beads on the outside of the glass
            from the cool temperature.
            """),
        .in(.location(.yourHouse)),
        .isTakable,
        .isWearable, // Can be balanced on head!
        .size(3)
    )

    /// Gnusto the dog - the "item" that creates the puzzle
    let gnustoDog = Item(
        id: .gnustoDog,
        .name("Gnusto"),
        .adjectives("little", "excited"),
        .description("""
            Berzio's little dog is a bundle of energy and enthusiasm. She's a medium-sized mutt
            with floppy ears and bright, intelligent eyes. Her tail wags constantly, and she
            seems to think that everything in the world exists solely for her entertainment.
            """),
        .in(.nowhere), // Starts nowhere, appears when gate is opened
        .isTakable, // Can be picked up to solve puzzle
        .size(15) // Too big for containers
    )

    // MARK: - Event Handlers (Simplified for now)

    /// Prevents leaving your house without food for Berzio.
    let yourHouseHandler = LocationEventHandler { engine, event in
        switch event {
        case .beforeTurn(let command):
            switch command.verb {
            case .go:
//                engine.playerInventory
                let basket = try await engine.item(.basket)
                let lemonade = try await engine.item(.lemonade)
                return switch (basket.parent, lemonade.parent) {
                case (.player, .player):
                    nil
                case (.player, _):
                    ActionResult("""
                        You're halfway out the door when you remember the glass jug of blackberry lemonade sitting inside. Berzio does get terribly absorbed in his work — sometimes for days at a time — and the lemonade is just as important as the food. Your neighbors have always included something to drink with their weekly offerings. After all, even brilliant thaumaturges need proper hydration.
                        """)
                case (_, .player):
                    ActionResult("""
                        You pause at your doorstep, the jug of blackberry lemonade in hand. What else did you need to bring? Oh right. The warm sourdough boule, fresh butter, and cherry preserves are still waiting inside — carefully prepared for your weekly visit to Berzio. It's a tradition that goes back generations in your family, and you'd hate to break it now. Grandmother always said the magic that keeps the neighborhood so pleasant depends on these small kindnesses.
                        """)
                default:
                    ActionResult("""
                        You pause at your doorstep, empty-handed. The warm sourdough boule, fresh butter, and cherry preserves are still waiting inside — carefully prepared for your weekly visit to Berzio. It's a tradition that goes back generations in your family, and you'd hate to break it now. Grandmother always said the magic that keeps the neighborhood so pleasant depends on these small kindnesses.
                        """)
                }

            default:
                return nil
            }
//        case .onEnter:
//            let basket = try await engine.item(.basket)
//            let lemonade = try await engine.item(.lemonade)
//
//            let baseDescription = """
//                    Hi
//                    """

        default:
            return nil
        }
    }

    /// Simple bridge message when entering
    let stoneBridgeHandler = LocationEventHandler { engine, event in
        // TODO: Add bridge wobbling description once we have access to output methods
        return nil
    }

    /// Gnusto behavior (simplified)
    let gnustoDogHandler = ItemEventHandler { engine, event in
        // TODO: Add Gnusto interference logic once we have access to proper APIs
        return nil
    }

    /// Lemonade wearing behavior (simplified)
    let lemonadeHandler = ItemEventHandler { engine, event in
        // TODO: Add head-balancing logic once we have access to flag setting
        return nil
    }

    /// Gate puzzle logic (simplified)
    let berziosGateHandler = LocationEventHandler { engine, event in
//        switch event {
//        case .beforeTurn(let command):
//            <#code#>
//        case .afterTurn(let command):
//            <#code#>
//        case .onEnter:
//            <#code#>
//        }
        // This is where Gnusto escapes!
        guard await engine.isFlagSet(.gnustoEscaped) != true else {
            return nil
        }

        let gnusto = try await engine.item(.gnustoDog)

        // Move Gnusto from nowhere to the gate area
        return ActionResult(
            message: """
                But before you can take a step into Berzio's garden, his little dog Gnusto
                slips out, dashing between your ankles and into the lane. Overjoyed to have
                company, she skitters about wriggling this way and that.
                """,
            stateChanges: [
                await engine.setFlag(.gnustoEscaped),
                await engine.move(gnusto, to: .location(.berziosGate)),
            ]
        )
    }

    /// Garden success message (simplified)
    let berziosGardenHandler = LocationEventHandler { engine, event in
        // TODO: Add completion celebration once we have proper score and output APIs
        return nil
    }
}
