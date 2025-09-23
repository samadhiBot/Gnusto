import Foundation

/// Handles the "DRINK" command for consuming liquids from various sources.
/// Separate from eating, this handles liquid consumption with proper container logic.
public struct DrinkActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .from, .indirectObject),
    ]

    public let synonyms: [Verb] = [.drink, .sip, .quaff, .imbibe]

    public let requiresLight: Bool = true

    public init() {}

    // MARK: - Action Processing Methods

    /// Processes the "DRINK" command.
    ///
    /// This action validates prerequisites and handles consuming liquids either directly
    /// or from containers. Drinkable items are typically removed after consumption.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Ensure we have a direct object
        guard let item = try await context.itemDirectObject() else {
            // Drink requires a direct object (what to drink)
            throw ActionResponse.doWhat(context)
        }

        let message =
            if let container = try await context.itemIndirectObject() {
                // Handle "drink water from bottle" syntax
                try await drinkItemFromContainer(context, item, container)
            } else if await item.isContainer {
                // Handle "drink [from] bottle" syntax
                try await drinkFromContainer(context, item)
            } else {
                // Handle "drink water" syntax
                try await drinkItem(context, item)
            }

        return await ActionResult(
            message,
            item.setFlag(.isTouched)
        )
    }
}

// MARK: - Private helpers

extension DrinkActionHandler {
    private func drinkItemFromContainer(
        _ context: ActionContext,
        _ contents: ItemProxy,
        _ container: ItemProxy
    ) async throws -> String {
        // Verify the item is actually in the specified container
        if await !container.contents.contains(contents) {
            return await context.msg.takeItemNotInContainer(
                contents.withDefiniteArticle,
                container: container.withDefiniteArticle
            )
        }

        // Item might be drinkable, but refuse here and override in specific game code
        return await context.msg.drinkDrinkableDenied(
            contents.withDefiniteArticle
        )
    }

    private func drinkFromContainer(
        _ context: ActionContext,
        _ container: ItemProxy
    ) async throws -> String {
        // Find anything drinkable in the container
        var drinkableContents: ItemProxy?
        for item in await container.contents where await item.hasFlag(.isDrinkable) {
            drinkableContents = item
            break
        }
        guard let drinkableContents else {
            return await context.msg.nothingToDrinkIn(
                container.withDefiniteArticle
            )
        }

        // Contents might be drinkable, but refuse here and override in specific game code
        return await context.msg.drinkDrinkableDenied(
            drinkableContents.withDefiniteArticle
        )
    }

    private func drinkItem(
        _ context: ActionContext,
        _ item: ItemProxy
    ) async throws -> String {
        guard await item.hasFlag(.isDrinkable) else {
            return await context.msg.drinkUndrinkableDenied(
                item.withDefiniteArticle
            )
        }

        // Item might be drinkable, but refuse here and override in specific game code
        return await context.msg.drinkDrinkableDenied(
            item.withDefiniteArticle
        )
    }
}
