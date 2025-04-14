//extension Command {
//    public struct Preposition: Sendable, Equatable {
//        public let rawValues: [String]
//
//        public init(_ rawValues: String...) {
//            assert(!rawValues.isEmpty, "At least one word must be provided")
//            self.rawValues = rawValues
//        }
//
//        public var rawValue: String {
//            rawValues[0]
//        }
//
//        // Core prepositions
//        public static let at = Preposition("at", "toward")
//        public static let behind = Preposition("behind")
//        public static let from = Preposition("from")
//        public static let `in` = Preposition("in")
//        public static let inside = Preposition("inside", "within")
//        public static let into = Preposition("into")
//        public static let on = Preposition("on", "onto", "upon", "on…top…of")
//        public static let to = Preposition("to")
//        public static let under = Preposition("under", "beneath")
//        public static let using = Preposition("using")
//        public static let with = Preposition("with")
//    }
//}
//
//// Extension to map preposition strings to the Command.Preposition enum
//extension Command.Preposition {
//    static func from(_ string: String) -> Command.Preposition {
//        switch string.lowercased() {
//        case "at", "toward": .at
//        case "behind": .behind
//        case "from": .from
//        case "in": .in
//        case "inside", "within": .inside
//        case "into": .into
//        case "on", "onto", "upon": .on
//        case "to": .to
//        case "under", "beneath": .under
//        case "using": .using
//        case "with": .with
//        default: Command.Preposition(string)
//        }
//    }
//}
