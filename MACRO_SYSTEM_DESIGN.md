# Gnusto Macro System Design 🚀

*The Buttonless Mouse Philosophy Applied to Interactive Fiction*

## Vision: Ultimate Simplicity

Following Steve Jobs' philosophy of eliminating unnecessary complexity, the Gnusto macro system achieves the ultimate in game definition simplicity. No more manual registration, no more boilerplate, no more giant structs with meaningless properties.

## The Dream: Complete Game in 10 Lines

```swift
@GameBlueprint(
    title: "The Frobozz Magic Demo Kit",
    introduction: "769 GUE. You are a neighbor of Berzio...",
    maxScore: 100,
    startingLocation: .yourCottage
)
struct FrobozzMagicDemoKit {
    // Everything else discovered automatically! ✨
}
```

## System Architecture

### 1. Convention-Based Discovery

The system discovers content by **convention**, not configuration:

- **Game Areas**: All `*Area` types in the module (e.g., `Act1Area`, `Act2Area`)
- **Items/Locations**: All `@GameItem`/`@GameLocation` marked properties
- **Event Handlers**: All `@ItemEventHandler`/`@LocationEventHandler` marked properties
- **Time Events**: All `@GameFuse`/`@GameDaemon` marked properties

### 2. Automatic ID Generation

Property names become IDs automatically:

```swift
@GameItem
static let sourdoughBoule = Item(...)
// Generates: ItemID("sourdoughBoule")

@GameLocation
static let berziosGate = Location(...)
// Generates: LocationID("berziosGate")
```

### 3. Cross-File Extension Support

Content can be organized across multiple files:

```
Act1Area/
├── Act1Area.swift           # @GameArea declaration
├── Act1Area+Items.swift     # Item definitions
├── Act1Area+Locations.swift # Location definitions
├── Act1Area+Handlers.swift  # Event handlers
└── Act1Area+TimeEvents.swift # Fuses and daemons
```

### 4. Compile-Time Validation

All cross-references are validated at compile time:

```swift
@GameItem
static let basket = Item(
    .in(.location(.yourCottage))  // ✅ Validated: yourCottage exists
)

@ItemEventHandler(.nonexistentItem)  // ❌ Compile error: Item not found
static let badHandler = ItemEventHandler { ... }
```

## Macro Specifications

### @GameBlueprint

The main game definition macro:

```swift
@GameBlueprint(
    title: String,
    introduction: String,
    maxScore: Int,
    startingLocation: LocationID
)
```

**Generates:**
- Complete `GameBlueprint` conformance
- Automatic area discovery (all `*Area` types)
- Constants structure
- Player initialization

### @GameArea

The area definition macro:

```swift
@GameArea
struct Act1Area {
    // Content discovered from extensions
}
```

**Generates:**
- Complete `AreaBlueprint` conformance
- All ID constants for items/locations in the area
- Discovery functions for items, locations, handlers, time events
- Cross-reference validation

### Content Definition Macros

#### @GameItem
```swift
@GameItem
static let itemName = Item(...)
```

#### @GameLocation
```swift
@GameLocation
static let locationName = Location(...)
```

#### @ItemEventHandler
```swift
@ItemEventHandler(.itemID)
static let handlerName = ItemEventHandler { ... }
```

#### @LocationEventHandler
```swift
@LocationEventHandler(.locationID)
static let handlerName = LocationEventHandler { ... }
```

#### @GameFuse / @GameDaemon
```swift
@GameFuse("fuse_id")
static let fuseName = FuseDefinition(...)

@GameDaemon("daemon_id")
static let daemonName = DaemonDefinition(...)
```

## Implementation Status

### ✅ Phase 1: Architecture & Design
- [x] Complete system design
- [x] Macro interface definitions
- [x] Blueprint protocol updates
- [x] Example implementations
- [x] File organization strategy

