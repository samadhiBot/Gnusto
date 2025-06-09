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
    /// - Returns: The string value of the attribute, or `nil` if the attribute doesn't exist.
    /// - Throws: `ActionResponse.invalidValue` if the attribute exists but is not a string,
    ///           or if the location does not exist.
    public func attribute(
        _ attributeID: AttributeID,
        of locationID: LocationID
    ) async throws -> String? {
        let result = await fetchStateValue(
            locationID: locationID,
            attributeID: attributeID
        )
        let value = result.value

        guard let value else {
            return nil
        }

        switch value {
        case .string(let stringValue):
            return stringValue
        default:
            throw ActionResponse.invalidValue("""
                Cannot fetch string value for \(locationID.rawValue).\(attributeID.rawValue): \
                expected string but got \(value)
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
    /// - Returns: A tuple containing the computed or stored `StateValue` (or `nil` if not found)
    ///           and a boolean indicating whether a compute handler provided the value.
    private func fetchStateValue(
        locationID: LocationID,
        attributeID: AttributeID
    ) async -> (value: StateValue?, wasComputed: Bool) {
        guard let location = gameState.locations[locationID] else {
            logWarning("""
                Attempted to get dynamic value '\(attributeID.rawValue)' \
                for non-existent location: \(locationID.rawValue)
                """)
            return (nil, false)
        }

        // Try compute handler first
        if let computer = locationComputers[locationID] {
            do {
                if let computedValue = try await computer.compute(attributeID, gameState) {
                    return (computedValue, true)
                }
                // Computer returned nil, fall through to stored value
            } catch {
                logError("Error computing dynamic value '\(attributeID.rawValue)' for location \(locationID.rawValue): \(error)")
                // Fall through to stored value on error
            }
        }

        // No compute handler or handler failed, return stored value
        return (location.attributes[attributeID], false)
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
            var descriptionLines: [String] = []

            // Handle items directly in the location (excluding those that omit description)
            let directItems = visibleItems.filter { !$0.hasFlag(.omitDescription) }
            if !directItems.isEmpty {
                // Check if any direct items have firstDescription and haven't been touched
                let hasFirstDescriptions = directItems.contains { item in
                    guard
                        let firstDescription = item.attributes[.firstDescription],
                        case .string(let description) = firstDescription,
                        !description.isEmpty
                    else {
                        return false
                    }
                    return !item.hasFlag(.isTouched)
                }

                if hasFirstDescriptions {
                    // Use individual first descriptions for untouched direct items
                    for item in directItems.sorted() {
                        if let firstDescription = item.attributes[.firstDescription],
                           case .string(let description) = firstDescription,
                           !description.isEmpty,
                           !item.hasFlag(.isTouched) {
                            // Use first description for untouched items
                            descriptionLines.append(description)
                        } else {
                            // Use generic description for touched items or those without first descriptions
                            descriptionLines.append("There is \(item.withIndefiniteArticle) here.")
                        }
                    }
                } else {
                    // No first descriptions or all items touched - use simple listing
                    let itemListing = directItems.listWithIndefiniteArticles
                    descriptionLines.append(
                        "There \(directItems.count == 1 ? "is" : "are") \(itemListing) here."
                    )
                }
            }

            // Check for surfaces and open/transparent containers in the location
            // Include ALL items in location (even those with .omitDescription) to check for surfaces
            let allItemsInLocation = gameState.items.values.filter { $0.parent == .location(locationID) }
            for item in allItemsInLocation {
                if item.hasFlag(.isSurface) ||
                   (item.hasFlag(.isContainer) && (item.hasFlag(.isOpen) || item.hasFlag(.isTransparent))) {
                    let contents = gameState.items(in: .item(item.id))

                    // Check if any items on this surface have first descriptions
                    let hasFirstDescriptions = contents.contains { item in
                        guard
                            let firstDescription = item.attributes[.firstDescription],
                            case .string(let description) = firstDescription,
                            !description.isEmpty
                        else {
                            return false
                        }
                        return !item.hasFlag(.isTouched)
                    }

                    if hasFirstDescriptions {
                        // Use individual first descriptions for items on surfaces
                        for contentItem in contents.sorted() {
                            if let firstDescription = contentItem.attributes[.firstDescription],
                               case .string(let fdesc) = firstDescription,
                               !fdesc.isEmpty,
                               !contentItem.hasFlag(.isTouched) {
                                // Use first description for untouched items on surfaces
                                descriptionLines.append(fdesc)
                            } else if !contentItem.hasFlag(.isTouched) {
                                // Use generic surface description for touched items without first descriptions
                                if item.hasFlag(.isSurface) {
                                    descriptionLines.append("On the \(item.name) is \(contentItem.withIndefiniteArticle).")
                                } else {
                                    descriptionLines.append("The \(item.name) contains \(contentItem.withIndefiniteArticle).")
                                }
                            }
                        }
                    }
                }
            }

            // Print all description lines
            for line in descriptionLines {
                await ioHandler.print(line)
            }
        }
        // No output if no items are visible
    }
}
