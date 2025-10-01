import Foundation
import SwiftParser
import SwiftSyntax

/// A simple game data collector that walks a syntax tree to find game patterns.
class GameDataCollector {
    var gameData = GameData()

    private var currentAreaType: String?

    func collect(from source: String) {
        let tree = Parser.parse(source: source)
        walk(tree)
    }

    private func walk(_ node: SyntaxProtocol) {
        // Track context for structs and enums
        let oldAreaType = currentAreaType

        // Check for specific node types we care about
        if let structDecl = node.as(StructDeclSyntax.self) {
            currentAreaType = structDecl.name.text
            processStructDecl(structDecl)
        } else if let classDecl = node.as(ClassDeclSyntax.self) {
            currentAreaType = classDecl.name.text
            processClassDecl(classDecl)
        } else if let enumDecl = node.as(EnumDeclSyntax.self) {
            currentAreaType = enumDecl.name.text
            processEnumDecl(enumDecl)
        } else if let extensionDecl = node.as(ExtensionDeclSyntax.self) {
            currentAreaType = extensionDecl.extendedType.trimmedDescription
            // Note: We are not processing extensions for GlobalID anymore, per the new strategy
        } else if let varDecl = node.as(VariableDeclSyntax.self) {
            processVariableDecl(varDecl)
        } else if let functionCall = node.as(FunctionCallExprSyntax.self) {
            processFunctionCallExpr(functionCall)
        }

        // Recursively walk children
        for child in node.children(viewMode: .sourceAccurate) {
            walk(child)
        }

        // Restore previous context
        currentAreaType = oldAreaType
    }

    private func processStructDecl(_ structDecl: StructDeclSyntax) {
        // Check for GameBlueprint conformance
        if let inheritanceClause = structDecl.inheritanceClause {
            for inheritance in inheritanceClause.inheritedTypes {
                if inheritance.type.trimmedDescription == "GameBlueprint" {
                    gameData.gameBlueprintTypes.insert(structDecl.name.text)
                } else if inheritance.type.trimmedDescription == "CombatSystem" {
                    // This is a CombatSystem implementation - we'll handle this in variable processing
                    gameData.gameAreaTypes.insert(structDecl.name.text)
                } else if inheritance.type.trimmedDescription == "CombatMessenger" {
                    // This is a CombatMessenger implementation - we'll handle this in variable processing
                    gameData.gameAreaTypes.insert(structDecl.name.text)
                } else {
                    // If it's not a GameBlueprint, it might be a game area (like Act1Area)
                    gameData.gameAreaTypes.insert(structDecl.name.text)
                }
            }
        } else {
            // Structs without inheritance might still be game areas if they contain game objects
            // We'll determine this based on whether they have items/locations
            gameData.gameAreaTypes.insert(structDecl.name.text)
        }
    }

    private func processClassDecl(_ classDecl: ClassDeclSyntax) {
        // Check for CombatMessenger inheritance
        if let inheritanceClause = classDecl.inheritanceClause {
            for inheritance in inheritanceClause.inheritedTypes {
                if inheritance.type.trimmedDescription == "CombatMessenger" {
                    // This is a CombatMessenger implementation - we'll handle this in variable processing
                    gameData.gameAreaTypes.insert(classDecl.name.text)
                } else {
                    // Other class types might still be game areas
                    gameData.gameAreaTypes.insert(classDecl.name.text)
                }
            }
        } else {
            // Classes without inheritance might still be game areas if they contain game objects
            gameData.gameAreaTypes.insert(classDecl.name.text)
        }
    }

    private func processEnumDecl(_ enumDecl: EnumDeclSyntax) {
        // Assume enums containing game objects are game areas
        gameData.gameAreaTypes.insert(enumDecl.name.text)
    }

    private func processFunctionCallExpr(_ functionCall: FunctionCallExprSyntax) {
        // We are looking for engine calls that use GlobalIDs implicitly,
        // like `engine.hasFlag(.someGlobalFlag)`
        guard
            let calledExpression = functionCall.calledExpression.as(MemberAccessExprSyntax.self)
        else {
            // Also check for SideEffect convenience methods like .runDaemon(.daemonName)
            processConvenienceSideEffects(functionCall)
            return
        }

        let functionName = calledExpression.declName.baseName.text
        let globalIDFunctions = [
            "adjustGlobal",
            "clearFlag",
            "global",
            "globalState",
            "hasFlag",
            "setFlag",
            "toggleFlag",
            "value",
        ]

        guard globalIDFunctions.contains(functionName) else { return }

        // These functions can be called on an item or globally on the engine.
        // A global call has one argument: `hasFlag(.someFlag)`.
        // An item call has two: `hasFlag(.someFlag, on: .someItem)`.
        // We only care about calls that are potentially global.
        guard let firstArgument = functionCall.arguments.first?.expression else { return }

        // We are looking for a dot-prefixed member access, like `.myFlag`.
        if let memberAccess = firstArgument.as(MemberAccessExprSyntax.self),
            memberAccess.base == nil
        {
            let globalIDName = memberAccess.declName.baseName.text

            // Only treat as GlobalID if called on engine/context, not on item instances
            // Check if this is likely an engine-level call vs item-level call
            if functionCall.arguments.count == 1 && isEngineOrContextCall(calledExpression) {
                gameData.globalIDs.insert(globalIDName)
            }
        }
    }

