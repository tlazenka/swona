/**
 * Creates a single argument primitive function.
 */
public func fun1(name: String, argType: Type, returnType: Type, `func`: @escaping (Value) throws -> Value) -> Value.Function {
    let signature = Type.Function.function(argumentTypes: [argType], returnType: returnType)
    return .native(func: FunctionReference(function: { args in try `func`(args.single())}), name: name, signature: signature)
}

public func fun1(name: String, argType: Type, `func`: @escaping (Value) throws -> Value) -> Value.Function {
    return fun1(name: name, argType: argType, returnType: .unit, func: `func`)
}

public func fun2(name: String, argType1: Type, argType2: Type, returnType: Type, `func`: @escaping (Value, Value) throws -> Value) -> Value.Function {
    let signature = Type.Function.function(argumentTypes: [argType1, argType2], returnType: returnType)
    return .native(func: FunctionReference(function: { args in
        precondition(args.count == 2)
        return try `func`(args[0], args[1])}), name: name, signature: signature)
}

public func fun2(name: String, argType: Type, returnType: Type, `func`: @escaping (Value, Value) throws -> Value) -> Value.Function {
    return fun2(name: name, argType1: argType, argType2: argType, returnType: returnType, func: `func`)
}

public func fun3(name: String, argType1: Type, argType2: Type, argType3: Type, returnType: Type, `func`: @escaping (Value, Value, Value) throws -> Value) -> Value.Function {
    let signature = Type.Function.function(argumentTypes: [argType1, argType2, argType3], returnType: returnType)
    return .native(func: FunctionReference(function: { args in
        precondition(args.count == 3)
        return try `func`(args[0], args[1], args[2])}), name: name, signature: signature)
}

extension Evaluator {
    func bindFunction(`func`: Value.Function) throws {
        try bind(name: `func`.name, value: .function(`func`), mutable: false)
    }
}

struct RuntimeError: Error {
    let message: Any
}

public func registerRuntimeFunctions(evaluator: Evaluator) throws {
    try evaluator.bindFunction(func: fun1(name: "println", argType: .string, func: {
        #warning("Remodel")
        guard case .string = $0 else {
            fatalError("Expected string, got \($0.description)")
        }
        print($0.description)
        return .unit
    }))
    
    try evaluator.bindFunction(func: fun1(name: "error", argType: .string, func: {
        guard case .string = $0 else {
            fatalError("Expected string, got \($0.description)")
        }
        throw RuntimeError(message: $0)
    }))
    
    try evaluator.bindFunction(func: fun2(name: "stringArrayOfSize", argType1: .int, argType2: .string, returnType: .array(elementType: .string), func: {
        (size, initialValue) in
        guard case let .integer(s) = size, case let .string(i) = initialValue else {
            fatalError("Expected int size and string initialValue, got \(size) and \(initialValue)")
        }
        return .array(elements: ArrayReference(array: Array<Value>(repeating: .string(value: i), count: s)), elementType: .string)
    }))
    
    try evaluator.bindFunction(func: fun1(name: "stringArrayLength", argType: .array(elementType:.string), returnType: .int, func: {
        guard case let .array(elements, _) = $0 else {
            fatalError("Expected array, got \($0.description)")
        }
        return .integer(value: elements.array.count)
    }))
    
    try evaluator.bindFunction(func: fun2(name: "stringArrayGet", argType1: .array(elementType: .string), argType2: .int, returnType: .string, func: {
        (array, index) in
        guard case let .array(elements, elementType) = array, elementType == .string, case let .integer(i) = index else {
            fatalError("Expected string array and int index, got \(array) and \(index)")
        }
        return elements.array[i]
    }))
    
    try evaluator.bindFunction(func: fun3(name: "stringArraySet", argType1: .array(elementType: .string), argType2: .int, argType3: .string, returnType: .unit, func: {
        (array, index, value) in
        guard case let .array(elements, elementType) = array, elementType == .string, case let .integer(i) = index, case .string = value else {
            fatalError("Expected string array and int index and string value, got \(array) and \(index) and \(value)")
        }
        elements.array[i] = value
        return .unit
    }))

}
