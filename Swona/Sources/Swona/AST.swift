/**
 * Represents expressions of the program.
 *
 * In addition to the logical structure of the source code, each expression
 * contains [location] referring to the location in source code where this
 * expression is written. It is used to provide context for error messages.
 *
 * The string representation of expressions does not try to mimic the original
 * source code, but rather provides a simple, compact and unambiguous syntax for
 * trees. Apart from debugging, its used in tests to verify the expected structure
 * of the parse tree.
 */

public indirect enum Expression: CustomStringConvertible {
    /** Reference to a variable. */
    case ref(name: String, location: SourceLocation)
    
    /** Literal value. */
    case lit(value: Value, location: SourceLocation)
    
    /** Logical not. */
    case not(exp: Expression, location: SourceLocation)
    
    /** Function call. */
    case call(func: Expression, args: Array<Expression>)
    
    case binary(Binary)
    
    /** Binary operators. */
    public enum Binary: CustomStringConvertible {
        /** lhs + rhs */
        case plus(lhs: Expression, rhs: Expression, location: SourceLocation)
        
        /** lhs - rhs */
        case minus(lhs: Expression, rhs: Expression, location: SourceLocation)
        
        /** lhs * rhs */
        case multiply(lhs: Expression, rhs: Expression, location: SourceLocation)
        
        /** lhs / rhs */
        case divide(lhs: Expression, rhs: Expression, location: SourceLocation)
        
        /** lhs && rhs */
        case and(lhs: Expression, rhs: Expression, location: SourceLocation)
        
        /** lhs || rhs */
        case or(lhs: Expression, rhs: Expression, location: SourceLocation)
        
        /** =, !=, <, >, <=, >= */
        case relational(op: RelationalOp, lhs: Expression, rhs: Expression, location: SourceLocation)
        
        public var location: SourceLocation {
            switch self {
            case let .plus(_, _, location),
                 let .minus(_, _, location),
                 let .multiply(_, _, location),
                 let .divide(_, _, location),
                 let .and(_, _, location),
                 let .or(_, _, location),
                 let .relational(_, _, _, location):
                return location
            }
        }
        
        public var description: String {
            switch self {
            case let .plus(lhs, rhs, _):
                return "[Plus \(lhs) \(rhs)]"
            case let .minus(lhs, rhs, _):
                return "[Minus \(lhs) \(rhs)]"
            case let .multiply(lhs, rhs, _):
                return "[Multiply \(lhs) \(rhs)]"
            case let .divide(lhs, rhs, _):
                return "[Divide \(lhs) \(rhs)]"
            case let .and(lhs, rhs, _):
                return "[And \(lhs) \(rhs)]"
            case let .or(lhs, rhs, _):
                return "[Or \(lhs) \(rhs)]"
            case let .relational(op, lhs, rhs, _):
                return "[\(op) \(lhs) \(rhs)]"
            }
        }
    }
    
    /** Assignment to a variable. */
    case assign(variable: String, expression: Expression, location: SourceLocation)
    
    /** Definition of a variable. */
    case `var`(variable: String, expression: Expression, mutable: Bool, location: SourceLocation)
    
    /** If-statement with optional else clause. */
    case `if`(condition: Expression, consequent: Expression, alternative: Expression?, location: SourceLocation)
    
    /** While-statement. */
    case `while`(condition: Expression, body: Expression, location: SourceLocation)
    
    /** List of statements */
    case `expressionList`(expressions: [Expression], location: SourceLocation)
    
    public var location: SourceLocation {
        switch self {
        case let .assign(_, _, location):
            return location
        case let .binary(binary):
            return binary.location
        case let .call(`func`, _):
            return `func`.location
        case let .expressionList(_, location):
            return location
        case let .if(_, _, _, location):
            return location
        case let .lit(_, location):
            return location
        case let .not(_, location):
            return location
        case let .ref(_, location):
            return location
        case .var(_, _, _, let location):
            return location
        case .while(_, _, let location):
            return location
        }
    }
    
    public var description: String {
        switch self {
        case let .ref(name, _):
            return "[Ref \(name)]"
        case let .lit(value, _):
            return "[Lit \(value.repr())]"
        case let .not(expression, _):
            return "[Not \(expression.description)]"
        case let .call(`func`, args):
            return "[Call \(`func`.description) \(args.description)]"
        case let .assign(variable, expression, _):
            return "[Assign \(variable.description) \(expression.description)]"
        case let .`if`(condition, consequent, alternative, _):
            return "[If \(condition) \(consequent) \(alternative?.description ?? "[]")]"
        case let .`while`(condition, body, _):
            return "[While \(condition) \(body)]"
        case let .`expressionList`(expressions, _):
            return "[ExpressionList \(expressions)]"
        case let .`var`(variable, expression, mutable, _):
            return "[\((mutable) ? "Var" : "Val") \(variable) \(expression)]"
        case let .binary(value):
            return value.description
        }
    }
    
}

public struct FunctionDefinition: CustomStringConvertible {
    let name: String
    let args: Array<(String, Type)>
    let returnType: Type?
    let body: Expression

    public var description: String {
        let argsDescription = args.map { "(\($0.0), \($0.1))" }.joined(separator: ", ")
        return "FunctionDefinition(name=\(name), args=[\(argsDescription)], returnType=\(returnType?.description ?? "null"), body=\(body.description))"
    }
    
}

public enum RelationalOp: String, CustomStringConvertible {
    case equals = "=="
    case notEquals = "!="
    case lessThan = "<"
    case lessThanOrEqual = "<="
    case greaterThan = ">"
    case greaterThanOrEqual = ">="
    
    public var description: String { return self.rawValue }
}