### ⏳ Phase 2: Core Macro Implementation
- [ ] `@GameBlueprint` macro implementation
- [ ] `@GameArea` macro implementation
- [ ] Module scanning for convention-based discovery
- [ ] ID generation from property names
- [ ] Cross-reference validation

### ⏳ Phase 3: Content Macros
- [ ] `@GameItem` / `@GameLocation` implementation
- [ ] `@ItemEventHandler` / `@LocationEventHandler` implementation
- [ ] `@GameFuse` / `@GameDaemon` implementation
- [ ] Compile-time validation for all cross-references

### ⏳ Phase 4: Advanced Features
- [ ] Dynamic attribute discovery
- [ ] Custom action handler discovery
- [ ] Vocabulary auto-generation enhancements
- [ ] Advanced validation (container logic, etc.)

## Example: Complete Area Definition

**Act1Area.swift**
```swift
@GameArea
struct Act1Area {
    // Everything discovered automatically
}
```

**Act1Area+Locations.swift**
```swift
extension Act1Area {
    @GameLocation
    static let yourCottage = Location(
        .name("Your Cottage"),
        .exits([.east: .to(.stoneBridge)]),
        .inherentlyLit
    )
    
    @GameLocation
    static let stoneBridge = Location(
        .name("Stone Bridge"),
        .exits([.west: .to(.yourCottage)])
    )
}
```

**Act1Area+Items.swift**
```swift
extension Act1Area {
    @GameItem
    static let basket = Item(
        .name("wicker basket"),
        .in(.location(.yourCottage)),
        .isContainer,
        .isTakable
    )
    
    @GameItem
    static let lemonade = Item(
        .name("lemonade jug"),
        .in(.location(.yourCottage)),
        .isTakable,
        .isWearable  // Can balance on head!
    )
}
```

**Act1Area+Handlers.swift**
```swift
extension Act1Area {
    @ItemEventHandler(.basket)
    static let basketHandler = ItemEventHandler { engine, event in
        // Custom basket logic
    }
    
    @LocationEventHandler(.yourCottage)
    static let cottageHandler = LocationEventHandler { engine, event in
        // Prevent leaving without food
    }
}
```

## Benefits

### For Game Developers
- **90% Less Boilerplate**: No manual registration or giant structs
- **Perfect Organization**: Spread content across logical files
- **Compile-Time Safety**: All errors caught at build time
- **Incremental Development**: Add content without touching main files
- **Zero Configuration**: Everything discovered by convention

### For Engine Development
- **Cleaner Architecture**: No more reflection-based discovery
- **Better Performance**: Compile-time generation vs runtime reflection
- **Type Safety**: Everything validated by Swift compiler
- **Future-Proof**: Easy to extend with new content types

### For Learning
- **Immediate Gratification**: Working games in minutes
- **Progressive Disclosure**: Start simple, add complexity gradually
- **Clear Organization**: Each file has a single, clear purpose

## Migration Strategy

The old and new systems can coexist during transition:

```swift
// Legacy approach still works
struct LegacyArea: AreaBlueprint {
    let room = Location(id: "room", ...)
    // ... manual implementation
}

// New macro approach
@GameArea
struct ModernArea {
    // Automatic everything!
}

// Mixed game
let state = GameState(
    areas: [LegacyArea.self, ModernArea.self],
    player: Player(in: .startingRoom)
)
```

## Future Possibilities

- **Hot Reloading**: Development-time recompilation when files change
- **Visual Editors**: GUI tools that generate macro-annotated code
- **Validation Extensions**: Custom validation rules via additional macros
- **Documentation Generation**: Auto-generated game maps and item lists
- **Localization Support**: Auto-discovery of translatable strings

---

*"Simplicity is the ultimate sophistication."* - Leonardo da Vinci

This macro system embodies the principle that the best interface is no interface at all. Game creators can focus entirely on their story and world-building, while the engine handles all the tedious details automatically. 