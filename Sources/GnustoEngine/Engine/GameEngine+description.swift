import Foundation

// MARK: - Location description helpers

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
    func describeCurrentLocation(forceFullDescription: Bool = false) async throws -> ActionResult {
        let location = await player.location
        var changes = [StateChange]()

        // 1. Check for light
        guard await location.isLit else {
            // It's dark! Do not describe the room or list items.
            throw ActionResponse.roomIsDark
        }

        // 2. Always print the room name
        var messages = await ["--- \(location.name) ---"]

        // 3. Show full description if forced, first visit, or in verbose mode
        let isFirstVisit = await !location.hasFlag(.isVisited)
        let isVerboseMode = hasFlag(.isVerboseMode)

        // 4. For subsequent visits without forceFullDescription and not in verbose mode, just show the room name (brief mode)
        if forceFullDescription || isFirstVisit || isVerboseMode {
            // Generate and print the full description
            await messages.append(
                location.description
            )

            // List visible items
            await messages.append(
                listItemsInLocation(location)
            )

            // Mark the room as visited now that we've actually described it
            // (following ZIL's TOUCHBIT pattern - only set when room is lit and described)
            if isFirstVisit {
                await changes.append(
                    location.setFlag(.isVisited)
                )
            }
        }

        return ActionResult(
            message: messages.joined(separator: .paragraph),
            changes: changes
        )
    }

    /// Prints the description of the player's current location to the IOHandler.
    ///
    /// This is a convenience wrapper around `describeCurrentLocation` that handles
    /// the common case of describing the current location and immediately displaying
    /// the result to the player.
    ///
    /// - Parameter forceFullDescription: If true, always shows the full description regardless
    ///   of visit status. If false, shows brief description for previously visited rooms.
    /// - Throws: Re-throws any errors from `describeCurrentLocation()` or state application.
    func printCurrentLocationDescription(forceFullDescription: Bool = false) async throws {
        let result = try await describeCurrentLocation(forceFullDescription: forceFullDescription)

        // Apply state changes (like marking room as visited)
        try applyActionResultChanges(result.changes)

        // Print the location description
        if let message = result.message {
            await ioHandler.print(message)
        }
    }

    /// Helper method to list items visible to the player in a given location.
    ///
    /// This method is only called if the location is determined to be lit.
    /// It generates descriptions for:
    /// 1. Items directly in the location (with first descriptions if untouched)
    /// 2. Items on surfaces or in open/transparent containers
    ///
    /// Returns an array of description strings that can be joined and displayed.
    func listItemsInLocation(_ location: LocationProxy) async -> String? {
        // Get all items directly in the location (not inside containers)
        // Include items that should be described OR have visible contents (surfaces/open containers)
        let allDirectItems = await location.items
        var directItems = [ItemProxy]()
        for item in allDirectItems {
            let shouldDescribe = await item.shouldDescribe
            let hasVisibleContents = await item.contentsAreVisible
            if shouldDescribe || hasVisibleContents {
                directItems.append(item)
            }
        }

        var descriptionLines = [String]()
        var firstDescriptions = [String]()
        var regularItems = [ItemProxy]()

        // Separate items with first descriptions from regular items
        // Only describe items that should be described (not those with .omitDescription)
        for item in directItems.sorted() {
            if await item.shouldDescribe {
                if let firstDescription = await item.firstDescription {
                    firstDescriptions.append(firstDescription)
                } else {
                    regularItems.append(item)
                }
            }
        }

        // Add first descriptions for items directly in the location
        descriptionLines.append(contentsOf: firstDescriptions)

        // List regular items (touched items or those without first descriptions)
        if regularItems.isNotEmpty {
            await descriptionLines.append(
                messenger.thereAreIndefiniteItemsHere(regularItems.sorted())
            )
        }

        // Handle contents of surfaces and open/transparent containers
        // This includes containers with .omitDescription that have visible contents
        for container in directItems.sorted() where await container.contentsAreVisible {
            let contents = await container.contents
            guard contents.isNotEmpty else { continue }

            var firstDescriptions = [String]()
            var regularContents = [ItemProxy]()

            for content in contents.sorted() {
                if let firstDescription = await content.firstDescription {
                    firstDescriptions.append(firstDescription)
                } else {
                    regularContents.append(content)
                }
            }

            descriptionLines.append(
                contentsOf: firstDescriptions
            )

            // List regular contents (touched items or those without first descriptions)
            if regularContents.isNotEmpty {
                await descriptionLines.append(
                    messenger.inContainerYouCanSee(
                        container,
                        contents: regularContents,
                        also: firstDescriptions.isNotEmpty
                    )
                )
            }
        }

        return descriptionLines.isEmpty ? nil : descriptionLines.joined(separator: " ")
    }
}
