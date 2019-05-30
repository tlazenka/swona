/**
 * Represents the valid runtime values in programs.
 *
 * We could Kotlin types directly instead of these and replace all references
 * to [Value] by references to [Any], but that way it would be less clear which
 * Kotlin values we are actually planning to support and the compiler could not
 * help us with exhaustiveness checks. Therefore we'll model our values explicitly.
 */
public enum Value: CustomStringConvertible {
    /**
     * Unit value.
     */
    case unit
    
    /**
     * Strings.
     */
    case string(value: String)
    
    /**
     * Booleans.
     */
    case bool(value: Bool)
    
    /**
     * Integers.
     */
    case integer(value: Int)
    
    case function(Function)
    
    public enum Function {
        /**
         * Function whose implementation is byte-code.
         */
        case compound(address: Int, codeSize: Int, name: String, signature: Type.Function)
        
        /**
         * Function implemented as native function.
         */
        case native(func: FunctionReference, name: String, signature: Type.Function)
        
        public var signature: Type.Function {
            switch self {
            case let .compound(_, _, _, signature),
                 let .native(_, _, signature):
                return signature
            }
        }
        
        public var name: String {
            switch self {
            case let .compound(_, _, name, _),
                 let .native(_, name, _):
                return name
            }
        }
    }
    
    case array(elements: ArrayReference, elementType: Type)
    
    case pointer(value: Int, Pointer)
    public enum Pointer {
        case code
    }
    
    public func plus(rhs: Value) -> Value {
        if case let .string(lhs) = self {
            return Value.string(value: lhs + rhs.description)
        }
        if case let .integer(lhs) = self, case let .integer(rhs) = rhs {
            return .integer(value: lhs + rhs)
        }
        fatalError("operation 'plus' invalid for \(self) and \(rhs)")
    }
    
    public func minus(rhs: Value) -> Value {
        if case let .integer(lhs) = self, case let .integer(rhs) = rhs {
            return .integer(value: lhs - rhs)
        }
        fatalError("operation 'minus' invalid for \(self) and \(rhs)")
    }
    
    public func times(rhs: Value) -> Value {
        if case let .integer(lhs) = self, case let .integer(rhs) = rhs {
            return .integer(value: lhs * rhs)
        }
        fatalError("operation 'times' invalid for \(self) and \(rhs)")
    }
    
    public func div(rhs: Value) -> Value {
        if case let .integer(lhs) = self, case let .integer(rhs) = rhs {
            return .integer(value: lhs / rhs)
        }
        fatalError("operation 'div' invalid for \(self) and \(rhs)")
    }
    
    /**
     * Returns a string representation of this value that is similar
     * to the syntax used in source code. Used when printing AST and
     * when printing values in REPL.
     */
    public func repr() -> String {
        switch self {
        case let .string(value):
            return "\"" + value.split(separator: "\"").joined(separator: "\\\"") + "\""
        default:
            return self.description
        }
    }
    
    /**
     * Returns the [Type] associated with this value.
     */
    public var type: Type {
        switch self {
        case .unit:
            return Type.unit
        case .bool(_):
            return Type.boolean
        case .integer(_):
            return Type.int
        case .string(_):
            return Type.string
        case let .function(function):
            return Type.function(function.signature)
        case let .array(_, elementType):
            return Type.array(elementType: elementType)
        case .pointer(_, _):
            fatalError("pointers are internal objects that have no visible type")
        }
    }
    
    /** Are values of this type subject to constant propagation? */
    public var mayInline: Bool {
        switch self {
        case .function, .array:
            return false
        default:
            return true
        }
    }
    
    public func lessThan(r: Value) -> Bool {
        switch (self, r) {
        case let (.string(lhs), .string(rhs)):
            return lhs < rhs
        case let (.integer(lhs), .integer(rhs)):
            return lhs < rhs
        case let (.bool(lhs), .bool(rhs)):
            return Int(lhs) < Int(rhs)
        default:
            fatalError("< not supported for \(self) and \(r)")
        }
    }
    
    public var description: String {
        switch self {
        case .unit:
            return "Unit"
        case let .bool(value):
            return value.description
        case let .integer(value):
            return value.description
        case let .string(value):
            return value.description
        case let .function(function):
            switch function.signature {
            case let .function(argumentTypes, returnType):
                return "fun \(function.name)(\(argumentTypes.map { $0.description }.joined(separator: ", "))): \(returnType)"
            }
        case let .array(elements, _):
            return "[\(elements.array.map { $0.description }.joined(separator: ", "))]"
        case let .pointer(value, _):
            return "Pointer.Code(\(value.description))"
        }
    }
}

public class ArrayReference: Hashable {
    public static func == (lhs: ArrayReference, rhs: ArrayReference) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }
    
    internal var array: Array<Value>
    
    init(array: Array<Value>) {
        self.array = array
    }
}

public class FunctionReference: Hashable {
    public static func == (lhs: FunctionReference, rhs: FunctionReference) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }
    
    let function: (Array<Value>) throws -> Value
    
    init(function: @escaping (Array<Value>) throws -> Value) {
        self.function = function
    }
}
