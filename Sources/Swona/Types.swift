/**
 * Represents the types supported in the language.
 */
public indirect enum Type: Equatable, Hashable, CustomStringConvertible {
    case string
    case int
    case boolean
    case unit
    case function(Function)
    case array(elementType: Type)

    public enum Function: Equatable, Hashable {
        case function(argumentTypes: [Type], returnType: Type)
    }

    func supports(op: RelationalOp) -> Bool {
        switch self {
        case .unit, .function:
            return false
        case .array:
            return [.equals, .notEquals].contains(op)
        default:
            return true
        }
    }

    public var description: String {
        switch self {
        case .string:
            return "String"
        case .int:
            return "Int"
        case .boolean:
            return "Boolean"
        case .unit:
            return "Unit"
        case let .array(elementType):
            return "Array<\(elementType)>"
        case let .function(function):
            switch function {
            case let .function(argumentTypes, returnType):
                return "(\(argumentTypes.map(\.description).joined(separator: ", "))) -> \(returnType)"
            }
        }
    }
}

/**
 * Represents an expression that has been type-checked and therefore has a known [type].
 *
 * The tree is mostly analogous to expressions in the original AST, but there are some
 * differences.
 *
 * For example, there are some new nodes with more explicit meaning. For example, while `1 + 2` is translated
 * to [TypedExpression.Binary.Plus], expressions `"foo" + "bar"` or `"foo" + 1` will be translated
 * to [TypedExpression.Binary.ConcatString].
 *
 * @see Type
 */
public indirect enum TypedExpression: CustomStringConvertible {
    /** Reference to a variable. */
    case ref(bindingReference: BindingReference)

    /** Literal value */
    case lit(value: Value, type: Type)

    /** Logical not. */
    case not(exp: TypedExpression)

    /** Function call. */
    case call(func: TypedExpression, args: [TypedExpression], type: Type)

    case binary(Binary)

    /** Binary operators. */
    public enum Binary: CustomStringConvertible {
        /** Numeric addition */
        case plus(lhs: TypedExpression, rhs: TypedExpression, type: Type)

        /** Numeric subtraction */
        case minus(lhs: TypedExpression, rhs: TypedExpression, type: Type)

        /** Numeric multiplication */
        case multiply(lhs: TypedExpression, rhs: TypedExpression, type: Type)

        /** Numeric division */
        case divide(lhs: TypedExpression, rhs: TypedExpression, type: Type)

        /** String concatenation */
        case concatString(lhs: TypedExpression, rhs: TypedExpression)

        /** =, !=, <, >, <=, >= */
        case relational(op: RelationalOp, lhs: TypedExpression, rhs: TypedExpression)

        var lhs: TypedExpression {
            switch self {
            case let .plus(lhs, _, _),
                 let .minus(lhs, _, _),
                 let .multiply(lhs, _, _),
                 let .divide(lhs, _, _),
                 let .concatString(lhs, _),
                 let .relational(_, lhs, _):
                return lhs
            }
        }

        var rhs: TypedExpression {
            switch self {
            case let .plus(_, rhs, _),
                 let .minus(_, rhs, _),
                 let .multiply(_, rhs, _),
                 let .divide(_, rhs, _),
                 let .concatString(_, rhs),
                 let .relational(_, _, rhs):
                return rhs
            }
        }

        var type: Type {
            switch self {
            case let .plus(_, _, type):
                return type
            case let .minus(_, _, type):
                return type
            case let .multiply(_, _, type):
                return type
            case let .divide(_, _, type):
                return type
            case .concatString:
                return Type.string
            case .relational:
                return Type.boolean
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
            case let .concatString(lhs, rhs):
                return "[ConcatString \(lhs) \(rhs)]"
            case let .relational(op, lhs, rhs):
                return "[\(op) \(lhs) \(rhs)]"
            }
        }
    }

    case assign(variable: BindingReference, expression: TypedExpression)

    case `var`(variable: BindingReference, expression: TypedExpression)

    case `if`(condition: TypedExpression, consequent: TypedExpression, alternative: TypedExpression?, type: Type)

    case `while`(condition: TypedExpression, body: TypedExpression)

    case expressionList(expressions: [TypedExpression], type: Type)

    static var empty: TypedExpression {
        .expressionList(expressions: [], type: Type.unit)
    }

    public var type: Type {
        switch self {
        case let .ref(bindingReference):
            return bindingReference.type
        case let .lit(value, type):
            #warning("Remodel")
            switch value {
            case .integer:
                return Type.int
            case .bool:
                return Type.boolean
            case .string:
                return Type.string
            default:
                return type
            }
        case .not:
            return Type.boolean
        case let .call(_, _, type):
            return type
        case .assign:
            return Type.unit
        case .var:
            return Type.unit
        case let .if(_, _, alternative, type):
            #warning("Remodel")
            precondition((alternative != nil) || (type == Type.unit))
            return type
        case .while:
            return .unit
        case let .expressionList(_, type):
            return type
        case let .binary(binary):
            return binary.type
        }
    }

    public var description: String {
        switch self {
        case let .ref(bindingReference):
            return "[Ref \(bindingReference.name)]"
        case let .lit(value, _):
            return "[Lit \(value.repr())]"
        case let .not(exp):
            return "[Not \(exp)]"
        case let .call(`func`, args, _):
            return "[Call \(`func`) \(args)]"
        case let .assign(variable, expression):
            return "[Assign \(variable) \(expression)"
        case let .var(variable, expression):
            return "[Var \(variable) \(expression)]"
        case let .if(condition, consequent, alternative, _):
            return "[If \(condition) \(consequent) \(alternative?.description ?? "[]")]"
        case let .while(condition, body):
            return "[While \(condition) \(body)]"
        case let .expressionList(expressions, _):
            return "[ExpressionList \(expressions)]"
        case let .binary(binary):
            return binary.description
        }
    }
}

