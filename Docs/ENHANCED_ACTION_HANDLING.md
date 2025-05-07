# Enhanced Action Handling System Design

## Overview

This document outlines the design for enhancing the existing Gnusto engine's action handling system. The goal is to build upon the current solid foundation while introducing more powerful capabilities for dynamic content and action handling.

## Current Architecture Analysis

### Existing Components

1. **Action Handling**

   - `ActionHandler` protocol with `perform(command:engine:)` method
   - `ObjectActionHandler` type for item-specific actions
   - Well-organized action handlers for common verbs

2. **State Management**

   - `GameState` class for overall game state
   - `Item` and `Location` types with properties
   - `AnyCodable` for flexible property values

3. **Command Processing**
   - `Command` type for representing player actions
   - `ScopeResolver` for object resolution

## Enhancement Strategy

### 1. Action Pipeline Enhancement

```swift
/// Enhanced ActionHandler protocol with pipeline support
public protocol ActionHandler: ActionHandler {
    /// Validate if the action can be performed
    func validate(command: Command, engine: GameEngine) async throws

    /// Process the action and return detailed results
    func process(command: Command, engine: GameEngine) async throws -> ActionResult

    /// Handle any post-action effects
    func postProcess(command: Command, engine: GameEngine, result: ActionResult) async throws
}

/// Result of an action execution with enhanced information
public struct ActionResult {
    /// Whether the action was successful
    public let success: Bool

    /// Message to display to the player
    public let message: String

    /// Any state changes that occurred
    public let stateChanges: [StateChange]

    /// Any side effects that need to be processed
    public let sideEffects: [SideEffect]
}

/// Represents a change in game state
public struct StateChange {
    /// The object being changed
    public let objectId: ItemID

    /// The property being modified
    public let property: String

    /// The new value
    public let value: AnyCodable
}

/// Represents a side effect of an action
public struct SideEffect {
    /// The type of side effect
    public let type: SideEffectType

    /// The target of the effect
    public let target: ItemID

    /// Any additional parameters
    public let parameters: [String: AnyCodable]
}
```

### 2. Dynamic Logic & State System

This system allows associating dynamic computation and validation logic with specific properties of Items or Locations, while storing the actual state values separately.

```swift
/// A strongly-typed identifier for game properties.
public struct AttributeID: Hashable, Codable, Sendable { /* ... */ }

/// The standard type for storing potentially dynamic state values.
public enum StateValue: Codable, Sendable { /* ... */ }

// --- Game Developer Interaction Points ---

/// Items store their specific state values using AttributeID keys.
/// (Example structure - actual might differ slightly)
public struct Item: Sendable, Codable {
    // ... other properties ...
    public var attributes: [AttributeID: StateValue]
}

/// Locations also store their state values.
public struct Location: Sendable, Codable {
    // ... other properties ...
    public var attributes: [AttributeID: StateValue]
}

/// Registry for dynamic behavior (part of GameBlueprint or DefinitionRegistry).
public struct DynamicAttributeRegistry: Sendable {
    /// Closure type for computing an item property's value.
    public typealias ItemComputeHandler =
        (@Sendable (Item, GameState) -> StateValue)
    /// Closure type for validating a new value for an item property.
    public typealias ItemValidateHandler =
        (@Sendable (Item, StateValue) -> Bool)

    // ... Similar types for Location handlers ...

    /// Registers a compute handler for a specific item property.
    public func registerItemCompute(
        key: AttributeID,
        handler: @escaping ItemComputeHandler
    ) { /* ... */ }

    /// Registers a validation handler for a specific item property.
    public func registerItemValidate(
        key: AttributeID,
        handler: @escaping ItemValidateHandler
    ) { /* ... */ }

    // ... Methods to retrieve handlers ...
}

/// Engine provides helpers to access values (handles registry lookup + state access).
public class GameEngine: Sendable {
    /// Gets the current value, checking compute handlers first.
    public func getDynamicItemValue(
        itemID: ItemID,
        key: AttributeID
    ) async -> StateValue? { /* ... */ }

    /// Sets a value after checking validate handlers and applying a StateChange.
    public func setDynamicItemValue(
        itemID: ItemID,
        key: AttributeID,
        newValue: StateValue
    ) async throws { /* ... */ }

    // ... Similar helpers for Locations ...
}
```

