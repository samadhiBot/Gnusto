import SwiftParser
import SwiftSyntax

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
