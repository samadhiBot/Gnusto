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
   - `SearchScope` for defining search boundaries

## Enhancement Strategy

### 1. Action Pipeline Enhancement

```swift
/// Enhanced ActionHandler protocol with pipeline support
public protocol EnhancedActionHandler: ActionHandler {
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

### 2. Dynamic Property System

```swift
/// Enhanced property system for dynamic values
public struct DynamicProperty<T> {
    /// The current value
    public var value: T

    /// The handler for computing the value
    public let computeHandler: ((Item, GameState) -> T)?

    /// The handler for validating changes
    public let validateHandler: ((T) -> Bool)?
}

/// Protocol for objects that can have dynamic properties
public protocol DynamicPropertyContainer {
    /// Get a dynamic property
    func getDynamicProperty<T>(_ key: String) -> DynamicProperty<T>?

    /// Set a dynamic property
    func setDynamicProperty<T>(_ key: String, value: T) throws
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

- [ ] Extend `ActionHandler` protocol with pipeline support
- [ ] Implement `ActionResult` and related types
- [ ] Add state change tracking to `GameState`

### Phase 2: Dynamic Properties

- [ ] Implement `DynamicProperty` system
- [ ] Add support to `Item` and `Location`
- [ ] Create property change tracking

### Phase 3: Context System

- [ ] Implement `ActionContext` system
- [ ] Add context providers for common scenarios
- [ ] Integrate with existing action handlers

### Phase 4: Migration

- [ ] Update existing action handlers to use new system
- [ ] Add support for dynamic descriptions
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
public struct EnhancedActionHandler: EnhancedActionHandler {
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
item.properties["isOpen"] = true

// After
try item.setDynamicProperty("isOpen", value: true)
let isOpen = item.getDynamicProperty<Bool>("isOpen")
```

## Conclusion

This enhanced design builds upon the existing Gnusto engine architecture while introducing more powerful capabilities for dynamic content and action handling. The design maintains backward compatibility while providing a path forward for more sophisticated game mechanics.
