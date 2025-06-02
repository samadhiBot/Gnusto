# FrobozzMagicDemoKit - Complete Game Structure

## Overview

The Frobozz Magic Demo Kit demonstrates the Gnusto Interactive Fiction Engine through a three-act narrative that progresses from simple mechanics to advanced features. The story follows the accidental discovery of the legendary GNUSTO spell, maintaining the engine's core principle: **small domestic moments leading to world-changing consequences**.

## Design Philosophy

### Progressive Complexity

- **Act I**: Core mechanics and basic puzzle solving
- **Act II**: Time-based events and custom behaviors
- **Act III**: Complex systems integration and multiple solution paths

### Teaching Strategy

Each act introduces new engine features through natural story progression, with extensive comments showing developers:

- How features are implemented
- Why design decisions were made
- How to extend or modify behaviors
- Best practices for game structure

---

## Act I: "The Helpful Neighbor"

**Theme**: Simple domestic kindness
**Engine Focus**: Core mechanics and basic puzzle solving

### Story Summary

769 GUE. You're bringing food to your neighbor Berzio, the reclusive thaumaturge. His magical bridge shows signs of his hunger (wobbling stones, feeble sparks). At his gate, his excited dog Gnusto escapes and you must get her back inside while managing your full hands.

### Puzzle Mechanics

The core challenge demonstrates basic item management:

1. **Parser Challenge**: "Gnusto" confuses the parser ("What do you want to gnusto?")
2. **Item Juggling**: Must put things down to catch the dog, but:
   - Put down `basket` → Gnusto thinks it's for her
   - Put down `lemonade` → Gnusto will knock it over
   - **Solution**: Put lemonade on head, then manage basket and dog

### Engine Features Demonstrated

#### Core World Representation

```swift
struct Act1Area {
    // Locations with increasing complexity
    let yourHouse = Location(id: "yourHouse", ...)
    let stoneBridge = Location(id: "stoneBridge", ...)
    let countryRoad = Location(id: "countryRoad", ...)
    let berziosGate = Location(id: "berziosGate", ...)
    let berziosGarden = Location(id: "berziosGarden", ...)

    // Items with special behaviors
    let basket = Item(id: "basket", .container(capacity: 3), .takable)
    let lemonade = Item(id: "lemonade", .takable, .wearable) // Can balance on head!
    let gnustoDog = Item(id: "gnustoDog", .takable) // Very special item

    // Event handlers following naming convention
    let gnustoDogHandler = ItemEventHandler { engine, event in
        // Gnusto "helps" by trying to take things
    }

    let stoneBridgeHandler = LocationEventHandler { engine, event in
        // Wobbling effects, magical sparks
    }
}
```

#### Standard Action Handlers

- **Movement**: `GO`, directional commands
- **Item Manipulation**: `TAKE`, `DROP`, `PUT ON` (lemonade on head)
- **Examination**: `LOOK`, `EXAMINE`
- **Inventory**: `I`, `INVENTORY`

#### Scope & Accessibility

- Items in player's hands vs. on ground vs. in containers
- What Gnusto can "reach" and interfere with
- Line of sight and interaction rules

### Key Items

- `basket` - Container holding `sourdoughBoule`, `butterCrock`, `preserveJar`
- `lemonade` - Glass jug that can be balanced on head
- `gnustoDog` - Interactive NPC-like item with special behaviors
- `food items` - Individual components that spill later

### Locations

- `yourHouse` - Starting location with basic description
- `stoneBridge` - Magical bridge showing Berzio's hunger (wobbling, sparks)
- `countryRoad` - Transition area with lovely countryside descriptions
- `berziosGate` - The main puzzle location
- `berziosGarden` - Success location, peaceful garden

### Learning Outcomes

- Basic game structure and area organization
- Standard action handling and validation
- Simple state tracking and conditional responses
- Item properties and container mechanics

---

## Act II: "The Bureaucratic Tangle"

**Theme**: Encroaching bureaucracy disrupts simple kindness
**Engine Focus**: Time-based events and custom behaviors

