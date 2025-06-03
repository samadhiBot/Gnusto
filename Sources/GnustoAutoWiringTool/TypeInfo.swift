import SwiftParser
import SwiftSyntax

// MARK: - Data Models

struct TypeInfo {
    let name: String
    let kind: String // "enum" or "struct"
    let properties: [Property]

    struct Property {
        let name: String
        let type: String
        let isStatic: Bool
    }
}

struct GameData {
    var locationIDs = Set<String>()
    var itemIDs = Set<String>()
    var globalIDs = Set<String>()
    var fuseIDs = Set<String>()
    var daemonIDs = Set<String>()
    var verbIDs = Set<String>()

    var itemEventHandlers = Set<String>()
    var locationEventHandlers = Set<String>()
    var gameBlueprintTypes = Set<String>()
    var gameAreaTypes = Set<String>()
    var customActionHandlers = Set<String>()
    var fuseDefinitions = Set<String>()
    var daemonDefinitions = Set<String>()

    var items = Set<String>()
    var locations = Set<String>()

    // Area mappings for proper scoping
    var itemToAreaMap = [String: String]()
    var locationToAreaMap = [String: String]()
    var handlerToAreaMap = [String: String]()
    var propertyIsStatic = [String: Bool]()
}

// MARK: - Collectors

final class TypeInfoCollector: SyntaxAnyVisitor {
    var collectedTypes = [TypeInfo]()

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        collectProperties(for: node, kind: "struct")
        return .skipChildren
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        collectProperties(for: node, kind: "enum")
        return .skipChildren
    }

    private func collectProperties(for node: some DeclGroupSyntax, kind: String) {
        let typeName: String = {
            switch node {
            case let structDecl as StructDeclSyntax:
                return structDecl.name.text
            case let enumDecl as EnumDeclSyntax:
                return enumDecl.name.text
            default:
                return ""
            }
        }()
        var properties = [TypeInfo.Property]()

        for member in node.memberBlock.members {
            guard let variable = member.decl.as(VariableDeclSyntax.self) else { continue }

            let isStatic = variable.modifiers.contains { $0.name.text == "static" }

            for binding in variable.bindings {
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                      let typeAnnotation = binding.typeAnnotation else { continue }

                let typeText = typeAnnotation.type.description
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                properties.append(
                    TypeInfo.Property(
                        name: pattern.identifier.text,
                        type: typeText,
                        isStatic: isStatic
                    )
                )
            }
        }

        collectedTypes.append(
            TypeInfo(
                name: typeName,
                kind: kind,
                properties: properties
            )
        )
    }
}

