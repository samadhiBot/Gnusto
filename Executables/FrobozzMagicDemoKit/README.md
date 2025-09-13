\*Guarantee void if used near grues, volcanoes, or during Implementor Incantations.

## Design Philosophy

The `FrobozzMagicDemoKit` struct (the heart of the Demo Kit) demonstrates:

1.  Setting up a complete game with the engine (some assembly required)
2.  Defining magical game content (locations, items, verbs)
3.  Implementing custom spell-like behavior through game hooks
4.  Managing time-based enchantments with fuses and daemons
5.  Testing the user-friendliness (ergonomics) of the engine for client games

### Adding More Magic to the Demo Kit

- Everything in the Demo Kit should be intentional, serving to demonstrate some piece of engine functionality (or "magic").
- The Demo Kit is the proving ground for engine functionality and ease-of-use.
- The Gnusto Interactive Fiction Engine is still under active development (pre 0.0.1!), so feel free to enhance and improve the engine whenever you find missing functionality or awkward enchantments.

## Engine Features to Demonstrate

This Demo Kit aims to showcase the comprehensive capabilities of the Gnusto Interactive Fiction Engine. Below is a technical outline of features we will implement and demonstrate:

### 1. Core World Representation (`Item`, `Location`, `GameState`)

- **Locations (`Location`)**:
  - Defining locations with unique IDs, names, and detailed descriptions.
  - Implementing static descriptions and dynamic descriptions (e.g., through custom logic or event handlers).
  - Utilizing `LocationProperty` (e.g., `.light`, `.outside`, `.waterSource`).
  - Configuring exits:
    - Standard directional exits (`.north`, `.south`, etc.).
    - Conditional exits (e.g., requiring an item or a specific game state).
    - Hidden or initially unavailable exits.
  - Managing "globals": items consistently present or accessible within a location.
  - Demonstrating room-specific event handling (e.g., `LocationEvent.beforeTurn`, `LocationEvent.onEnter`) using `LocationEventHandler` (configured in `GameBlueprint`).
- **Items (`Item`)**:
  - Defining items with unique IDs, names, adjectives, and synonyms for robust parsing.
  - Crafting descriptive text for items, including static and dynamic descriptions.
  - Assigning `ItemProperty` flags (e.g., `.takable`, `.container`, `.wearable`, `.lightSource`, `.readable`, `.food`, `.weapon`).
  - Specifying initial item placement (`ParentEntity`): in a location, inside a container, carried by the player, or `.nowhere`.
  - Defining and using item properties (e.g., `size`, `capacity`, `strength`, `charges`).
  - Implementing item-specific event handling (e.g., `ItemEvent.beforeTurn`, `ItemEvent.afterTurn`) using `ItemEventHandler` (configured in `GameBlueprint`).
- **Game State (`GameState`)**:
  - Tracking and modifying player status (current location, score, turn count, health/status effects).
  - Managing the player's inventory.
  - Reflecting dynamic item states (e.g., a lantern being lit or unlit, an open/closed container, charges remaining).
  - Tracking dynamic location states (e.g., "has been visited," "puzzle solved").
  - Utilizing global game flags for arbitrary boolean states.
  - (If applicable) Demonstrating game saving and loading via `Codable` conformance.

### 2. Player Input and Parsing (`Vocabulary`, `Parser`)

- **Vocabulary (`Vocabulary`)**:
  - Populating the vocabulary with nouns (for items, locations, significant game entities), verbs (standard and custom), adjectives, directions, and prepositions.
- **Parser (`Parser`)**:
  - Handling a variety of command structures:
    - Simple: `VERB`, `VERB NOUN` (e.g., `LOOK`, `TAKE LANTERN`)
    - Complex: `VERB ADJECTIVE NOUN`, `VERB NOUN PREPOSITION NOUN` (e.g., `OPEN RED CHEST`, `PUT COIN IN SLOT`)
  - Demonstrating the parser's disambiguation logic when noun phrases are ambiguous.
  - Providing clear error messages for unrecognized words or unparsable grammar.

### 3. Action Processing (`ActionHandler`, `GameEngine`)