    /// Determines if a member access expression represents a call on engine/context vs item instance
    private func isEngineOrContextCall(_ memberAccess: MemberAccessExprSyntax) -> Bool {
        guard let base = memberAccess.base else { return false }

        let baseText = base.trimmedDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        // Be very restrictive - only direct engine references
        // Exclude proxy calls like "context.location(.foo)", "item.hasFlag", "bar.setFlag", etc.
        let directEnginePatterns = [
            "engine",
            "context.engine",
            "await engine",
            "await context.engine",
        ]

        // Must be an exact match or end with these patterns to avoid false positives
        return directEnginePatterns.contains { pattern in
            baseText == pattern || baseText.hasSuffix(".\(pattern)")
        }
    }

    private func processConvenienceSideEffects(_ functionCall: FunctionCallExprSyntax) {
        // Look for convenience side effect methods like .runDaemon(.daemonName) and .stopDaemon(.daemonName)
        guard let memberAccess = functionCall.calledExpression.as(MemberAccessExprSyntax.self),
            memberAccess.base == nil
        else { return }

        let functionName = memberAccess.declName.baseName.text

        // Check for daemon convenience methods
        if functionName == "runDaemon" || functionName == "stopDaemon" {
            // Look for string literal argument
            if let firstArg = functionCall.arguments.first?.expression,
                let stringLiteral = firstArg.as(StringLiteralExprSyntax.self),
                let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self)
            {
                let daemonID = segment.content.text
                gameData.daemonIDs.insert(daemonID)
            }
        }

