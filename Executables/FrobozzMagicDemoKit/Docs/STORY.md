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
    // ...
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
    // ...
```

#### Custom Action Handlers

```swift
    // ...
```

#### Dynamic Location Behaviors

```swift
    // ...
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

- Time-based event management (`Fuse`, `Daemon`)
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
    // ...
```

#### Dynamic Property Computation

```swift
    // ...
```

#### ItemEventHandlers with Complex Logic

```swift
    // ...
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
- Dynamic property systems and computation
- Multi-step puzzle design with multiple solution paths
- Advanced state tracking and scoring
- Integration of all previous features into cohesive systems


## Educational Value

Each act serves as a tutorial for specific engine capabilities:

- **New Game Developers**: Start with Act I to understand basics
- **Intermediate Developers**: Study Act II for advanced features
- **Expert Developers**: Examine Act III for complex system design

The progression ensures developers can learn incrementally while seeing how features combine to create rich, interactive experiences.