final class GameDataCollector: SyntaxAnyVisitor {
    var gameData = GameData()
    private var currentAreaType: String?

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        processTypeDeclaration(node)
        return .visitChildren
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        processTypeDeclaration(node)
        return .visitChildren
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        processTypeDeclaration(node)
        return .visitChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        processVariableDeclaration(node)
        processInitializerExpressions(node)
        return .visitChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        processIDUsages(node)
        return .visitChildren
    }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        processMemberAccess(node)
        return .visitChildren
    }

    private func processTypeDeclaration(_ node: some NamedDeclSyntax & DeclGroupSyntax) {
        let typeName = node.name.text

        // Check if this type implements GameBlueprint
        if let inheritanceClause = node.inheritanceClause {
            let inherits = inheritanceClause.inheritedTypes.compactMap { type in
                type.type.as(IdentifierTypeSyntax.self)?.name.text
            }
            if inherits.contains("GameBlueprint") {
                gameData.gameBlueprintTypes.insert(typeName)
            }
        }

        // Check if this looks like a game area (contains Location/Item declarations)
        let containsGameContent = hasGameContent(in: node.memberBlock)
        if containsGameContent {
            gameData.gameAreaTypes.insert(typeName)
            currentAreaType = typeName
        }

        // Look for ActionHandler types
        if typeName.hasSuffix("ActionHandler") {
            gameData.customActionHandlers.insert(String(typeName.dropLast("ActionHandler".count)))
        }
    }

    private func processVariableDeclaration(_ node: VariableDeclSyntax) {
        let isStatic = node.modifiers.contains { $0.name.text == "static" }

        for binding in node.bindings {
            guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }
            let propertyName = pattern.identifier.text

            // Track static vs instance properties
            gameData.propertyIsStatic[propertyName] = isStatic

            // Check for Location properties
            if let typeAnnotation = binding.typeAnnotation,
               typeAnnotation.type.description.contains("Location") {
                gameData.locations.insert(propertyName)
                if let area = currentAreaType {
                    gameData.locationToAreaMap[propertyName] = area
                }
            }

            // Check for Item properties
            if let typeAnnotation = binding.typeAnnotation,
               typeAnnotation.type.description.contains("Item") {
                gameData.items.insert(propertyName)
                if let area = currentAreaType {
                    gameData.itemToAreaMap[propertyName] = area
                }
            }

            // Check for event handlers
            if propertyName.hasSuffix("Handler") {
                let handlerBaseName = String(propertyName.dropLast("Handler".count))

                if let initializer = binding.initializer,
                   initializer.value.description.contains("ItemEventHandler") {
                    gameData.itemEventHandlers.insert(handlerBaseName)
                    if let area = currentAreaType {
                        gameData.handlerToAreaMap[handlerBaseName] = area
                    }
                }

                if let initializer = binding.initializer,
                   initializer.value.description.contains("LocationEventHandler") {
                    gameData.locationEventHandlers.insert(handlerBaseName)
                    if let area = currentAreaType {
                        gameData.handlerToAreaMap[handlerBaseName] = area
                    }
                }
            }

            // Check for fuse/daemon definitions
            if let initializer = binding.initializer {
                let initDesc = initializer.value.description
                if initDesc.contains("FuseDefinition") {
                    gameData.fuseDefinitions.insert(propertyName)
                }
                if initDesc.contains("DaemonDefinition") {
                    gameData.daemonDefinitions.insert(propertyName)
                }
            }
        }
    }

    private func processIDUsages(_ node: FunctionCallExprSyntax) {
        let callDescription = node.description

        // Look for ID constructor patterns
        if callDescription.contains("LocationID(") {
            extractStringLiterals(from: node) { gameData.locationIDs.insert($0) }
        }
        if callDescription.contains("ItemID(") {
            extractStringLiterals(from: node) { gameData.itemIDs.insert($0) }
        }
        if callDescription.contains("GlobalID(") {
            extractStringLiterals(from: node) { gameData.globalIDs.insert($0) }
        }
        if callDescription.contains("FuseID(") {
            extractStringLiterals(from: node) { gameData.fuseIDs.insert($0) }
        }
        if callDescription.contains("DaemonID(") {
            extractStringLiterals(from: node) { gameData.daemonIDs.insert($0) }
        }
        if callDescription.contains("VerbID(") {
            extractStringLiterals(from: node) { id in
                // Filter out standard verbs
                let standardVerbs = ["close", "drop", "examine", "give", "go", "insert", "inventory", "listen", "lock", "look", "open", "push", "putOn", "read", "remove", "smell", "take", "taste", "thinkAbout", "touch", "turnOff", "turnOn", "unlock", "wear", "xyzzy", "brief", "help", "quit", "restore", "save", "score", "verbose", "wait", "debug"]
                if !standardVerbs.contains(id) {
                    gameData.verbIDs.insert(id)
                }
            }
        }

        // Look for .to() and .location() patterns
        if let calledExpression = node.calledExpression.as(MemberAccessExprSyntax.self) {
            if calledExpression.declName.baseName.text == "to" {
                extractDotIdentifiers(from: node) { gameData.locationIDs.insert($0) }
            }
            if calledExpression.declName.baseName.text == "location" {
                extractDotIdentifiers(from: node) { gameData.locationIDs.insert($0) }
            }
        }
    }

    private func processMemberAccess(_ node: MemberAccessExprSyntax) {
        // Look for implicit member expressions like .foyer, .cloak, etc.
        // These appear when used in contexts where the type is inferred
        guard node.base == nil else { return } // Only implicit member access

        let memberName = node.declName.baseName.text

        // For now, we'll infer the ID type based on context
        // This is heuristic-based and could be improved
        if memberName.allSatisfy({ $0.isLowercase || $0.isNumber || $0 == "_" }) {
            // Assume it's an ID if it's lowercase (conventional for Swift enums)
            // We'll categorize these during code generation based on usage patterns
            gameData.locationIDs.insert(memberName)
            gameData.itemIDs.insert(memberName)
        }
    }

    private func processInitializerExpressions(_ node: VariableDeclSyntax) {
        for binding in node.bindings {
            guard let initializer = binding.initializer else { continue }

            // Look for ID usages in variable initializers
            findIDUsagesInExpression(initializer.value)
        }
    }

    private func findIDUsagesInExpression(_ expr: ExprSyntax) {
        // Recursively search for ID patterns in expressions
        if let memberAccess = expr.as(MemberAccessExprSyntax.self) {
            processMemberAccess(memberAccess)
        }

        if let functionCall = expr.as(FunctionCallExprSyntax.self) {
            processIDUsages(functionCall)

            // Check arguments
            for arg in functionCall.arguments {
                findIDUsagesInExpression(arg.expression)
            }
        }

        if let arrayExpr = expr.as(ArrayExprSyntax.self) {
            for element in arrayExpr.elements {
                findIDUsagesInExpression(element.expression)
            }
        }

        if let dictExpr = expr.as(DictionaryExprSyntax.self) {
            switch dictExpr.content {
            case .elements(let elements):
                for element in elements {
                    if let keyValue = element.as(DictionaryElementSyntax.self) {
                        findIDUsagesInExpression(keyValue.key)
                        findIDUsagesInExpression(keyValue.value)
                    }
                }
            default:
                break
            }
        }
    }

    private func extractStringLiterals(from node: FunctionCallExprSyntax, handler: (String) -> Void) {
        guard let args = node.arguments.first else { return }
        if let stringLiteral = args.expression.as(StringLiteralExprSyntax.self),
           let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
            handler(segment.content.text)
        }
    }

    private func extractDotIdentifiers(from node: FunctionCallExprSyntax, handler: (String) -> Void) {
        for arg in node.arguments {
            if let memberAccess = arg.expression.as(MemberAccessExprSyntax.self),
               memberAccess.base == nil { // Implicit member access like .foyer
                let identifier = memberAccess.declName.baseName.text
                handler(identifier)
            }
        }
    }

    private func hasGameContent(in memberBlock: MemberBlockSyntax) -> Bool {
        for member in memberBlock.members {
            if let variable = member.decl.as(VariableDeclSyntax.self) {
                for binding in variable.bindings {
                    if let typeAnnotation = binding.typeAnnotation {
                        let typeDesc = typeAnnotation.type.description
                        if typeDesc.contains("Location") || typeDesc.contains("Item") {
                            return true
                        }
                    }
                    if let initializer = binding.initializer {
                        let initDesc = initializer.value.description
                        if initDesc.contains("Location(") || initDesc.contains("Item(") ||
                           initDesc.contains("ItemEventHandler") || initDesc.contains("LocationEventHandler") {
                            return true
                        }
                    }
                }
            }
        }
        return false
    }
}