### 3. Action Context System

```swift
/// Context for action execution
public struct ActionContext {
    /// The command being executed
    public let command: Command

    /// The game engine instance
    public let engine: GameEngine

    /// The current game state
    public let state: GameState

    /// Any additional context data
    public let contextData: [String: AnyCodable]
}

/// Protocol for objects that can provide action context
public protocol ActionContextProvider {
    /// Get context for an action
    func getContext(for command: Command) async throws -> ActionContext
}
```

## Implementation Phases

### Phase 1: Core Enhancements

- [x] Extend `ActionHandler` protocol with pipeline support
- [x] Implement `ActionResult` and related types
- [x] Add state change tracking to `GameState`

### Phase 2: Dynamic Logic & State System

- [x] Define `AttributeID` type.
- [x] Create `DynamicAttributeRegistry` for compute/validate handlers.
- [x] Add `attributes: [AttributeID: StateValue]` to `Item` and `Location`.
- [x] Update `StatePropertyKey` and `GameState.apply` to handle changes to `attributes`.
- [x] Implement `GameEngine` helpers (`get/setDynamic...Value`) to orchestrate registry/state access.

### Phase 3: Context System

- [x] Implement `ActionContext` system
- [x] Add context providers for common scenarios
- [x] Integrate with existing action handlers

### Phase 4: Migration

- [x] Update existing action handlers to use new system
- [x] Add support for dynamic descriptions
- [ ] Implement state-dependent behavior

## Testing Strategy

1. **Unit Tests**

   - Test enhanced action handlers
   - Verify dynamic properties
   - Check context system

2. **Integration Tests**

   - Test action pipeline
   - Verify state changes
   - Check side effects

3. **Migration Tests**
   - Verify existing functionality
   - Test new features
   - Check performance impact

## Migration Guide

### For Action Handlers

1. **Simple Migration**

```swift
// Before
public struct SimpleActionHandler: ActionHandler {
    func perform(command: Command, engine: GameEngine) async throws {
        // Implementation
    }
}

// After
public struct ActionHandler: ActionHandler {
    func perform(command: Command, engine: GameEngine) async throws {
        try await validate(command: command, engine: engine)
        let result = try await process(command: command, engine: engine)
        try await postProcess(command: command, engine: engine, result: result)
    }

    // New methods
    func validate(command: Command, engine: GameEngine) async throws {
        // Validation logic
    }

    func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Processing logic
    }

    func postProcess(command: Command, engine: GameEngine, result: ActionResult) async throws {
        // Post-processing logic
    }
}
```

2. **Dynamic Properties**

```swift
// Before
item.attributes["isOpen"] = true

// After (Conceptual Example)
// 1. Define AttributeID
// extension AttributeID { static let isOpen = AttributeID("isOpen") }
// 2. Register validation handler (optional, during setup)
// registry.registerItemValidate(key: .isOpen) { item, newValue in ... }
// 3. Set value using engine helper (triggers validation & StateChange)
// try await engine.setDynamicItemValue(itemID: item.id, key: .isOpen, newValue: true,)
// 4. Get value using engine helper (checks compute handlers)
// let isOpen = await engine.getDynamicItemValue(itemID: item.id, key: .isOpen)?.toBool ?? false
```

## Conclusion

This enhanced design builds upon the existing Gnusto engine architecture while introducing more powerful capabilities for dynamic content and action handling. The design maintains backward compatibility while providing a path forward for more sophisticated game mechanics.
