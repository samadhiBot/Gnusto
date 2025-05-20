\*Guarantee void if used near grues, volcanoes, or during Implementor Incantations.

## Design Philosophy

The `FrobozzMagicDemoKit` class (the heart of the Demo Kit) demonstrates:

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
  - Implementing static descriptions and dynamic descriptions (potentially using `DescriptionHandler`).
  - Utilizing `LocationProperty` (e.g., `.light`, `.outside`, `.waterSource`).
  - Configuring exits:
    - Standard directional exits (`.north`, `.south`, etc.).
    - Conditional exits (e.g., requiring an item or a specific game state).
    - Hidden or initially unavailable exits.
  - Managing "globals": items consistently present or accessible within a location.
  - Demonstrating room-specific action overrides using `RoomActionHandler`.
- **Items (`Item`)**:
  - Defining items with unique IDs, names, adjectives, and synonyms for robust parsing.
  - Crafting descriptive text for items, including static and dynamic descriptions.
  - Assigning `ItemProperty` flags (e.g., `.takable`, `.container`, `.wearable`, `.lightSource`, `.readable`, `.food`, `.weapon`).
  - Specifying initial item placement (`ParentEntity`): in a location, inside a container, carried by the player, or `.nowhere`.
  - Defining and using item attributes (e.g., `size`, `capacity`, `strength`, `charges`).
  - Implementing item-specific action overrides using `ObjectActionHandler`.
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

### 3. Action Processing (`ActionHandler`, `EnhancedActionHandler`, `GameEngine`)

- **Standard Actions**:
  - Implementing and showcasing a suite of common actions:
    - Movement: `GO NORTH`, `SOUTH`, `ENTER CAVE`, `UP`.
    - Item Manipulation: `TAKE KEY`, `DROP SWORD`, `PUT TREASURE IN CHEST`, `OPEN DOOR`, `CLOSE BOX`, `EXAMINE STATUE`, `READ SCROLL`.
    - Inventory: `INVENTORY`, `I`.
    - Interaction: `ATTACK GRUE`, `USE ROPE ON HOOK`, `GIVE WATER TO MAN`.
    - Sensory: `LOOK`, `LISTEN`.
- **Enhanced Actions (`EnhancedActionHandler`)**:
  - Demonstrating actions with pre-conditions (e.g., needing a key to open a lock).
  - Showing how actions return an `ActionResult` to signal success, failure, or specific outcomes, and how these modify `GameState`.
- **Custom Actions**:
  - Defining new game-specific verbs and their corresponding `ActionHandler` or `EnhancedActionHandler` implementations.
  - Overriding default action behaviors for specific items or locations via `DefinitionRegistry` (`ObjectActionHandler`, `RoomActionHandler`).

### 4. Scope, Visibility, and Interaction (`ScopeResolver`)

- **Light and Darkness**:
  - Demonstrating the effect of `ItemProperty.lightSource` on visibility.
  - Implementing "pitch black" rooms and the classic grue warning/encounter.
- **Container Logic**:
  - Showing how `ScopeResolver` handles visibility of items within open vs. closed containers.
- **Accessibility**:
  - Illustrating how the resolver determines which items are in scope for interaction (player's inventory, current location, accessible containers).

### 5. Time-Based Events and Daemons (`FuseDefinition`, `DaemonDefinition`, `GameEngine.tickClock`)

- **Daemons (`DaemonDefinition`)**:
  - Creating background processes that run each turn or at set intervals (e.g., lantern dimming progressively, atmospheric messages, NPC behavior).
- **Fuses (`FuseDefinition`)**:
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

### 7. Game Customization and Extensibility (`DefinitionRegistry`, `DescriptionHandlerRegistry`)

- **Definition Registry (`DefinitionRegistry`)**:
  - Registering custom `FuseDefinition`s and `DaemonDefinition`s for unique timed events.
  - Registering game-specific `ObjectActionHandler`s and `RoomActionHandler`s to tailor interactions.
- **Description Handler Registry (`DescriptionHandlerRegistry`)**:
  - Implementing and registering custom `DescriptionHandler`s to provide dynamic, state-dependent descriptions for items and locations.

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