### Story Summary

Just as you settle Gnusto in the garden, there's an official knock. A bored agent from the "Frobozz Animal Control Division" arrives with bureaucratic demands: 17-page forms, magical safety inspections, recitation of the "Flathead Oath of Allegiance." This delay causes the food to warm and spill in Berzio's workshop, leading to the accidental discovery.

### New Mechanics

The bureaucratic encounter introduces time pressure and custom interactions:

1. **Time Pressure**: Food items have spoilage timers
2. **Custom Verbs**: `FILL OUT`, `PRESENT`, `RECITE`, `BRIBE`
3. **Dynamic Responses**: Official gets increasingly impatient
4. **Background Events**: Workshop activity continues during delays

### Engine Features Demonstrated

#### Time-Based Events

```swift
// Fuse: Butter softening creates urgency
let butterSoftening = FuseDefinition(id: "butterSoftening", initialTurns: 20) { engine in
    await engine.ioHandler.print("The butter is becoming dangerously soft in the warm sun!")
    let change = StateChange(
        entityId: .item("butterCrock"),
        attribute: .hasAttribute("melted"),
        newValue: .bool(true)
    )
    try engine.applyStateChange(change)
}

// Daemon: Official's increasing impatience
let impatientOfficial = DaemonDefinition(id: "impatientOfficial", frequency: 3) { engine in
    let patience = await engine.getGlobalFlag("officialPatience")
    if patience > 0 {
        let messages = [
            "*tap tap*",
            "The official checks his timepiece.",
            "\"Bureaucracy waits for no one!\"",
            "The official drums his fingers impatiently."
        ]
        await engine.ioHandler.print(messages.randomElement()!)
        await engine.setGlobalFlag("officialPatience", patience - 1)
    }
}

// Daemon: Workshop atmosphere
let workshopAmbience = DaemonDefinition(id: "workshopAmbience", frequency: 5) { engine in
    let messages = [
        "Magical apparatus bubbles quietly in the workshop.",
        "Ancient tomes rustle their pages in a mystical breeze.",
        "A distant sound of thaumaturgical experimentation echoes."
    ]
    await engine.ioHandler.print(messages.randomElement()!)
}
```

#### Custom Action Handlers

```swift
struct FillOutActionHandler: ActionHandler {
    func validate(context: ActionContext) async throws {
        guard let directObject = context.command.directObject,
              case .item(let itemID) = directObject,
              itemID == "bureaucraticForm" else {
            throw ActionResponse.prerequisiteNotMet("Fill out what? You need the proper forms.")
        }

        let formProgress = await context.engine.getItemAttribute(itemID, "progress")?.toInt ?? 0
        guard formProgress < 17 else {
            throw ActionResponse.prerequisiteNotMet("The form is already completely filled out.")
        }
    }

    func process(context: ActionContext) async throws -> ActionResult {
        // Complex form completion logic with multiple steps
        // Each page requires different information
        return ActionResult(
            message: "You begin the tedious process of form completion...",
            stateChanges: [
                StateChange(
                    entityId: .item("bureaucraticForm"),
                    attribute: .hasAttribute("progress"),
                    newValue: .int(currentProgress + 1)
                )
            ]
        )
    }
}

struct ReciteActionHandler: ActionHandler {
    func validate(context: ActionContext) async throws {
        let hasOath = await context.engine.getGlobalFlag("knowsFlatheadOath")
        guard hasOath else {
            throw ActionResponse.prerequisiteNotMet("You don't know the Flathead Oath of Allegiance. Perhaps you should ask about it first.")
        }
    }

    func process(context: ActionContext) async throws -> ActionResult {
        return ActionResult("""
            You begin reciting the absurdly long Flathead Oath:
            "I, a humble subject of the Great Underground Empire, do solemnly swear..."
            [The recitation continues for several minutes]

            The official nods approvingly. "Acceptable. Though your pronunciation of
            'thaumaturgical sovereignty' could use work."
            """)
    }
}
```

