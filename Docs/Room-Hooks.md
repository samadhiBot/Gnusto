# Room Hooks in Gnusto

This document explains how to use the Room Hooks feature in your Gnusto games.

## Overview

Room Hooks allow rooms to respond to specific lifecycle events:

1. \`onEnter\`: Triggered when a player enters the room
2. \`beforeAction\`: Triggered before any action is processed in the room
3. \`afterAction\`: Triggered after any action is processed in the room

## Example

```swift
// Example of using room hooks
let magicRoom = Object.room(
    id: "magicRoom",
    name: "Magic Room",
    description: "A mysterious room with shimmering walls."
)

// Add hooks to the magic room
let magicRoomWithHooks = Object.addRoomHooks(
    to: "magicRoom",
    onEnter: { world in
        return [.showText("As you enter, the walls begin to glow brighter!")]
    },
    beforeAction: { action, world in
        // Prevent certain actions in this room
        if case .command(.take(let objectID)) = action,
           objectID == "magicCrystal" {
            return [.showText("The crystal floats away from your grasp!")]
        }
        return nil // Allow other actions to proceed normally
    },
    afterAction: { action, world in
        // Add special effects after certain actions
        if case .command(.look) = action {
            return [.showText("The room seems to respond to your gaze.")]
        }
        return []
    }
)

// Register the room with hooks
world.register(magicRoomWithHooks)
```
