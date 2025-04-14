# Gnusto

A modern Swift interactive fiction game engine.

The Gnusto game engine aims to:

1. Facilitate creation of faithful translations of the original ZIL-based classics, accurately replicating the original gameplay mechanics and stories.
2. Provide the best possible foundation and ergonomics for creating new works of interactive fiction
3. Allow games to easily customize and extend the built-in functionality
4. Utilize modern Swift features and optimizations under the hood.
5. Adhere to the highest standards of software craftsmanship, with clean, SOLID, maintainable, and well-tested code (80-90% coverage).

### Proposed Project Structure

We need a structure that supports the Gnusto-based implementation of one or more ZIL-based games, alongside the Gnusto engine itself.

```
Gnusto/
├── Documentation/          # Project documentation, design docs, etc.
├── Package.swift           # Xcode project file
├── Sources/
│   ├── GnustoEngine/         # The reusable text adventure engine
│   │   ├── Core/           # Fundamental types (GameState, Action, etc.)
│   │   ├── IO/             # Input/Output handling
│   │   ├── Parsing/        # Command parsing logic
│   │   └── /* Other Engine Modules */
│   ├── ZILGame/            # Gnusto-specific implementation
│   │   ├── Actors/         # Player, NPCs (like the Troll)
│   │   ├── Data/           # Game data (Rooms, Items, Verbs specific to ZILGame)
│   │   ├── Handlers/       # Logic for specific ZILGame actions/events
│   │   └── Main.swift      # Application entry point
│   └── /* Potentially shared utility modules */
└── Tests/
    ├── GnustoEngineTests/    # Tests for the reusable engine
    └── ZILGameTests/      # Tests for the Gnusto-specific logic
```

### Core Domain Models (Initial Thoughts)

Now, let's brainstorm some fundamental types. We'll start simple and refine as we go. These would likely reside initially within `GnustoEngine/Core` or `ZILGame/Data`, depending on their generality.

1.  **`Location` (or `Room`)**: Represents a distinct place in the game world.

    - `id`: A unique identifier (e.g., `"westOfHouse"`).
    - `name`: The display name (e.g., "West of House").
    - `description`: Text shown when the player enters or looks around.
    - `exits`: A way to map directions (e.g., `Direction.north`) to other `Location` IDs.
    - `items`: A collection of `Item`s currently in the location.
    - `properties`: Flags or attributes (e.g., `isLit`, `isOutside`).

2.  **`Item` (or `GameObject`)**: Represents objects the player can interact with.

    - `id`: Unique identifier (e.g., `"brassLantern"`).
    - `name`: Primary noun used to refer to the item (e.g., "lantern").
    - `description`: Text shown when the item is examined.
    - `synonyms`: Other words used to refer to the item (e.g., ["lamp", "light"]).
    - `properties`: Attributes (e.g., `isTakable`, `isContainer`, `isLightSource`, `isOpenable`).
    - `contents`: If it's a container, the `Item`s inside.

3.  **`Player`**: Represents the user's state.

    - `currentLocationID`: The ID of the `Location` the player is in.
    - `inventory`: A collection of `Item`s the player is carrying.
    - `score`: The player's current score.
    - `moves`: The number of turns taken.

4.  **`Verb`**: Represents the action the player wants to perform.

    - `id`: Unique identifier (e.g., `"take"`).
    - `synonyms`: Different ways to invoke the verb (e.g., ["get", "pick up"]).

5.  **`Command`**: Represents the parsed player input.

    - `verb`: The identified `Verb`.
    - `directObject`: The primary `Item` or target of the action (optional).
    - `indirectObject`: The secondary `Item` or target (optional, e.g., "put _lantern_ in _case_").

6.  **`GameState`**: An aggregate representing the entire state of the game world at a point in time. This is crucial for saving/loading and potentially for concurrency management.

    - `locations`: A dictionary mapping `Location.ID` to `Location` instances.
    - `items`: A dictionary mapping `Item.ID` to `Item` instances (potentially including their current location or container).
    - `player`: The `Player` state.
    - `flags`: Game-wide flags or variables (e.g., `trollDefeated`).

7.  **`Engine`**: The central orchestrator.

    - Responsible for the main game loop: Read input -> Parse -> Execute -> Update State -> Print Output.
    - Holds or manages access to the `GameState`.

8.  **`Parser`**: Responsible for taking raw string input and attempting to turn it into a `Command`. This involves:
    - Tokenization.
    - Verb identification.
    - Noun identification (mapping words to `Item`s or `Location` features).
    - Handling ambiguity and unknown words.

### Reference Materials

```
Docs
└── References
    ├── A Mind Forever Voyaging
    ├── Cloak of Darkness
    ├── Hitchhikers Guide to the Galaxy
    └── Zork 1
```

Having original Infocom source files from [Historical Source](https://github.com/historicalsource/) as references is invaluable. They provide concrete examples of how Infocom structured their data and logic, which significantly informs the Swift implementation. The progression from Cloak of Darkness to Zork, Hitchhiker's, and AMFV provides a clear path for evolving the engine's complexity.

Cloak of Darkness, in particular, with its explicit ZIL definitions for objects, properties, flags, and routines, provides immediate insights.

### Roadmap

Looking at the structure of classic ZIL games like Cloak of Darkness and Zork 1, and comparing that to what we've built so far, here are some other foundational elements or systems besides the Parser Implementation that are currently missing or very rudimentary in GnustoEngine:

1. Game Data Definition & Loading:

   - ZIL: Had its own definition language within .zil files to declare objects (items), rooms (locations), routines, globals, syntax, etc.
   - Gnusto: Currently, we define objects, locations, and vocabulary mostly within Swift code, either directly in tests or via initializers (GameState.initial). A robust engine needs a way to load game data from external files (e.g., JSON, YAML, or a custom format) separate from the engine code itself. This allows different games to run on the same engine.

2. Event/Time System (Daemons, Fuses, Clocks):

   - ZIL: Relied heavily on timed events (CLOCKER daemon, FUSE system in Zork) to manage things like lamp timers, character actions occurring over time, or periodic world events (events.zil, gclock.zil).
   - Gnusto: Our GameEngine has a simple turn-based loop but no concept of timed events, daemons running in the background each turn, or actions that take multiple turns.

3. Advanced Scope Resolution / Reachability:

   - ZIL: Had sophisticated routines (scope.zil) to determine what the player could "see" or interact with, considering light levels (darkness/light sources), open/closed/transparent containers, player location, and potentially other factors.
   - Gnusto: Our current handlers implement very basic scope checks (e.g., Take checks if the item is in the current location or an accessible open container). We lack a centralized scope resolution system, especially regarding light.

4. NPC / Actor System:

   - ZIL: Supported non-player characters (often called actors or routines associated with PERSONBIT objects) that could have their own behaviors, potentially move between rooms, or react to player actions (orphan.zil hints at this).
   - Gnusto: We have ItemProperty.person, but no system for managing NPC state, behavior routines, or interactions beyond basic object properties.

5. Pronoun Resolution Logic:

   - ZIL: Had dedicated logic (pronouns.zil) to handle resolving pronouns like "it" and "them" based on recent actions and context.
   - Gnusto: GameState has a pronouns dictionary placeholder, but no Parser or ActionHandler logic currently updates or uses it.

6. Save/Restore System:

   - ZIL: Supported saving and restoring game state.
   - Gnusto: We have Codable conformance on core types, laying some groundwork, but no actual save/restore mechanism implemented in the GameEngine.