#### Dynamic Location Behaviors

```swift
let bureaucraticCheckpointHandler = LocationEventHandler { engine, event in
    switch event {
    case .beforeTurn(let command):
        let officialPresent = await engine.isItemInLocation("impatientOfficial", "bureaucraticCheckpoint")
        if officialPresent && command.verb != .fillOut && command.verb != .present {
            return ActionResult("The official clears his throat meaningfully. \"The forms, citizen. The forms must be completed.\"")
        }
        return nil
    case .onEnter:
        await engine.ioHandler.print("The official has set up a small folding table with an impressive stack of forms.")
        return nil
    case .afterTurn:
        return nil
    }
}
```

### New Items

- `bureaucraticForm` - 17-page form with completion tracking
- `officialBadge` - Can be examined for bureaucratic details
- `timepiece` - Official's device, shows increasing urgency
- `folding table` - Temporary bureaucratic setup

### New Locations

- `bureaucraticCheckpoint` - Temporary official station at the gate
- `berziosWorkshop` - Workshop where the spill occurs (initially locked/private)

### Learning Outcomes

- Time-based event management (`FuseDefinition`, `DaemonDefinition`)
- Custom action handler implementation
- Dynamic location and item behaviors
- Complex state tracking and conditional logic
- Background atmosphere and narrative pacing

---

## Act III: "The Discovery"

**Theme**: Scientific wonder emerges from chaos
**Engine Focus**: Complex systems integration

### Story Summary

The bureaucratic delay causes the food to spill in Berzio's workshop in a specific sequence (butter, preserves, lemonade). When Berzio tries to cast a Pulver spell from a scroll, the scroll disintegrates but the spell appears faintly on the stained notebook pages. Through experimentation, the player can discover the process for creating spell books.

### Advanced Mechanics

The discovery phase showcases the engine's most sophisticated features:

1. **Recipe System**: Complex ingredient combinations and sequences
2. **Spell Mechanics**: Scroll-to-book transfer with potency calculations
3. **Experimentation**: Multiple solution paths with varying outcomes
4. **Dynamic Descriptions**: Items and locations change based on magical state
5. **Scoring System**: Points awarded for understanding, not just completion

### Engine Features Demonstrated

#### Complex Custom Verbs

```swift
struct CastActionHandler: ActionHandler {
    func validate(context: ActionContext) async throws {
        guard let directObject = context.command.directObject,
              case .item(let scrollID) = directObject else {
            throw ActionResponse.prerequisiteNotMet("Cast what? You need to specify a scroll.")
        }

        let isScroll = await context.engine.hasItemProperty(scrollID, .scroll)
        guard isScroll else {
            throw ActionResponse.prerequisiteNotMet("You can only cast spells from scrolls.")
        }

        let isMemorized = await context.engine.getItemAttribute(scrollID, "memorized")?.toBool ?? false
        guard isMemorized else {
            throw ActionResponse.prerequisiteNotMet("You must first memorize the spell before casting it.")
        }
    }

    func process(context: ActionContext) async throws -> ActionResult {
        guard case .item(let scrollID) = context.command.directObject else {
            throw ActionResponse.internalEngineError("Validated item disappeared")
        }

        let spellType = await context.engine.getItemAttribute(scrollID, "spellType")?.toString ?? "unknown"
        let potency = await context.engine.getItemAttribute(scrollID, "potency")?.toInt ?? 50

        // Check for nearby impregnated paper (the magic happens here!)
        let nearbyItems = await context.engine.itemsInCurrentLocation()
        let impregnatedNotebook = nearbyItems.first { item in
            item.hasAttribute("butterStained") &&
            item.hasAttribute("preserveStained") &&
            item.hasAttribute("lemonadeStained")
        }

        if let notebook = impregnatedNotebook {
            return processSpellTransfer(scrollID: scrollID, notebook: notebook, potency: potency)
        } else {
            return processNormalSpellCasting(spellType: spellType, potency: potency)
        }
    }

    private func processSpellTransfer(scrollID: ItemID, notebook: Item, potency: Int) -> ActionResult {
        let transferPotency = max(potency / 2, 25) // Initial transfer is half potency

        return ActionResult(
            message: """
                As you cast the \(spellType) spell, the scroll crumbles to dust as usual. But wait!
                Something extraordinary happens. Faint letters begin to appear on the stained pages
                of the notebook, like a developing Polaroid print. The spell is transferring to the paper!

                The magical writings glow softly for a moment, then settle into the page. You have
                discovered something remarkable.
                """,
            stateChanges: [
                StateChange(entityId: .item(scrollID), attribute: .removeFromGame, newValue: .bool(true)),
                StateChange(entityId: .item(notebook.id), attribute: .addSpell(spellType), newValue: .int(transferPotency)),
                StateChange(entityId: .global, attribute: .setFlag("discoveredSpellTransfer"), newValue: .bool(true))
            ],
            sideEffects: [
                SideEffect(type: .scheduleEvent, targetID: .global, parameters: ["message": "Berzio emerges from the workshop, drawn by the unusual magical resonance."])
            ]
        )
    }
}

struct ExperimentActionHandler: ActionHandler {
    func process(context: ActionContext) async throws -> ActionResult {
        // Complex experimentation logic
        // Players can try different combinations and sequences
        // Success depends on understanding the proper order and proportions
    }
}
```

