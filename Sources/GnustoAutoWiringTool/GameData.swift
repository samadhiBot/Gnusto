import Foundation
import SwiftSyntax
import SwiftParser

/// Holds all discovered game-related information from parsing Swift source code.
struct GameData {
    // ID collections
    var locationIDs: Set<String> = []
    var itemIDs: Set<String> = []
    var globalIDs: Set<String> = []
    var fuseIDs: Set<String> = []
    var daemonIDs: Set<String> = []
    var verbIDs: Set<String> = []

    // Type collections
    var gameBlueprintTypes: Set<String> = []
    var gameAreaTypes: Set<String> = []
    var itemEventHandlers: Set<String> = []
    var locationEventHandlers: Set<String> = []
    var customActionHandlers: Set<String> = []
    var fuseDefinitions: Set<String> = []
    var daemonDefinitions: Set<String> = []

    // Item and location property collections
    var items: Set<String> = []
    var locations: Set<String> = []

    // Mapping collections
    var itemToAreaMap: [String: String] = [:]
    var locationToAreaMap: [String: String] = [:]
    var handlerToAreaMap: [String: String] = [:]
    var propertyIsStatic: [String: Bool] = [:]

    init() {}
}

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
        } else if let enumDecl = node.as(EnumDeclSyntax.self) {
            currentAreaType = enumDecl.name.text
            processEnumDecl(enumDecl)
        } else if let varDecl = node.as(VariableDeclSyntax.self) {
            processVariableDecl(varDecl)
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

    private func processEnumDecl(_ enumDecl: EnumDeclSyntax) {
        // Assume enums containing game objects are game areas
        gameData.gameAreaTypes.insert(enumDecl.name.text)
    }

    private func processVariableDecl(_ varDecl: VariableDeclSyntax) {
        // Check if this is a static property
        let isStatic = varDecl.modifiers.contains { modifier in
            modifier.name.tokenKind == .keyword(.static)
        }

        for binding in varDecl.bindings {
            if let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
               let initializer = binding.initializer?.value {

                // Check for Location/Item initialization patterns
                if let functionCall = initializer.as(FunctionCallExprSyntax.self) {
                    let functionName = functionCall.calledExpression.trimmedDescription

                    if functionName == "Location" {
                        extractLocationData(from: functionCall, propertyName: pattern.identifier.text, isStatic: isStatic)
                    } else if functionName == "Item" {
                        extractItemData(from: functionCall, propertyName: pattern.identifier.text, isStatic: isStatic)
                    }
                }
            }
        }
    }

    private func extractLocationData(from functionCall: FunctionCallExprSyntax, propertyName: String, isStatic: Bool) {
        // Look for id: .locationName pattern
        guard let arguments = functionCall.arguments.first else { return }

        if let memberAccess = arguments.expression.as(MemberAccessExprSyntax.self),
           arguments.label?.text == "id" {
            let locationID = memberAccess.declName.baseName.text
            gameData.locationIDs.insert(locationID)
            gameData.locations.insert(propertyName)

            // Map this location property to its area type
            if let areaType = currentAreaType {
                gameData.locationToAreaMap[propertyName] = areaType
                gameData.propertyIsStatic[propertyName] = isStatic
            }
        }
    }

    private func extractItemData(from functionCall: FunctionCallExprSyntax, propertyName: String, isStatic: Bool) {
        // Look for id: .itemName pattern
        guard let arguments = functionCall.arguments.first else { return }

        if let memberAccess = arguments.expression.as(MemberAccessExprSyntax.self),
           arguments.label?.text == "id" {
            let itemID = memberAccess.declName.baseName.text
            gameData.itemIDs.insert(itemID)
            gameData.items.insert(propertyName)

            // Map this item property to its area type
            if let areaType = currentAreaType {
                gameData.itemToAreaMap[propertyName] = areaType
                gameData.propertyIsStatic[propertyName] = isStatic
            }
        }

        // Also look for additional IDs in other arguments (like .in(.location(.room)))
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
}
