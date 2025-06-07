import Foundation

// MARK: - Location Descriptions

extension GameEngine {
    /// Fetches the string value of a dynamic or static attribute for a given location.
    ///
    /// Works like the item-specific `fetch` for strings, but targets a location attribute.
    /// Useful for dynamic location descriptions.
    ///
    /// - Parameters:
    ///   - attributeID: The `AttributeID` of the string attribute.
    ///   - locationID: The `LocationID` of the location.
    /// - Returns: The string value of the attribute.
    /// - Throws: `ActionResponse.invalidValue` if the attribute is not a string, does not exist,
    ///           or the location does not exist.
    public func attribute(
        _ attributeID: AttributeID,
        of locationID: LocationID
    ) async throws -> String {
        let value = await fetchStateValue(
            locationID: locationID,
            attributeID: attributeID
        )
        switch value {
        case .string(let stringValue):
            return stringValue
        default:
            throw ActionResponse.invalidValue("""
                Cannot fetch string value for \(locationID.rawValue).\(attributeID.rawValue): \
                \(value ?? .undefined)
                """)
        }
    }

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
    ///   - attributeID: The `AttributeID` for the desired description (typically `.description`).
    ///   - engine: The `GameEngine` instance, used for fetching dynamic values.
    ///             (Note: This parameter is often the same instance the method is called on).
    /// - Returns: A formatted description string.
    public func generateDescription(
        for locationID: LocationID,
        attributeID: AttributeID,
        engine: GameEngine
    ) async -> String {
        if let actualDescription = try? await engine.attribute(attributeID, of: locationID) {
            actualDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            await defaultDescription(
                for: locationID,
                attributeID: attributeID,
                engine: engine
            ).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    /// Checks whether the specified location is currently lit.
    ///
    /// A location is considered lit if it has the `.inherentlyLit` attribute set to `true`,
    /// or if an item with the `.lightSource` attribute set to `true` and also having its
    /// `.on` attribute `true` is present in the location (including being held by the player).
    /// This check is performed by the engine's `ScopeResolver`.
    ///
    /// - Parameter locationID: The `LocationID` of the location to check.
    /// - Returns: `true` if the location is determined to be lit, `false` otherwise.
    public func isLocationLit(at locationID: LocationID) async -> Bool {
        await scopeResolver.isLocationLit(locationID: locationID)
    }

    /// Retrieves an immutable copy (snapshot) of a specific location from the current game state.
    ///
    /// - Parameter id: The `LocationID` of the location to retrieve.
    /// - Returns: A `Location` struct representing a snapshot of the specified location.
    /// - Throws: An `ActionResponse.internalEngineError` if no `id` is provided or if the
    ///           specified `LocationID` does not exist in the `gameState`.
    public func location(_ id: LocationID?) throws -> Location {
        guard let id else {
            throw ActionResponse.internalEngineError("No location identifier provided.")
        }
        guard let location = gameState.locations[id] else {
            throw ActionResponse.internalEngineError("Location `\(id)` not found.")
        }
        return location
    }
}

// MARK: - Internal helpers

extension GameEngine {
    /// Displays the full description of the player's current location to the player.
    ///
    /// This method performs the following steps:
    /// 1. Checks if the location is lit. If dark, it prints the standard "pitch black" message
    ///    and does not proceed further.
    /// 2. If lit, it prints the location's name.
    /// 3. It generates and prints the location's main description (which may be dynamic).
    /// 4. It lists all items visible to the player in that location.
    ///
    /// This is called by the engine automatically when the player enters a new room, after
    /// certain commands that might change visibility (like turning a light on/off), or when
    /// the player explicitly looks around.
    ///
    /// - Parameter forceFullDescription: If true, always shows the full description regardless
    ///   of visit status. If false, shows brief description for previously visited rooms.
    func describeCurrentLocation(forceFullDescription: Bool = false) async throws {
        // 1. Check for light
        guard await playerLocationIsLit() else {
            // It's dark!
            await ioHandler.print("It is pitch black. You can't see a thing.")
            // Do not describe the room or list items.
            return
        }

        // 2. If lit, get snapshot and determine if this should be a full description
        let location = try location(playerLocationID)
        let isFirstVisit = !location.hasFlag(.isVisited)
        let shouldShowFullDescription = forceFullDescription || isFirstVisit

        // 3. Always print the room name
        await ioHandler.print("--- \(location.name) ---")

        // 4. Show full description if forced or first visit
        if shouldShowFullDescription {
            // Generate and print the full description
            let description = await generateDescription(
                for: location.id,
                attributeID: .description,
                engine: self
            )
            await ioHandler.print(description)

            // List visible items
            try await listItemsInLocation(locationID: playerLocationID)

            // Mark the room as visited now that we've actually described it
            // (following ZIL's TOUCHBIT pattern - only set when room is lit and described)
            if isFirstVisit, let visitedChange = setFlag(.isVisited, on: location) {
                try gameState.apply(visitedChange)
            }
        }
        // For subsequent visits without forceFullDescription, just show the room name (brief mode)
    }

    /// Displays a brief description of the player's current location (just the name).
    ///
    /// This is used when the player moves to a previously visited location in brief mode,
    /// providing acknowledgment of the movement without the full description. This matches
    /// traditional IF behavior where visited locations show only their name unless explicitly
    /// examined.
    func showBriefLocation() async throws {
        // 1. Check for light
        guard await playerLocationIsLit() else {
            // It's dark!
            await ioHandler.print("It is pitch black. You can't see a thing.")
            return
        }

        // 2. If lit, get snapshot and print just the name
        let location = try location(playerLocationID)
        await ioHandler.print("--- \(location.name) ---")
    }

    /// Validates a proposed value for a location attribute.
    /// Since validation handlers have been removed, this always returns true.
    /// This method is kept for compatibility during the transition.
    ///
    /// - Parameters:
    ///   - attributeID: The `AttributeID` of the attribute being validated.
    ///   - locationID: The unique identifier of the location.
    ///   - newValue: The proposed new `StateValue`.
    /// - Returns: Always `true` since validation handlers are not implemented yet.
    func validateStateValue(
        locationID: LocationID,
        attributeID: AttributeID,
        newValue: StateValue
    ) async throws -> Bool {
        // Validation handlers removed for now, always allow changes
        true
    }
}

// MARK: - Private helpers

extension GameEngine {
    /// Provides a default description string for a location attribute when a specific one
    /// isn't found. This internal helper is called by the public `generateDescription` for locations.
    private func defaultDescription(
        for locationID: LocationID,
        attributeID: AttributeID,
        engine: GameEngine
    ) async -> String {
        // Consider fetching location name
        // let locationName = await engine.locationSnapshot(locationID)?.name ?? "place"
        switch attributeID {
        case .description:
            return "You are in a nondescript location."
        case .shortDescription:
            return "A location."
        default:
            return "It seems indescribable."
        }
    }

    /// Retrieves the current value of a potentially dynamic location property.
    /// Checks for a compute handler first, then returns the stored value if no handler exists.
    ///
    /// - Parameters:
    ///   - attributeID: The `AttributeID` of the desired value.
    ///   - locationID: The unique identifier of the location.
    /// - Returns: The computed or stored `StateValue`, or `nil` if the location or value doesn't exist.
    private func fetchStateValue(
        locationID: LocationID,
        attributeID: AttributeID
    ) async -> StateValue? {
        guard let location = gameState.locations[locationID] else {
            logWarning("""
                Attempted to get dynamic value '\(attributeID.rawValue)' \
                for non-existent location: \(locationID.rawValue)
                """)
            return nil
        }

        if let computer = locationComputers[locationID] {
            do {
                return try await computer.compute(location, attributeID, gameState)
            } catch ComputeError.attributeNotHandled {
                // The computer doesn't handle this attribute, fall back to stored value
                return location.attributes[attributeID]
            } catch {
                logError("""
                    Error computing dynamic value '\(attributeID.rawValue)' \
                    for location \(locationID.rawValue): \(error)
                    """)
                // Fall through to return stored value on error
                return location.attributes[attributeID]
            }
        } else {
            return location.attributes[attributeID]
        }
    }

    /// Internal helper method to list items visible to the player in a given location.
    ///
    /// This method is only called if the location is determined to be lit.
    /// It uses the `ScopeResolver` to get a list of visible item IDs, fetches their
    /// `Item` data, and then formats them into a sentence like "There are a foo,
    /// a bar, and a baz here."
    /// If no items are visible, it prints nothing.
    private func listItemsInLocation(locationID: LocationID) async throws {
        // 1. Get visible item IDs using ScopeResolver
        let visibleItemIDs = await scopeResolver.visibleItemsIn(locationID: locationID)

        // 2. Asynchronously fetch Item objects/snapshots for the visible IDs
        let visibleItems = try visibleItemIDs.compactMap(item(_:))

        // 3. Format and print the list if not empty
        if !visibleItems.isEmpty {
            // Use the helper to generate a sentence like "a foo, a bar, and a baz"
            let itemListing = visibleItems.listWithIndefiniteArticles
            await ioHandler.print(
                "There \(visibleItems.count == 1 ? "is" : "are") \(itemListing) here."
            )
        }
        // No output if no items are visible
    }
}
