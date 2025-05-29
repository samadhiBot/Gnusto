import GnustoEngine

/// Location definitions for Act I: "The Helpful Neighbor"
///
/// This extension demonstrates the new macro-based approach to defining locations.
/// Each location is marked with `@GameLocation` and gets its ID auto-generated
/// from the property name.
extension Act1Area {
    
    /// Your house - the starting location where the journey begins
    @GameLocation
    static let yourCottage = Location(
        .name("Your Cottage"),
        .description("""
            Your cozy cottage sits beside the gentle creek that winds
            through this peaceful stretch of countryside. Stone walls weathered
            to warm honey catch the morning light, while climbing roses frame
            the windows in cheerful abundance. Your garden spreads in neat,
            contented rows—vegetables and herbs growing with the quiet
            satisfaction that comes from good soil and careful tending.

            The creek babbles softly as it flows past, its clear water catching
            glints of sunlight. To the east, Berzio's magical bridge spans the
            water in graceful, fitted stone arcs that hover just above the
            surface. Beyond the bridge, the winding country road continues its
            meandering path between the scattered cottages of your small
            community.
            """),
        .exits([
            .east: .to(.stoneBridge)  // Auto-generated ID reference
        ]),
        .inherentlyLit
    )

    /// The magical bridge showing signs of Berzio's hunger
    @GameLocation
    static let stoneBridge = Location(
        .name("Stone Bridge"),
        .description("""
            Berzio's magical bridge arcs gracefully over the creek, its
            fitted stones rising several feet above the water before descending
            to meet the banks on either side. Usually these stones hold steady
            as solid ground, but today they wobble and bob beneath your feet
            like a boat in gentle swells. Feeble sparks crackle between the
            gaps—clear signs that Berzio hasn't been eating properly again.

            Your cottage lies to the west, while the country road continues east
            toward Berzio's gate.
            """),
        .exits([
            .west: .to(.yourCottage),
            .east: .to(.countryRoad),
        ]),
        .inherentlyLit
    )

    /// The lovely country road between houses
    @GameLocation
    static let countryRoad = Location(
        .name("Country Road"),
        .description("""
            This stretch of the winding lane captures the very essence of
            pastoral charm. Ancient oaks form a natural canopy overhead, their
            branches heavy with summer leaves, while wildflowers bloom in
            glorious abundance along the verges. The hedges grow in perfectly
            maintained shapes—all thanks to Berzio's beneficent influence
            keeping the countryside in gentle order.

            Your stone bridge lies to the west, while Berzio's gate beckons
            invitingly to the north.
            """),
        .exits([
            .west: .to(.stoneBridge),
            .north: .to(.berziosGate),
        ]),
        .inherentlyLit
    )

    /// Berzio's gate - where the main puzzle takes place
    @GameLocation
    static let berziosGate = Location(
        .name("Berzio's Gate"),
        .description("""
            The wrought-iron gate stands before you, its intricate metalwork
            bearing patterns that seem to shift and dance when you're not
            looking directly at them. A worn brass latch holds it closed,
            polished smooth by countless hands over the years.

            Through the bars to the north, you glimpse peaceful herb plots
            arranged in mystical patterns and various pieces of magical
            apparatus resting on wooden tables. The country road continues
            south, leading back toward your bridge and home.
            """),
        .exits([
            .south: .to(.countryRoad),
            .north: .to(.berziosGarden),
        ]),
        .inherentlyLit
    )

    /// Berzio's garden - the goal location
    @GameLocation
    static let berziosGarden = Location(
        .name("Berzio's Garden"),
        .description("""
            You've successfully entered Berzio's peaceful sanctuary. Herb
            plots spread before you in intricate, mystical patterns that seem to
            hold deeper meaning than mere gardening. Various pieces of magical
            apparatus sit on wooden tables—alembics, retorts, and devices whose
            purposes remain charmingly mysterious. A well-worn path leads north
            toward Berzio's cottage, where warm light glows invitingly in the
            windows.

            Little Gnusto bounces around happily among the herbs, clearly
            delighted to be back in her proper home. The gate stands open to the
            south, should you need to return to the road.
            """),
        .exits([
            .south: .to(.berziosGate)
        ]),
        .inherentlyLit
    )
} 