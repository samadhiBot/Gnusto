# State Management Refactoring Plan

This document outlines the phased plan to refactor the Gnusto Engine's state management for increased robustness, testability, and clarity, while maintaining good developer ergonomics.

## Phase 1: Centralized State Mutation via `GameState`

**Goal:** Ensure all modifications to the game state are channeled through a single, controlled mechanism within the `GameState` struct, guaranteeing that every change is recorded in the `changeHistory`.

**Steps:**

- [x] **Generalize `StateChange` Identifier:**
  - [x] Define `EntityID` enum (`.item(ItemID)`, `.location(LocationID)`, `.player`, `.global`) in `ActionResult.swift`.
  - [x] Update `StateChange` struct to use `entityId: EntityID` instead of `objectId: ItemID`.
  - [x] Review and update `StatePropertyKey` enum cases to align with `EntityID` (e.g., ensure keys clearly map to item, location, player, or global state). Add missing keys like `.locationExits` if needed, along with corresponding `StateValue` cases.
- [x] **Implement `GameState.apply(_:)`:**
  - [x] Add `public private(set)` access control to core state properties in `GameState` (`items`, `locations`, `flags`, `player`, `activeFuses`, `activeDaemons`, `pronouns`, `gameSpecificState`, `changeHistory`).
  - [x] Create a `public mutating func apply(_ change: StateChange) throws` method within `GameState`.
  - [x] Move the `switch change.propertyKey` logic from `GameEngine.applyStateChange` into `GameState.apply`.
  - [x] Ensure `GameState.apply` validates `change.oldValue` against the current state before applying the mutation.
  - [x] Ensure `GameState.apply` appends the `change` to `changeHistory` _after_ a successful mutation.
- [x] **Refactor `GameEngine`:**
  - [x] Modify `GameEngine.applyStateChange` to be a simple forwarding call: `try gameState.apply(change)`.
  - [x] Identify all methods/code locations within `GameEngine` that directly modify `gameState` or its contained objects (e.g., `updateItemParent`, `setFlagValue`, player move increments, fuse/daemon updates in `tickClock`, etc.).
  - [x] Refactor these locations to:
    - Determine the `oldValue`.
    - Construct the appropriate `StateChange` object (using `EntityID`, `StatePropertyKey`, `oldValue`, `newValue`).
    - Call `try gameState.apply(change)` instead of performing direct mutation.
  - [x] Create ergonomic helper methods in `GameEngine` (e.g., `applyFlagChange`, `applyScoreUpdate`, `applyItemMove`) that encapsulate `StateChange` creation and the call to `gameState.apply` for common mutations needed by game logic (daemons, fuses, handlers).
  - [x] Ensure `GameEngine.execute` correctly calls `gameState.apply(change)` for changes originating from `EnhancedActionHandler` `ActionResult`s (confirming the current implementation which looks correct).
- [x] **Testing:**
  - [x] Add comprehensive unit tests for `GameState.apply` covering all `StatePropertyKey` cases, including `oldValue` validation.
  - [x] Update/add integration tests to ensure actions and engine operations correctly modify state and update `changeHistory` via the new mechanism.

## Phase 2: Convert Core Models to Structs

**Goal:** Leverage value semantics for `Item` and `Location` to further enhance predictability, simplify `Sendable` conformance, and remove the need for snapshot types. (To be undertaken _after_ Phase 1 is complete and stable).

**Steps:**

- [ ] **Convert `Item` to Struct:**
  - [ ] Change `Item` declaration from `class` to `struct`.
  - [ ] Update all code that interacts with `Item` instances to handle value semantics (mutations will require replacing the instance in `GameState.items`).
  - [ ] Adjust `GameState.apply` logic for item-related keys to replace the item struct in the dictionary.
- [ ] **Convert `Location` to Struct:**
  - [ ] Change `Location` declaration from `class` to `struct`.
  - [ ] Update all code that interacts with `Location` instances to handle value semantics.
  - [ ] Adjust `GameState.apply` logic for location-related keys to replace the location struct in the dictionary.
- [ ] **Remove Snapshot Types:**
  - [ ] Delete `ItemSnapshot.swift`.
  - [ ] Delete `LocationSnapshot.swift`.
  - [ ] Update all code (primarily in `GameEngine`) that used snapshots to use the `Item` and `Location` structs directly.
- [ ] **Review `Sendable` Conformance:**
  - [ ] Verify `Item`, `Location`, and `GameState` conform to `Sendable` correctly.
- [ ] **Testing:**
  - [ ] Update existing tests to reflect the use of structs instead of classes/snapshots.
  - [ ] Add tests specifically verifying value semantics (ensuring mutations don't have unintended side effects).