/**
 * Exception thrown if type checking code fails.
 */
public class TypeCheckException: Error {
    public let errorMessage: String
    public let sourceLocation: SourceLocation
    init(errorMessage: String, sourceLocation: SourceLocation) {
        self.errorMessage = errorMessage
        self.sourceLocation = sourceLocation
    }
}

/**
 * Type-checker for expressions.
 *
 * Type-checker walks through the syntax tree, maintaining a [StaticEnvironment] mapping
 * identifiers to their types and validates that all types agree. If type-checking
 * succeeds, the checker will return a simplified and type checked tree where each
 * expression is annotated with [Type]. If the checking fails, it will throw a
 * [TypeCheckException].
 */

extension Expression {
    public func typeCheck(env: StaticEnvironment) throws -> TypedExpression {
        switch self {
        case let .lit(value, _):
            return TypedExpression.lit(value: value, type: value.type)
        case let .ref(name, location):
            return .ref(bindingReference: try env.lookupBinding(name: name, location: location))
        case let .not(exp, _):
            return TypedExpression.not(exp: try exp.typeCheckExpected(expectedType: Type.boolean, env: env))
        case let .binary(binary):
            return try binary.typeCheck(env: env)
        case let .call(`func`, args):
            let typedFunc = try `func`.typeCheck(env: env)
            guard case let .function(function) = typedFunc.type else {
                throw TypeCheckException(errorMessage: "expected function type for call, but got \(typedFunc.type)", sourceLocation: location)
            }

            switch function {
            case let .function(argumentTypes, returnType):
                let expectedArgTypes = argumentTypes

                if args.count != expectedArgTypes.count {
                    throw TypeCheckException(errorMessage: "expected \(expectedArgTypes.count) arguments, but got \(args.count)", sourceLocation: location)
                }

                let typedArgs = try args.enumerated().map { i, arg in try arg.typeCheckExpected(expectedType: expectedArgTypes[i], env: env) }

                return TypedExpression.call(func: typedFunc, args: typedArgs, type: returnType)
            }
        case let .assign(variable, expression, location):
            let binding = try env.lookupBinding(name: variable, location: location)
            if !binding.mutable {
                throw TypeCheckException(errorMessage: "can't assign to immutable variable \(binding.name)", sourceLocation: location)
            }
            let typedLhs = try expression.typeCheckExpected(expectedType: binding.type, env: env)
            return TypedExpression.assign(variable: binding, expression: typedLhs)
        case let .var(variable, expression, mutable, location):
            let typed = try expression.typeCheck(env: env)
            let binding = try env.bindType(name: variable, type: typed.type, location: location, mutable: mutable)
            return TypedExpression.var(variable: binding, expression: typed)
        case let .if(condition, consequent, alternative, _):
            let typedCondition = try condition.typeCheckExpected(expectedType: Type.boolean, env: env)
            let typedConsequent = try consequent.typeCheck(env: env)
            let typedAlternative = try alternative?.typeCheck(env: env)

            let type: Type
            if typedAlternative != nil, typedConsequent.type == typedAlternative?.type {
                type = typedConsequent.type
            } else {
                type = Type.unit
            }

            return TypedExpression.if(condition: typedCondition, consequent: typedConsequent, alternative: typedAlternative, type: type)
        case let .while(condition, body, _):
            let typedCondition = try condition.typeCheckExpected(expectedType: Type.boolean, env: env)
            let typedBody = try body.typeCheck(env: env)
            return TypedExpression.while(condition: typedCondition, body: typedBody)
        case let .expressionList(expressions, _):
            let childEnv = env.newScope()
            let expressions = try expressions.map { try $0.typeCheck(env: childEnv) }
            let lastType = expressions.last?.type ?? Type.unit
            return TypedExpression.expressionList(expressions: expressions, type: lastType)
        }
    }

