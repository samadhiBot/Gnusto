import Foundation
import Markdown

// MARK: - Item Descriptions

extension GameEngine {
    /// Generates a formatted description string for a specific item property.
    /// Retrieves the raw string using `engine.getDynamicItemValue` and applies formatting.
    ///
    /// - Parameters:
    ///   - itemID: The unique identifier of the item.
    ///   - key: The `AttributeID` representing the desired description (e.g., `.longDescription`).
    ///   - engine: The game engine providing access to state and dynamic values.
    /// - Returns: The formatted description string, or a default message if unavailable.
    public func generateDescription(
        for itemID: ItemID,
        key: AttributeID,
        engine: GameEngine
    ) async -> String {
        formatDescription(
            (try? await engine.fetch(itemID, key)) ??
            defaultItemDescription(for: itemID, key: key, engine: engine)
        )
    }

    /// Provides a default description string when a dynamic or static one isn't found.
    ///
    /// - Parameters:
    ///   - itemID: The unique identifier of the item.
    ///   - key: The `AttributeID` representing the desired description (e.g., `.longDescription`).
    ///   - engine: The game engine providing access to state and dynamic values.
    /// - Returns: The formatted default description string.
    private func defaultItemDescription(
        for itemID: ItemID,
        key: AttributeID,
        engine: GameEngine
    ) -> String {
        let item = engine.item(itemID)
        return switch key {
        case .longDescription:
            "You see nothing special about \(item?.withDefiniteArticle ?? "it")."
        case .shortDescription:
            "\(item?.withIndefiniteArticle.capitalizedFirst ?? "An item")."
        case .firstDescription:
            "There is \(item?.withIndefiniteArticle ?? "something") here."
        case .readText:
            "There is nothing written on \(item?.withDefiniteArticle ?? "it")."
        case .readWhileHeldText:
            "Holding \(item?.withDefiniteArticle ?? "it") reveals nothing special."
        default:
            "\(item?.withDefiniteArticle.capitalizedFirst ?? "It") seems indescribable."
        }
    }
}

// MARK: - Location Descriptions

extension GameEngine {
    /// Generates a formatted description string for a specific location property.
    /// Retrieves the raw string using `engine.getDynamicLocationValue` and applies formatting.
    ///
    /// - Parameters:
    ///   - locationID: The unique identifier of the location.
    ///   - key: The `AttributeID` representing the desired description (e.g., `.longDescription`).
    ///   - engine: The game engine providing access to state and dynamic values.
    /// - Returns: The formatted description string, or a default message if unavailable.
    public func generateDescription(
        for locationID: LocationID,
        key: AttributeID,
        engine: GameEngine
    ) async -> String {
        formatDescription(
            (try? await engine.fetch(locationID, key)) ??
            defaultLocationDescription(for: locationID, key: key, engine: engine)
        )
    }

    /// Provides a default description string when a dynamic or static one isn't found.
    private func defaultLocationDescription(
        for locationID: LocationID,
        key: AttributeID,
        engine: GameEngine
    ) -> String {
        // Consider fetching location name
        // let locationName = await engine.locationSnapshot(locationID)?.name ?? "place"
        switch key {
        case .longDescription:
            return "You are in a nondescript location."
        case .shortDescription:
            return "A location."
        default:
            return "It seems indescribable."
        }
    }
}

// MARK: - Formatting

extension GameEngine {
    /// Formats a raw description string using Markdown.
    private func formatDescription(_ rawMarkdown: String) -> String {
        Document(parsing: rawMarkdown)
            .format()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
