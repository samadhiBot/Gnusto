import Foundation

// MARK: - Item Descriptions

extension GameEngine {
    /// Generates a formatted description string for a specific item attribute, typically
    /// used for different kinds of textual descriptions (e.g., general description,
    /// text revealed on reading).
    ///
    /// This method attempts to fetch a dynamic or static string value for the given `itemID`
    /// and `AttributeID` (e.g., `.description`, `.readText`) using the engine's `fetch`
    /// mechanism. If a string is found, it's trimmed of whitespace. If no specific string
    /// is found for the attribute, a context-appropriate default description is provided
    /// (e.g., "You see nothing special about the {item}" for `.description`).
    ///
    /// - Parameters:
    ///   - itemID: The `ItemID` of the item for which to generate a description.
    ///   - key: The `AttributeID` indicating the type of description requested (e.g.,
    ///          `.description`, `.shortDescription`, `.readText`).
    ///   - engine: The `GameEngine` instance, used for fetching dynamic values.
    ///             (Note: This parameter is often the same instance the method is called on).
    /// - Returns: A formatted description string.
    public func generateDescription(
        for itemID: ItemID,
        key: AttributeID,
        engine: GameEngine
    ) async -> String {
        let fetchedOrNil: String? = try? await engine.fetch(itemID, key)
        return if let actualDescription = fetchedOrNil {
            actualDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            await defaultItemDescription(
                for: itemID,
                key: key,
                engine: engine
            ).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    /// Provides a default description string for an item attribute when a specific one
    /// (dynamic or static) isn't found.
    ///
    /// This internal helper is called by `generateDescription(for:key:engine:)` for items.
    /// It returns standard fallback text based on the `AttributeID` (e.g., "You see
    /// nothing special about the {item}." if `key` is `.description`).
    private func defaultItemDescription(
        for itemID: ItemID,
        key: AttributeID,
        engine: GameEngine
    ) async -> String {
        let item = try? await engine.item(itemID)
        return switch key {
        case .description:
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
    /// Generates a formatted description string for a specific location attribute, typically
    /// its main description.
    ///
    /// This method attempts to fetch a dynamic or static string value for the given
    /// `locationID` and `AttributeID` (usually `.description`) using the engine's `fetch`
    /// mechanism. If a string is found, it's trimmed. If not, a default description like
    /// "You are in a nondescript location." is provided.
    ///
    /// - Parameters:
    ///   - locationID: The `LocationID` of the location.
    ///   - key: The `AttributeID` for the desired description (typically `.description`).
    ///   - engine: The `GameEngine` instance, used for fetching dynamic values.
    ///             (Note: This parameter is often the same instance the method is called on).
    /// - Returns: A formatted description string.
    public func generateDescription(
        for locationID: LocationID,
        key: AttributeID,
        engine: GameEngine
    ) async -> String {
        if let actualDescription = try? await engine.fetch(locationID, key) {
            actualDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            await defaultLocationDescription(
                for: locationID,
                key: key,
                engine: engine
            ).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    /// Provides a default description string for a location attribute when a specific one
    /// isn't found. This internal helper is called by the public `generateDescription` for locations.
    private func defaultLocationDescription(
        for locationID: LocationID,
        key: AttributeID,
        engine: GameEngine
    ) async -> String {
        // Consider fetching location name
        // let locationName = await engine.locationSnapshot(locationID)?.name ?? "place"
        switch key {
        case .description:
            return "You are in a nondescript location."
        case .shortDescription:
            return "A location."
        default:
            return "It seems indescribable."
        }
    }
}
