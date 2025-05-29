import GnustoEngine

/// # Act I: "The Helpful Neighbor" - Core Engine Mechanics Demonstration
///
/// This area demonstrates the power of the new macro-based game definition system.
/// With the `@GameArea` macro, all content is automatically discovered from extensions
/// across multiple files, making organization clean and flexible.
///
/// ## Story Summary
///
/// You're bringing food to your neighbor Berzio when his excited dog Gnusto escapes from the gate.
/// The puzzle involves managing your full hands while catching the dog, demonstrating item juggling
/// mechanics and the engine's scope and interaction systems.
///
/// ## Engine Features Showcased
///
/// - **Macro-Based Organization**: Items and locations defined in separate files
/// - **Automatic ID Generation**: No manual ID constant management
/// - **Compile-Time Validation**: All cross-references checked at build time
/// - **Cross-File Discovery**: Extensions automatically discovered
/// - **Container Mechanics**: Basket with capacity limits and food items
/// - **Wearable Items**: Lemonade jug that can be balanced on head
/// - **Event Handlers**: Custom behaviors for Gnusto dog and other interactions
/// - **State Tracking**: Global flags for puzzle progress
///
/// ## File Organization
///
/// ```
/// Act1Area.swift           # This file - @GameArea declaration
/// Act1Area+Locations.swift # All location definitions
/// Act1Area+Items.swift     # All item definitions  
/// Act1Area+Handlers.swift  # All event handlers
/// Act1Area+TimeEvents.swift # Fuses and daemons (future)
/// ```
///
/// ## Auto-Generated Content
///
/// The `@GameArea` macro automatically discovers and generates:
/// - Location and Item ID constants (`.yourCottage`, `.basket`, etc.)
/// - AreaBlueprint conformance with all required static properties
/// - Cross-reference validation between items and locations
/// - Event handler associations based on macro annotations
/// - Time event registrations for fuses and daemons

@GameArea
struct Act1Area {
    // That's it! Everything else is discovered automatically from extensions:
    // 
    // ✅ Locations from Act1Area+Locations.swift (@GameLocation)
    // ✅ Items from Act1Area+Items.swift (@GameItem)  
    // ⏳ Event handlers from Act1Area+Handlers.swift (@ItemEventHandler/@LocationEventHandler)
    // ⏳ Time events from Act1Area+TimeEvents.swift (@GameFuse/@GameDaemon)
    //
    // All ID constants (.yourCottage, .basket, etc.) are auto-generated
    // All cross-references (.in(.location(.yourCottage))) are validated at compile time
    // All AreaBlueprint conformance is automatically generated
}