- **Standard Actions**:
  - Implementing and showcasing a suite of common actions:
    - Movement: `GO NORTH`, `SOUTH`, `ENTER CAVE`, `UP`.
    - Item Manipulation: `TAKE KEY`, `DROP SWORD`, `PUT TREASURE IN CHEST`, `OPEN DOOR`, `CLOSE BOX`, `EXAMINE STATUE`, `READ SCROLL`.
    - Inventory: `INVENTORY`, `I`.
    - Interaction: `ATTACK GRUE`, `USE ROPE ON HOOK`, `GIVE WATER TO MAN`.
    - Sensory: `LOOK`, `LISTEN`.

**Action Results**:

- Demonstrating how `ActionHandler` methods (`validate`, `process`) can enforce pre-conditions.
- Showing how the `process` method returns an `ActionResult` to signal success, failure, or specific outcomes, and how these can lead to `StateChange`s applied to `GameState`.

### 4. Scope, Visibility, and Interaction (`ScopeResolver`)

- **Light and Darkness**:
  - Demonstrating the effect of `ItemProperty.lightSource` on visibility.
  - Implementing "pitch black" rooms and the classic grue warning/encounter.
- **Container Logic**:
  - Showing how `ScopeResolver` handles visibility of items within open vs. closed containers.
- **Accessibility**:
  - Illustrating how the resolver determines which items are in scope for interaction (player's inventory, current location, accessible containers).

### 5. Time-Based Events and Daemons (`Fuse`, `Daemon`, `GameEngine.tickClock`)

- **Daemons (`Daemon`)**:
  - Creating background processes that run each turn or at set intervals (e.g., lantern dimming progressively, atmospheric messages, NPC behavior).
- **Fuses (`Fuse`)**:
  - Implementing delayed, one-time events (e.g., a final lantern warning before it goes out, a timed puzzle element, a trap triggering).
  - Showing how these are scheduled and processed by `GameEngine.tickClock`.

### 6. Player Feedback and Output (`IOHandler`)

- **Text Output**:
  - Delivering clear and engaging game responses, descriptions, and messages.
  - Utilizing different text styles (if supported by `IOHandler`) for emphasis or clarity.
- **Status Display**:
  - (If part of `IOHandler`'s responsibility) Displaying a standard status line (current location, score, turns).
- **List Formatting**:
  - Presenting lists of items or visible objects in a readable format (e.g., "You can see a rusty key, a worn map, and a curious glint in the corner.").

### 7. Game Customization and Extensibility (`GameBlueprint`, `TimeRegistry`)

- **GameBlueprint**:
  - The primary way to customize a game.
  - Registering custom `ActionHandler` implementations for new verbs.
  - Providing game-specific `ItemEventHandler` and `LocationEventHandler` instances to tailor interactions with specific entities.
  - Supplying the game's `Vocabulary`.
  - Configuring the `TimeRegistry` with `Fuse`s and `Daemon`s.
  - Providing `DynamicPropertyProvider`s for complex, stateful item/location properties.
- **TimeRegistry (via `GameBlueprint`)**:
  - Registering custom `Fuse`s (for timed, one-off events) and `Daemon`s (for recurring background processes).

### 8. Advanced Gameplay Mechanics (Illustrative Examples)

- **Puzzles**:
  - Simple item-based puzzles (e.g., using a key to open a chest).
  - Puzzles requiring item combination or specific sequences of actions.
  - Puzzles based on environmental interaction or observation.
- **Conditional Logic**:
  - Implementing game responses and events that depend on `GameState` flags, item properties, or player actions.
- **Scoring**:
  - Demonstrating a simple scoring system tied to discovering locations, solving puzzles, or acquiring treasure.
- **(Optional) Basic NPCs**:
  - If feasible within the engine's current capabilities, demonstrating simple non-player characters with basic dialogue or reactive behaviors.

This outline will serve as a blueprint for developing the `FrobozzMagicDemoKit`, ensuring we thoroughly test and exemplify the Gnusto Engine's power and flexibility.

## Running the Demo Kit

Todo

## Demo Game Design

### Puzzle and Story Design

We should design at least a few puzzles/locations/items that showcase:

- Room and item events that trigger before/after turns or on entry.
- Items and locations with dynamic, state-dependent descriptions.
- Actions that demonstrate precondition checks and varying outcomes.
- Timed puzzles or background events (e.g., a lantern dimming, a guard's patrol, a spell wearing off).
- Custom verbs and parser disambiguation.
- Scoring and state tracking (e.g., tracking which puzzles are solved, treasures found).

### Teaching Moment

Each core feature should be easy to point to in the demo, so users can see how the engine supports it (and how to do it themselves).
