import Foundation

/// Handles the "LOOK" command and its synonyms (e.g., "L"). It can also implicitly handle
/// "EXAMINE [ITEM]" logic if a direct object is provided with the LOOK command.
///
/// - When used without a direct object ("LOOK"), it describes the player's current location,
///   including its name, description, and any visible items.
/// - When used with a direct object that is an item ("LOOK [ITEM]" or "EXAMINE [ITEM]"),
///   it describes the specified item, including its contents if it's an open/transparent
///   container or a surface.
public struct LookActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb)
    ]

    public let verbs: [Verb] = [.look, "l"]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "LOOK" command.
    ///
    /// This action handles various forms of the LOOK command:
    /// - LOOK (no object): Describes the current location
    /// - LOOK AT [object]: Examines the specified object
    /// - LOOK IN/INSIDE/WITH [object]: Looks inside containers
    /// - LOOK THROUGH [object]: Looks through transparent objects
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Check if this is LOOK (no direct object) or LOOK AT [object] or LOOK THROUGH [object]
        if command.directObject == nil {
            // LOOK (no direct object) - describe the room
            // Check for darkness FIRST
            guard await engine.playerLocationIsLit() else {
                return ActionResult(
                    engine.messenger.roomIsDark()
                )
            }

            await engine.ioHandler.print(
                "--- \(try engine.playerLocation().name) ---",
                style: .strong
            )

            // Location is lit, proceed with description
            return ActionResult(
                await locationDescription(
                    try engine.playerLocation(),
                    engine: engine,
                    showVerbose: true
                )
            )
        } else if command.preposition == "through" {
            // LOOK THROUGH [Object] - delegate to examine behavior for basic look-through functionality
            // Specific items can override this via ItemEventHandlers (like the kitchen window)
            let examineHandler = ExamineActionHandler()
            return try await examineHandler.process(command: command, engine: engine)
        } else if command.preposition == "in" || command.preposition == "inside"
            || command.preposition == "with"
        {
            // LOOK IN/INSIDE/WITH [Object] - delegate to look-inside behavior
            let lookInsideHandler = LookInsideActionHandler()
            return try await lookInsideHandler.process(command: command, engine: engine)
        } else {
            // LOOK AT [Object] - validate and delegate to ExamineActionHandler
            guard let directObjectRef = command.directObject else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.doWhat(verb: command.verb)
                )
            }

            // If a direct object is present, it must be an item for LOOK/EXAMINE
            guard case .item(let targetItemID) = directObjectRef else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.canOnlyLookAtItems()
                )
            }

            // Ensure item exists and is reachable
            let targetItem = try await engine.item(targetItemID)
            guard await engine.playerCanReach(targetItemID) else {
                throw ActionResponse.itemNotAccessible(targetItemID)
            }

            // Delegate to ExamineActionHandler to avoid code duplication
            let examineHandler = ExamineActionHandler()
            return try await examineHandler.process(command: command, engine: engine)
        }
    }

    // MARK: - Helper Methods

    /// Generates a comprehensive description of the specified location, including its standard
    /// description and a list of any visible items.
    ///
    /// - Parameters:
    ///   - location: The `Location` to describe.
    ///   - engine: The `GameEngine` instance, used for description generation and scope resolution.
    ///   - showVerbose: A flag (currently unused but planned) that might control the level of detail.
    /// - Returns: A string containing the full description of the location and its visible items.
    private func locationDescription(
        _ location: Location,
        engine: GameEngine,
        showVerbose: Bool
    ) async -> String {
        var description: [String] = [
            await engine.generateDescription(
                for: location.id,
                attributeID: .description,
                engine: engine
            )
        ]

        let stateSnapshot = await engine.gameState

        // Use the correct ScopeResolver method
        let visibleItemIDs = await engine.scopeResolver.visibleItemsIn(locationID: location.id)

        let visibleItems = visibleItemIDs.compactMap { stateSnapshot.items[$0] }

        // Collect all items to describe: directly in location + items on surfaces/in open containers
        var surfaceFirstDescriptions: [String] = []

        // Check for surfaces and open/transparent containers in the location
        // Include ALL items in location (even those with .omitDescription) to check for surfaces
        let allItemsInLocation = stateSnapshot.items.values.filter {
            $0.parent == .location(location.id)
        }
        for item in allItemsInLocation {
            if item.hasFlag(.isSurface)
                || (item.hasFlag(.isContainer)
                    && (item.hasFlag(.isOpen) || item.hasFlag(.isTransparent)))
            {
                let contents = stateSnapshot.items(in: .item(item.id))

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
                            !contentItem.hasFlag(.isTouched)
                        {
                            // Use first description for untouched items on surfaces
                            surfaceFirstDescriptions.append(fdesc)
                        } else if !contentItem.hasFlag(.isTouched) {
                            // Use generic surface description for touched items without first descriptions
                            if item.hasFlag(.isSurface) {
                                surfaceFirstDescriptions.append(
                                    "On the \(item.name) is \(contentItem.withIndefiniteArticle).")
                            } else {
                                surfaceFirstDescriptions.append(
                                    "The \(item.name) contains \(contentItem.withIndefiniteArticle)."
                                )
                            }
                        }
                    }
                }
            }
        }

        // Now handle the description output
        var descriptionLines: [String] = []

        // First, handle items directly in the location
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
                        case .string(let fdesc) = firstDescription,
                        !fdesc.isEmpty,
                        !item.hasFlag(.isTouched)
                    {
                        // Use first description for untouched items
                        descriptionLines.append(fdesc)
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

        // Add surface/container first descriptions
        descriptionLines.append(contentsOf: surfaceFirstDescriptions)

        if !descriptionLines.isEmpty {
            description.append(descriptionLines.joined(separator: "\n"))
        }

        return description.joined(separator: "\n\n")
    }
}