        // Check for fuse convenience methods (if they exist)
        if functionName == "startFuse" || functionName == "stopFuse" {
            // Look for string literal argument
            if let firstArg = functionCall.arguments.first?.expression,
                let stringLiteral = firstArg.as(StringLiteralExprSyntax.self),
                let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self)
            {
                let fuseID = segment.content.text
                gameData.fuseIDs.insert(fuseID)
            }
        }
    }

    private func processVariableDecl(_ varDecl: VariableDeclSyntax) {
        // Check if this is a static property
        let isStatic = varDecl.modifiers.contains { modifier in
            modifier.name.tokenKind == .keyword(.static)
        }

        for binding in varDecl.bindings {
            if let pattern = binding.pattern.as(IdentifierPatternSyntax.self) {
                let propertyName = pattern.identifier.text

                // Handle stored properties with initializers
                if let initializer = binding.initializer?.value {
                    // Check for Location/Item initialization patterns
                    if let functionCall = initializer.as(FunctionCallExprSyntax.self) {
                        let functionName = functionCall.calledExpression.trimmedDescription

                        if functionName == "Location" {
                            extractLocationData(
                                from: functionCall, propertyName: propertyName, isStatic: isStatic)
                        } else if functionName == "Item" {
                            extractItemData(
                                from: functionCall, propertyName: propertyName, isStatic: isStatic)
                        } else if functionName == "ItemEventHandler" {
                            extractEventHandlerData(
                                from: propertyName, type: .item, isStatic: isStatic)
                        } else if functionName == "LocationEventHandler" {
                            extractEventHandlerData(
                                from: propertyName, type: .location, isStatic: isStatic)
                        } else if functionName == "ItemComputer" {
                            extractComputeHandlerData(
                                from: propertyName, type: .item, isStatic: isStatic)
                        } else if functionName == "LocationComputer" {
                            extractComputeHandlerData(
                                from: propertyName, type: .location, isStatic: isStatic)
                        } else if isCombatSystemType(functionName) {
                            extractCombatSystemData(
                                from: functionCall, propertyName: propertyName, isStatic: isStatic)
                        } else if isCombatMessengerType(functionName) {
                            extractCombatMessengerData(
                                from: functionCall, propertyName: propertyName, isStatic: isStatic)
                        } else if functionName == "Fuse" {
                            extractFuseData(
                                propertyName: propertyName, isStatic: isStatic)
                        } else if functionName == "Daemon" {
                            extractDaemonData(
                                propertyName: propertyName, isStatic: isStatic)
                        }
                    }
                }

                // Handle computed properties with accessors (getters)
                if let accessorBlock = binding.accessorBlock {
                    // Walk through the accessor block to find function calls
                    walk(accessorBlock)
                }
            }
        }
    }

    private enum EventHandlerType {
        case item
        case location
    }

    private enum ComputeHandlerType {
        case item
        case location
    }

    private func extractEventHandlerData(
        from propertyName: String,
        type: EventHandlerType,
        isStatic: Bool
    ) {
        // Extract the entity name from the handler property name
        // e.g., "cloakHandler" -> "cloak", "barHandler" -> "bar"
        if propertyName.hasSuffix("Handler") {
            let entityName = String(propertyName.dropLast("Handler".count))

            switch type {
            case .item:
                gameData.itemEventHandlers.insert(entityName)
            case .location:
                gameData.locationEventHandlers.insert(entityName)
            }

            // Map this handler to its area type and track if it's static
            if let currentAreaType {
                gameData.handlerToAreaMap[entityName] = currentAreaType

                // We need to find if the handler property is static - let's look at the parent variable declaration
                // For now, we'll track the handler property name and its static status
                gameData.propertyIsStatic["\(entityName)Handler"] = isStatic
            }
        }
    }

    private func extractComputeHandlerData(
        from propertyName: String,
        type: ComputeHandlerType,
        isStatic: Bool
    ) {
        // Extract the entity name from the compute handler property name
        // e.g., "cloakComputer" -> "cloak", "barComputer" -> "bar"
        if propertyName.hasSuffix("Computer") {
            let entityName = String(propertyName.dropLast("Computer".count))

            switch type {
            case .item:
                gameData.itemComputeHandlers.insert(entityName)
            case .location:
                gameData.locationComputeHandlers.insert(entityName)
            }

            // Map this handler to its area type and track if it's static
            if let currentAreaType {
                gameData.handlerToAreaMap[entityName] = currentAreaType
                gameData.propertyIsStatic["\(entityName)Computer"] = isStatic
            }
        }
    }

    private func extractLocationData(
        from functionCall: FunctionCallExprSyntax,
        propertyName: String,
        isStatic: Bool
    ) {
        // Look for id: .locationName pattern
        guard let arguments = functionCall.arguments.first else { return }

        if let memberAccess = arguments.expression.as(MemberAccessExprSyntax.self),
            arguments.label?.text == "id"
        {
            let locationID = memberAccess.declName.baseName.text
            gameData.locationIDs.insert(locationID)
            gameData.locations.insert(propertyName)

            // Map this location property to its area type
            if let currentAreaType {
                gameData.locationToAreaMap[propertyName] = currentAreaType
                gameData.propertyIsStatic[propertyName] = isStatic
            }
        }
    }

    private func isCombatSystemType(_ typeName: String) -> Bool {
        // Check if this is a CombatSystem type - could be direct instantiation or a known combat system type
        typeName.hasSuffix("CombatSystem")
            || (typeName.contains("Combat") && typeName.contains("System"))
    }

    private func isCombatMessengerType(_ typeName: String) -> Bool {
        // Check if this is a CombatMessenger type - could be direct instantiation or a known combat messenger type
        typeName.hasSuffix("CombatMessenger")
            || (typeName.contains("Combat") && typeName.contains("Messenger"))
            || typeName == "CombatMessenger"
    }

    private func extractCombatSystemData(
        from functionCall: FunctionCallExprSyntax,
        propertyName: String,
        isStatic: Bool
    ) {
        // Look for enemyID property in the combat system
        // This could be in an initializer argument or we might need to infer it from the property name

        // First, try to find enemyID in function arguments
        for argument in functionCall.arguments {
            if argument.label?.text == "enemyID" {
                if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                    let enemyID = memberAccess.declName.baseName.text
                    gameData.itemIDs.insert(enemyID)
                    gameData.combatSystems.insert(propertyName)

                    if let currentAreaType {
                        gameData.handlerToAreaMap[propertyName] = currentAreaType
                        gameData.propertyIsStatic[propertyName] = isStatic
                    }
                    return
                }
            }
        }

        // If no explicit enemyID found, try to infer from property name
        // e.g., "trollCombatSystem" -> "troll", "dragonCombat" -> "dragon"
        var enemyID = propertyName
        if enemyID.hasSuffix("CombatSystem") {
            enemyID = String(enemyID.dropLast("CombatSystem".count))
        } else if enemyID.hasSuffix("Combat") {
            enemyID = String(enemyID.dropLast("Combat".count))
        }

        gameData.itemIDs.insert(enemyID)
        gameData.combatSystems.insert(propertyName)

        if let currentAreaType {
            gameData.handlerToAreaMap[propertyName] = currentAreaType
            gameData.propertyIsStatic[propertyName] = isStatic
        }
    }

    private func extractCombatMessengerData(
        from functionCall: FunctionCallExprSyntax,
        propertyName: String,
        isStatic: Bool
    ) {
        // Look for enemyID property in the combat messenger
        // This could be in an initializer argument or we might need to infer it from the property name

        // First, try to find enemyID in function arguments
        for argument in functionCall.arguments {
            if argument.label?.text == "enemyID" {
                if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                    let enemyID = memberAccess.declName.baseName.text
                    gameData.itemIDs.insert(enemyID)
                    gameData.combatMessengers.insert(propertyName)

                    if let currentAreaType {
                        gameData.handlerToAreaMap[propertyName] = currentAreaType
                        gameData.propertyIsStatic[propertyName] = isStatic
                    }
                    return
                }
            }
        }

        // If no explicit enemyID found, try to infer from property name
        // e.g., "trollCombatMessenger" -> "troll", "dragonMessenger" -> "dragon"
        var enemyID = propertyName
        if enemyID.hasSuffix("CombatMessenger") {
            enemyID = String(enemyID.dropLast("CombatMessenger".count))
        } else if enemyID.hasSuffix("Messenger") {
            enemyID = String(enemyID.dropLast("Messenger".count))
        }

        gameData.itemIDs.insert(enemyID)
        gameData.combatMessengers.insert(propertyName)

        if let currentAreaType {
            gameData.handlerToAreaMap[propertyName] = currentAreaType
            gameData.propertyIsStatic[propertyName] = isStatic
        }
    }

    private func extractItemData(
        from functionCall: FunctionCallExprSyntax,
        propertyName: String,
        isStatic: Bool
    ) {
        // Look for id: .itemName pattern
        guard let arguments = functionCall.arguments.first else { return }

        if let memberAccess = arguments.expression.as(MemberAccessExprSyntax.self),
            arguments.label?.text == "id"
        {
            let itemID = memberAccess.declName.baseName.text
            gameData.itemIDs.insert(itemID)
            gameData.items.insert(propertyName)

            // Map this item property to its area type
            if let currentAreaType {
                gameData.itemToAreaMap[propertyName] = currentAreaType
                gameData.propertyIsStatic[propertyName] = isStatic
            }
        }

        // Also look for additional IDs in other arguments (like .in(.room))
        for argument in functionCall.arguments.dropFirst() {
            extractIDsFromExpression(argument.expression)
        }
    }

    private func extractIDsFromExpression(_ expression: ExprSyntax) {
        if let memberAccess = expression.as(MemberAccessExprSyntax.self) {
            // Check if this is in an ID context (not a method call)
            if isInIDContext(memberAccess) {
                let idName = memberAccess.declName.baseName.text

                // Try to determine the ID type from context
                if let base = memberAccess.base?.trimmedDescription {
                    if base.contains("location") {
                        gameData.locationIDs.insert(idName)
                    } else if base.contains("item") {
                        gameData.itemIDs.insert(idName)
                    } else if base.contains("player") {
                        // Player is a special case - it's an implicit ID
                        gameData.locationIDs.insert(idName)
                    }
                }
            }
        } else if let functionCall = expression.as(FunctionCallExprSyntax.self) {
            // Recursively check function call arguments
            for argument in functionCall.arguments {
                extractIDsFromExpression(argument.expression)
            }
        }
    }

    private func isInIDContext(_ memberAccess: MemberAccessExprSyntax) -> Bool {
        // This is a simplified version - in a real implementation, you'd want more
        // sophisticated context analysis to avoid false positives
        let memberName = memberAccess.declName.baseName.text

        // Filter out common method names that aren't IDs
        let methodNames = ["name", "description", "location", "in", "to", "exits", "adjectives"]
        return !methodNames.contains(memberName)
    }

    private func extractFuseData(
        propertyName: String,
        isStatic: Bool
    ) {
        // Since Fuse no longer takes an ID parameter, we derive the ID from the property name
        // e.g., "explodingFuse" -> "explodingFuse"
        gameData.fuseIDs.insert(propertyName)
        gameData.fuses.insert(propertyName)

        // Map this fuse definition to its area type
        if let currentAreaType {
            gameData.handlerToAreaMap[propertyName] = currentAreaType
            gameData.propertyIsStatic[propertyName] = isStatic
        }
    }

    private func extractDaemonData(
        propertyName: String,
        isStatic: Bool
    ) {
        // Since Daemon no longer takes an ID parameter, we derive the ID from the property name
        // e.g., "swordDaemon" -> "swordDaemon"
        gameData.daemonIDs.insert(propertyName)
        gameData.daemons.insert(propertyName)

        // Map this daemon definition to its area type
        if let currentAreaType {
            gameData.handlerToAreaMap[propertyName] = currentAreaType
            gameData.propertyIsStatic[propertyName] = isStatic
        }
    }
}