    func typeCheckExpected(expectedType: Type, env: StaticEnvironment) throws -> TypedExpression {
        try typeCheck(env: env).expectAssignableTo(expectedType: expectedType, location: location)
    }
}

extension Expression.Binary {
    func typeCheck(env: StaticEnvironment) throws -> TypedExpression {
        switch self {
        case let .plus(lhs, rhs, _):
            let typedLhs = try lhs.typeCheck(env: env)

            if typedLhs.type == .string {
                let typedRhs = try rhs.typeCheck(env: env)
                return .binary(.concatString(lhs: typedLhs, rhs: typedRhs))
            } else {
                let typedLhs2 = try typedLhs.expectAssignableTo(expectedType: Type.int, location: lhs.location)
                let typedRhs = try rhs.typeCheckExpected(expectedType: Type.int, env: env)
                return .binary(.plus(lhs: typedLhs2, rhs: typedRhs, type: Type.int))
            }
        case let .minus(lhs, rhs, _):
            let typedLhs = try lhs.typeCheckExpected(expectedType: .int, env: env)
            let typedRhs = try rhs.typeCheckExpected(expectedType: .int, env: env)
            return .binary(.minus(lhs: typedLhs, rhs: typedRhs, type: Type.int))
        case let .multiply(lhs, rhs, _):
            let typedLhs = try lhs.typeCheckExpected(expectedType: .int, env: env)
            let typedRhs = try rhs.typeCheckExpected(expectedType: .int, env: env)
            return .binary(.multiply(lhs: typedLhs, rhs: typedRhs, type: Type.int))
        case let .divide(lhs, rhs, _):
            let typedLhs = try lhs.typeCheckExpected(expectedType: .int, env: env)
            let typedRhs = try rhs.typeCheckExpected(expectedType: .int, env: env)
            return .binary(.divide(lhs: typedLhs, rhs: typedRhs, type: Type.int))
        case let .and(lhs, rhs, _):
            let typedLhs = try lhs.typeCheckExpected(expectedType: .boolean, env: env)
            let typedRhs = try rhs.typeCheckExpected(expectedType: .boolean, env: env)
            return TypedExpression.if(condition: typedLhs, consequent: typedRhs, alternative: TypedExpression.lit(value: Value.bool(value: false), type: .boolean), type: Type.boolean)
        case let .or(lhs, rhs, _):
            let typedLhs = try lhs.typeCheckExpected(expectedType: .boolean, env: env)
            let typedRhs = try rhs.typeCheckExpected(expectedType: .boolean, env: env)
            return TypedExpression.if(condition: typedLhs, consequent: TypedExpression.lit(value: Value.bool(value: true), type: .boolean), alternative: typedRhs, type: Type.boolean)
        case let .relational(op, lhs, rhs, location):
            let (l, r) = try typeCheckMatching(env: env, lhs: lhs, rhs: rhs, location: location)

            if !l.type.supports(op: op) {
                throw TypeCheckException(errorMessage: "operator \(op) is not supported for type \(l.type)", sourceLocation: location)
            }

            return .binary(.relational(op: op, lhs: l, rhs: r))
        }
    }

    func typeCheckMatching(env: StaticEnvironment, lhs: Expression, rhs: Expression, location: SourceLocation) throws -> (TypedExpression, TypedExpression) {
        let typedLhs = try lhs.typeCheck(env: env)
        let typedRhs = try rhs.typeCheck(env: env)

        if typedLhs.type != typedRhs.type {
            throw TypeCheckException(errorMessage: "lhs type \(typedLhs.type) did not match rhs type \(typedRhs.type)", sourceLocation: location)
        }

        return (typedLhs, typedRhs)
    }
}

extension TypedExpression {
    @discardableResult func expectAssignableTo(expectedType: Type, location: SourceLocation) throws -> TypedExpression {
        if type == expectedType {
            return self
        } else {
            throw TypeCheckException(errorMessage: "expected type \(expectedType), but was \(type)", sourceLocation: location)
        }
    }
}

extension StaticEnvironment {
    func lookupBinding(name: String, location: SourceLocation) throws -> BindingReference {
        guard let result = self[name] else {
            throw TypeCheckException(errorMessage: "unbound variable '\(name)'", sourceLocation: location)
        }
        return result
    }

    func bindType(name: String, type: Type, location: SourceLocation, mutable: Bool) throws -> BindingReference {
        do {
            return try bind(name: name, type: type, mutable: mutable)
        } catch {
            throw TypeCheckException(errorMessage: "variable already bound '\(name)'", sourceLocation: location)
        }
    }
}
