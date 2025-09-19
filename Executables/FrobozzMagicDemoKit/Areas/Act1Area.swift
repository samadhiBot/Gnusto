import GnustoEngine

/// # Act I: "The Helpful Neighbor" - Core Engine Mechanics Demonstration
///
/// This area demonstrates the foundational features of the Gnusto Interactive Fiction Engine:
/// - Basic `Location` and `Item` definitions
/// - Container mechanics and item properties
/// - Simple `ItemEventHandler` and `LocationEventHandler` usage
/// - Standard action handling and scope resolution
///
/// ## Story Summary
///
/// You're bringing food to your neighbor Berzio when his excited dog Gnusto escapes from the gate.
/// The puzzle involves managing your full hands while catching the dog, demonstrating item juggling
/// mechanics and the engine's scope and interaction systems.
///
/// ## Engine Features Showcased
///
/// - Location exits and navigation
/// - Container items with capacity limits
/// - Item properties (takable, wearable, etc.)
/// - Event handlers with naming conventions
/// - State tracking and conditional responses
/// - Parser interactions and disambiguation
struct Act1Area {

    // MARK: - Locations

    /// Your house - the starting location where the journey begins
    let yourCottage = Location(
        id: .yourCottage,
        .name("Your Cottage"),
        .description(
            """
            Your cozy cottage sits beside the gentle creek that winds
            through this peaceful stretch of countryside. Stone walls weathered
            to warm honey catch the morning light, while climbing roses frame
            the windows in cheerful abundance. Your garden spreads in neat,
            contented rows--vegetables and herbs growing with the quiet
            satisfaction that comes from good soil and careful tending.

            The creek babbles softly as it flows past, its clear water catching
            glints of sunlight. To the east, Berzio's magical bridge spans the
            water in graceful, fitted stone arcs that hover just above the
            surface. Beyond the bridge, the winding country road continues its
            meandering path between the scattered cottages of your small
            community.
            """
        ),
        .exits(.east(.stoneBridge)),
        .inherentlyLit
    )

    /// The magical bridge showing signs of Berzio's hunger
    let stoneBridge = Location(
        id: .stoneBridge,
        .name("Stone Bridge"),
        .description(
            """
            Berzio's magical bridge arcs gracefully over the creek, its
            fitted stones rising several feet above the water before descending
            to meet the banks on either side. Usually these stones hold steady
            as solid ground, but today they wobble and bob beneath your feet
            like a boat in gentle swells. Feeble sparks crackle between the
            gaps--clear signs that Berzio hasn't been eating properly again.

            Your cottage lies to the west, while the country road continues east
            toward Berzio's gate.
            """
        ),
        .exits(.west(.yourCottage), .east(.countryRoad)),
        .inherentlyLit
    )

    /// The lovely country road between houses
    let countryRoad = Location(
        id: .countryRoad,
        .name("Country Road"),
        .description(
            """
            This stretch of the winding lane captures the very essence of
            pastoral charm. Ancient oaks form a natural canopy overhead, their
            branches heavy with summer leaves, while wildflowers bloom in
            glorious abundance along the verges. The hedges grow in perfectly
            maintained shapes--all thanks to Berzio's beneficent influence
            keeping the countryside in gentle order.

            Your stone bridge lies to the west, while Berzio's gate beckons
            invitingly to the north.
            """
        ),
        .exits(.west(.stoneBridge), .north(.berziosGate)),
        .inherentlyLit
    )

    /// Berzio's gate - where the main puzzle takes place
    let berziosGate = Location(
        id: .berziosGate,
        .name("Berzio's Gate"),
        .description(
            """
            The wrought-iron gate stands before you, its intricate metalwork
            bearing patterns that seem to shift and dance when you're not
            looking directly at them. A worn brass latch holds it closed,
            polished smooth by countless hands over the years.

            Through the bars to the north, you glimpse peaceful herb plots
            arranged in mystical patterns and various pieces of magical
            apparatus resting on wooden tables. The country road continues
            south, leading back toward your bridge and home.
            """
        ),
        .exits(.south(.countryRoad), .north(.berziosGarden)),
        .inherentlyLit
    )

    /// Berzio's garden - the goal location
    let berziosGarden = Location(
        id: .berziosGarden,
        .name("Berzio's Garden"),
        .description(
            """
            You've successfully entered Berzio's peaceful sanctuary. Herb
            plots spread before you in intricate, mystical patterns that seem to
            hold deeper meaning than mere gardening. Various pieces of magical
            apparatus sit on wooden tables--alembics, retorts, and devices whose
            purposes remain charmingly mysterious. A well-worn path leads north
            toward Berzio's cottage, where warm light glows invitingly in the
            windows.

            Little Gnusto bounces around happily among the herbs, clearly
            delighted to be back in her proper home. The gate stands open to the
            south, should you need to return to the road.
            """
        ),
        .exits(.south(.berziosGate)),
        .inherentlyLit
    )

    // MARK: - Items

    /// The basket containing food items - demonstrates container mechanics
    let basket = Item(
        id: .basket,
        .name("wicker basket"),
        .description(
            """
            A sturdy wicker basket lined with cheerful gingham cloth--the
            perfect size for carrying neighborly offerings. The weave is tight
            and even, speaking of skilled craftsmanship, and the handles are
            worn smooth from years of faithful service. It feels comfortably
            familiar in your hands, like an old friend ready for another
            journey.
            """
        ),
        .in(.yourCottage),
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
        .description(
            """
            A round loaf of sourdough bread, still warm from your oven this
            morning. Its crust gleams golden-brown and perfectly crispy, while
            the wonderful aroma makes your mouth water even though you baked it
            yourself. The surface bears those telltale bubbles and blisters that
            mark truly excellent bread--Berzio will be delighted.
            """
        ),
        .in(.item(.basket)),
        .isTakable,
        .size(2)
    )

