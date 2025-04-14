import Foundation

// Note: Assumes World, Effect, UserInput, Object, Component types are available.

/// Handles the "inventory" command.
struct InventoryHandler {

    static func handle(context: CommandContext) -> [Effect]? {
        // Ignore any parameters ("inventory sword")
        // let command = context.userInput // Not needed for basic inventory
        let world = context.world // Extract for convenience

        let inventory = world.find(in: world.player.id)

        if inventory.isEmpty {
            return [.showText("You aren't carrying anything.")]
        }

        var inventoryText = "You are carrying:"

        // Sort items alphabetically by name for consistent listing
        let sortedInventory = inventory.sorted { obj1, obj2 in
            let name1 = obj1.find(DescriptionComponent.self)?.name ?? ""
            let name2 = obj2.find(DescriptionComponent.self)?.name ?? ""
            return name1 < name2
        }

        for item in sortedInventory {
            if let desc = item.find(DescriptionComponent.self) {
                // Check if the item is worn using the now-defined Flag.worn
                let isWorn = item.find(ObjectComponent.self)?.flags.contains(Flag.worn) ?? false
                let wornSuffix = isWorn ? " (being worn)" : ""
                inventoryText += "\n  \(desc.name)\(wornSuffix)"
            }
        }

        return [.showText(inventoryText)]
    }
}

// No longer need TODO for Flag.worn