#### Dynamic Attribute Computation

```swift
// Register dynamic spell potency calculation
dynamicAttributeRegistry.registerItemCompute(attributeID: "spellPotency") { item, gameState in
    let baseIngredients = ["butter", "preserves", "lemonade"]
    let hasAllIngredients = baseIngredients.allSatisfy { ingredient in
        item.hasAttribute("\(ingredient)Stained")
    }

    if hasAllIngredients {
        let orderBonus = calculateSequenceBonus(item: item, gameState: gameState)
        let qualityBonus = calculateIngredientQuality(item: item, gameState: gameState)
        return .int(50 + orderBonus + qualityBonus) // Base 50%, up to 100%
    }

    return .int(0)
}

// Validate spell transfer attempts
dynamicAttributeRegistry.registerItemValidate(attributeID: "canReceiveSpell") { item, newValue in
    guard item.hasProperty(.paper) else { return false }

    let isImpregnated = item.hasAttribute("butterStained") &&
                       item.hasAttribute("preserveStained") &&
                       item.hasAttribute("lemonadeStained")

    return isImpregnated
}
```

#### ItemEventHandlers with Complex Logic

```swift
let magicNotebookHandler = ItemEventHandler { engine, event in
    switch event {
    case .beforeTurn(let command):
        if command.verb == .examine {
            let description = await generateDynamicNotebookDescription(engine: engine)
            return ActionResult(description)
        }
        return nil

    case .afterTurn(let command):
        if command.verb == .cast && await engine.getGlobalFlag("discoveredSpellTransfer") {
            await engine.scheduleEvent("berzioReaction", delay: 1)
        }
        return nil
    }
}

func generateDynamicNotebookDescription(engine: GameEngine) async -> String {
    let notebook = await engine.itemSnapshot(with: "magicNotebook")!

    var description = "A massive thousand-page notebook filled with thaumaturgical notes and diagrams."

    if notebook.hasAttribute("butterStained") {
        description += " The pages are stained with butter"
        if notebook.hasAttribute("preserveStained") {
            description += " and cherry preserves"
            if notebook.hasAttribute("lemonadeStained") {
                description += " and blackberry lemonade"
            }
        }
        description += ". The stains have created an unusual pattern on the paper."
    }

    let spellCount = notebook.attributes.keys.filter { $0.starts(with: "spell_") }.count
    if spellCount > 0 {
        description += " Magical writings glow faintly on \(spellCount) of the stained pages."
    }

    return description
}
```

### New Items

