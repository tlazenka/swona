@dynamicMemberLookup
public struct Bridge {
    public init() throws {
        self.evaluator = Evaluator(trace: false)
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
        return member.ref
    }

    
    public subscript(dynamicMember member: String) -> BridgeRuntimeFunction {
        get {
            return BridgeRuntimeFunction(evaluator: evaluator, name: member)
        }
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
        return Expression.lit(value: self.value, location: bridgeSourceLocation())
    }
    
    public var ref: Expression {
        return Expression.ref(name: self, location: bridgeSourceLocation())
    }
}

extension Int {
    public var lit: Expression {
        return Expression.lit(value: self.value, location: bridgeSourceLocation())
    }
}

func bridgeSourceLocation(file: String = #file) -> SourceLocation {
    return SourceLocation(file: file, line: 0, column: 0, lineText: "")
}

