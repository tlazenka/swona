@dynamicMemberLookup
public struct Bridge {
    public init() throws {
        evaluator = Evaluator(trace: false)
        try registerRuntimeFunctions(evaluator: evaluator)
    }

    public let evaluator: Evaluator

    public subscript(dynamicMember member: String) -> Value? {
        get {
            guard let bindingReference = evaluator.globalTypeEnvironment.bindings[member] else {
                return nil
            }
            return evaluator.globalData[bindingReference.binding.index]
        }

        nonmutating set {
            evaluator.globalTypeEnvironment.unbind(name: member)
            if let newValue = newValue {
                try! evaluator.bind(name: member, value: newValue)
            }
        }
    }

    public subscript(dynamicMember member: String) -> Expression {
        member.ref
    }

    public subscript(dynamicMember member: String) -> BridgeRuntimeFunction {
        BridgeRuntimeFunction(evaluator: evaluator, name: member)
    }
}

@dynamicCallable
public struct BridgeRuntimeFunction {
    let evaluator: Evaluator
    let name: String

    public init(evaluator: Evaluator, name: String) {
        self.evaluator = evaluator
        self.name = name
    }

    @discardableResult
    public func dynamicallyCall(withArguments arguments: [Expression]) throws -> Value {
        let expression = Expression.call(func: .ref(name: name, location: bridgeSourceLocation()), args: arguments)

        let typeChecked = try expression.typeCheck(env: evaluator.globalTypeEnvironment)
        let translated = try evaluator.translate(exp: typeChecked)
        let evaluated = try evaluator.evaluateSegment(segment: translated)

        return EvaluationResult(value: evaluated, type: typeChecked.type).value
    }
}

extension String {
    public var lit: Expression {
        Expression.lit(value: value, location: bridgeSourceLocation())
    }

    public var ref: Expression {
        Expression.ref(name: self, location: bridgeSourceLocation())
    }
}

extension Int {
    public var lit: Expression {
        Expression.lit(value: value, location: bridgeSourceLocation())
    }
}

func bridgeSourceLocation(file: String = #file) -> SourceLocation {
    SourceLocation(file: file, line: 0, column: 0, lineText: "")
}

extension Value.Function {
    public func callAsFunction(_ values: Value...) -> Any {
        switch self {
        case .compound:
            fatalError("Cannot call compound function")
        case let .native(`func`, _, _):
            guard let result = try? `func`.function(values) else {
                fatalError("Could not evaluate function")
            }
            return result
        }
    }
}

extension Value: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value: value)
    }
}

extension Value: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .integer(value: value)
    }
}

extension Value: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value: value)
    }
}

extension Value: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Value...) {
        let types = Set(elements.map(\.type))

        guard let type = types.first, types.count == 1 else {
            fatalError("Only arrays of a single type are supported")
        }

        self = .array(elements: .init(array: elements), elementType: type)
    }
}