- `magicNotebook` - 1000-page notebook with dynamic staining and spell storage
- `pulverScroll` - The scroll that triggers the discovery
- `butterCrock` - Now with melting/staining properties
- `preserveJar` - Staining and sequence tracking
- `lemonadeJug` - Final component in the sequence
- `variousScrolls` - Additional scrolls for experimentation
- `thaumaturgicalApparatus` - Workshop equipment

### New Locations

- `berziosWorkshopInterior` - Fully accessible workshop with complex interactions
- `storageAlcove` - Where scrolls are kept
- `experimentationArea` - Where players can try different combinations

### Scoring System

- **Basic Discovery** (50 pts): Witness the accidental spell transfer
- **Understanding Sequence** (75 pts): Realize the order matters (butter → preserves → lemonade)
- **Perfecting Process** (90 pts): Achieve full potency transfer
- **Independent Innovation** (100 pts): Discover additional improvements or variations

### Learning Outcomes

- Complex custom action implementation
- Dynamic attribute systems and computation
- Multi-step puzzle design with multiple solution paths
- Advanced state tracking and scoring
- Integration of all previous features into cohesive systems

---

## Progressive Feature Integration

### File Organization Strategy

```
Executables/FrobozzMagicDemoKit/
├── STORY.md # This document
├── ACT1.md # Existing story outline
├── README.md # Existing overview
├── TONE_BACKSTORY.md # Existing lore
├── main.swift # Entry point
├── Areas/
│ ├── Act1Area.swift # Basic mechanics demonstration
│ ├── Act2Area.swift # Time events and custom actions
│ └── Act3Area.swift # Complex systems integration
├── ActionHandlers/
│ ├── FillOutActionHandler.swift
│ ├── ReciteActionHandler.swift
│ ├── CastActionHandler.swift
│ └── ExperimentActionHandler.swift
├── EventHandlers/
│ ├── BureaucraticHandlers.swift
│ ├── MagicalHandlers.swift
│ └── WorkshopHandlers.swift
├── TimeEvents/
│ ├── Act2Fuses.swift # Butter melting, official patience
│ ├── Act2Daemons.swift # Workshop ambience, bureaucratic pressure
│ └── Act3Events.swift # Discovery reactions, spell effects
└── FrobozzMagicDemoKit.swift # Main GameBlueprint implementation
```

### Implementation Phases

1. **Phase 1**: Complete Act I implementation

   - Basic area structure
   - Standard action handlers
   - Simple puzzle mechanics
   - Foundation for Acts II & III

2. **Phase 2**: Add Act II complexity

   - Time-based event system
   - Custom action handlers
   - Dynamic location behaviors
   - Bureaucratic encounter mechanics

3. **Phase 3**: Implement Act III discovery

   - Complex spell system
   - Dynamic attribute computation
   - Multiple solution paths
   - Comprehensive scoring

4. **Phase 4**: Polish and documentation
   - Extensive code comments
   - Developer tutorials
   - Engine feature demonstrations
   - Performance optimization

## Educational Value

Each act serves as a tutorial for specific engine capabilities:

- **New Game Developers**: Start with Act I to understand basics
- **Intermediate Developers**: Study Act II for advanced features
- **Expert Developers**: Examine Act III for complex system design

The progression ensures developers can learn incrementally while seeing how features combine to create rich, interactive experiences.

---

## ZIL Homages & Easter Eggs

Throughout all acts, we maintain connection to IF classics:

### Phrases & Responses

- "It is pitch black. You are likely to be eaten by a grue." (dark workshop)
- "You are carrying..." (inventory formatting)
- "I don't understand that." (parser failures)
- "You can't see that here." (scope violations)

### Mechanical Homages

- Light source requirements for certain areas
- Container logic matching Zork behavior
- Score notifications matching classic format
- Turn counting and time passage

### Hidden References

- `xyzzy` command produces appropriate response
- Grue encounters in truly dark areas
- References to the Great Underground Empire
- Flathead bureaucracy callbacks

The demo celebrates IF history while showcasing modern engine capabilities, honoring the past while building for the future.
