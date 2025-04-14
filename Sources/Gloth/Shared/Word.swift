import Foundation

enum Word: Hashable {
    case directObject(String)
    case indirectObject(String)
    case modifier(String)
    case preposition(String)
    case verb(String)
    case determiner(String)

    var token: String {
        switch self {
        case .directObject(let word): word
        case .indirectObject(let word): word
        case .modifier(let word): word
        case .preposition(let word): word
        case .verb(let word): word
        case .determiner(let word): word
        }
    }

    var label: String {
        switch self {
        case .directObject: "directObject"
        case .indirectObject: "indirectObject"
        case .modifier: "modifier"
        case .preposition: "preposition"
        case .verb: "verb"
        case .determiner: "determiner"
        }
    }
}