    /// Butter crock - will be important in later acts
    let butterCrock = Item(
        id: .butterCrock,
        .name("butter crock"),
        .adjectives("fresh"),
        .description(
            """
            A small ceramic crock filled with fresh, creamy butter churned
            just yesterday. The butter gleams with that rich, golden color that
            speaks of quality cream from contented cows. It's perfectly
            spreadable and smells of sweet pastures and morning sunshine--exactly
            what good bread deserves.
            """
        ),
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
        .description(
            """
            A glass jar filled with ruby-red cherry preserves that gleam
            like jewels in the light. Whole cherry pieces float suspended in the
            thick, sweet mixture, and you can almost taste the summer sunshine
            that went into their making. The preserves will complement the bread
            and butter perfectly.
            """
        ),
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
        .description(
            """
            A clear glass jug filled with freshly squeezed blackberry
            lemonade. The deep purple liquid has a lovely fruity aroma that
            makes your mouth water, and condensation beads on the outside of the
            glass from the cool temperature. It's exactly the sort of refreshing
            drink that a hard-working thaumaturge needs on a warm day.
            """
        ),
        .in(.yourCottage),
        .isTakable,
        .isWearable,  // Can be balanced on head!
        .size(3)
    )

    /// Gnusto the dog - the "item" that creates the puzzle
    let gnustoDog = Item(
        id: .gnustoDog,
        .name("Gnusto"),
        .adjectives("little", "excited"),
        .description(
            """
            Berzio's little dog is a bundle of pure energy and enthusiasm
            wrapped in a medium-sized, floppy-eared package. She's clearly a
            mutt of excellent character, with bright, intelligent eyes and a
            tail that never stops wagging. Her expression suggests she believes
            the entire world exists solely for her entertainment--and she might
            just be right.
            """
        ),
        .in(.nowhere),  // Starts nowhere, appears when gate is opened
        .isTakable,  // Can be picked up to solve puzzle
        .size(15)  // Too big for containers
    )

    // MARK: - Event Handlers (Simplified for now)

    /// Prevents leaving your house without food for Berzio.
    let yourCottageHandler = LocationEventHandler(for: .yourCottage) {
        beforeTurn(.move) { context, command in
            let basket = await context.item(.basket)
            let lemonade = await context.item(.lemonade)
            return switch await (basket.parent, lemonade.parent) {
            case (.player, .player):
                nil
            case (.player, _):
                ActionResult(
                    """
                    You're halfway out the door when you remember the glass jug of blackberry lemonade sitting inside. Berzio does get terribly absorbed in his work--sometimes for days at a time--and the lemonade is just as important as the food. Your neighbors have always included something to drink with their weekly offerings. After all, even brilliant thaumaturges need proper hydration.
                    """)
            case (_, .player):
                ActionResult(
                    """
                    You pause at your doorstep, the jug of blackberry lemonade in hand. What else did you need to bring? Oh right. The warm sourdough boule, fresh butter, and cherry preserves are still waiting inside--carefully prepared for your weekly visit to Berzio. It's a tradition that goes back generations in your family, and you'd hate to break it now. Grandmother always said the magic that keeps the neighborhood so pleasant depends on these small kindnesses.
                    """)
            default:
                ActionResult(
                    """
                    You pause at your doorstep, empty-handed. The warm sourdough boule, fresh butter, and cherry preserves are still waiting inside--carefully prepared for your weekly visit to Berzio. It's a tradition that goes back generations in your family, and you'd hate to break it now. Grandmother always said the magic that keeps the neighborhood so pleasant depends on these small kindnesses.
                    """)
            }
        }
    }

    /// Simple bridge message when entering
    let stoneBridgeHandler = LocationEventHandler(for: .stoneBridge) {
        // TODO: Add bridge wobbling description once we have access to output methods
    }

    /// Gnusto behavior (simplified)
    let gnustoDogHandler = ItemEventHandler(for: .gnustoDog) {
        // TODO: Add Gnusto interference logic once we have access to proper APIs
    }

    /// Lemonade wearing behavior (simplified)
    let lemonadeHandler = ItemEventHandler(for: .lemonade) {
        // TODO: Add head-balancing logic once we have access to flag setting
    }

    /// Gate puzzle logic (simplified)
    let berziosGateHandler = LocationEventHandler(for: .berziosGate) {
        onEnter { context in
            // This is where Gnusto escapes!
            guard await !context.engine.hasFlag(.gnustoEscaped) else {
                return nil
            }

            let gnusto = await context.item(.gnustoDog)

            // Move Gnusto from nowhere to the gate area
            return ActionResult(
                """
                But before you can take a step into Berzio's garden, his little dog Gnusto
                slips out, dashing between your ankles and into the lane. Overjoyed to have
                company, she skitters about wriggling this way and that.
                """,
                await context.engine.setFlag(.gnustoEscaped),
                gnusto.move(to: .location(.berziosGate))
            )
        }
    }

    /// Garden success message (simplified)
    let berziosGardenHandler = LocationEventHandler(for: .berziosGarden) {
        // TODO: Add completion celebration once we have proper score and output APIs
    }
}
