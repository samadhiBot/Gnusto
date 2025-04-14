import Foundation

protocol Generator {
    static func any() -> Phrase
}

extension Generator {
    static func generate(_ count: Int) -> [Phrase] {
        var phrases = Set<Phrase>()
        var iterationsWithoutGrowth = 0
        let maxIterationsWithoutGrowth = count

        while phrases.count < count && iterationsWithoutGrowth < maxIterationsWithoutGrowth {
            let initialCount = phrases.count
            phrases.insert(any())
            if phrases.count == initialCount {
                iterationsWithoutGrowth += 1
            } else {
                iterationsWithoutGrowth = 0
            }
        }

        return Array(phrases).sorted()
    }

    static func any(_ phrases: Phrase...) -> Phrase {
        phrases.randomElement()!
    }

    static func phrase(_ words: Word...) -> Phrase {
        Phrase(
            words.filter {
                switch $0 {
                case .determiner: Bool.random()
                case .directObject: true
                case .indirectObject: true
                case .modifier: Bool.random()
                case .preposition: true
                case .verb: true
                }
            }
        )
    }
}

extension Array {
    var rnd: Element {
        randomElement()!
    }
}
