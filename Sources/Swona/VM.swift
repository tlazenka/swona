/**
 * Integer-addressable segment of [Value]s.
 *
 * The segment grows as needed because it is used for things for which we can't determine
 * the original size. (For example the call stack of the system.)
 */
public struct DataSegment: CustomStringConvertible {
    
    private var bindings = [Value?](repeating: nil, count: 1024)
    
    subscript(index: Int) -> Value {
        /**
         * Assigns a new value to existing variable.
         */
        set(value) {
            ensureCapacity(capacity: index + 1)
            bindings[index] = value
        }
        
        /**
         * Returns the value bound to given variable.
         */
        get {
            // We don't need to call ensureCapacity here because we can never read uninitialized values
            guard let result = bindings[index] else {
                fatalError("uninitialized read at \(index)")
            }
            return result
        }
    }
    
    /**
     * Returns the value bound to given variable.
     */
    subscript(base: Int, offset: Int) -> Value {
        get {
            // We don't need to call ensureCapacity here because we can never read uninitialized values
            guard let result = bindings[base + offset] else { fatalError("uninitialized read at \(base)+\(offset)") }
            return result
        }
    }
    
    private mutating func ensureCapacity(capacity: Int) {
        if (capacity > bindings.count) {
            let newSize = max(capacity, bindings.count * 2) - bindings.count
            
            bindings = bindings + [Value?](repeating: nil, count: newSize)
        }
    }

    public var description: String {
        return "[\(bindings.prefix(10).map { $0!.description }.joined(separator: ", "))]"
    }
    
}

public enum OpCode: CustomStringConvertible {
    func relocate(baseAddress: Int) -> OpCode {
        switch self {
        case let .jump(address):
            return .jump(address: baseAddress + address)
        case let .jumpIfFalse(sp, address):
            return .jumpIfFalse(sp: sp ,address: baseAddress + address)
        default:
            return self
        }
    }
    
    case not(target: Int, source: Int)
    
    public enum Binary {
        case add(target: Int, lhs: Int, rhs: Int)
        case subtract(target: Int, lhs: Int, rhs: Int)
        case multiply(target: Int, lhs: Int, rhs: Int)
        case divide(target: Int, lhs: Int, rhs: Int)
        case equal(target: Int, lhs: Int, rhs: Int)
        case lessThan(target: Int, lhs: Int, rhs: Int)
        case lessThanOrEqual(target: Int, lhs: Int, rhs: Int)
        case concatString(target: Int, lhs: Int, rhs: Int)
        
        var name: String {
            switch self {
            case .add:
                return "+"
            case .subtract:
                return "-"
            case .multiply:
                return "*"
            case .divide:
                return "/"
            case .equal:
                return "=="
            case .lessThan:
                return "<"
            case .lessThanOrEqual:
                return "<="
            case .concatString:
                return "++"
                
            }
        }
        
        public var target: Int {
            switch self {
            case let .add(target, _, _),
                 let .subtract(target, _, _),
                 let .multiply(target, _, _),
                 let .divide(target, _, _),
                 let .equal(target, _, _),
                 let .lessThan(target, _, _),
                 let .lessThanOrEqual(target, _, _),
                 let .concatString(target, _, _):
                return target
                
            }
        }
        
        public var lhs: Int {
            switch self {
            case let .add(_, lhs, _),
                 let .subtract(_, lhs, _),
                 let .multiply(_, lhs, _),
                 let .divide(_, lhs, _),
                 let .equal(_, lhs, _),
                 let .lessThan(_, lhs, _),
                 let .lessThanOrEqual(_, lhs, _),
                 let .concatString(_, lhs, _):
                return lhs
                
            }
        }
        
        public var rhs: Int {
            switch self {
            case let .add(_, _, rhs),
                 let .subtract(_, _, rhs),
                 let .multiply(_, _, rhs),
                 let .divide(_, _, rhs),
                 let .equal(_, _, rhs),
                 let .lessThan(_, _, rhs),
                 let .lessThanOrEqual(_, _, rhs),
                 let .concatString(_, _, rhs):
                return rhs
                
            }
        }
        
    }
    
    case binary(Binary)
    case nop
    case call(offset: Int, argumentCount: Int)
    case restoreFrame(sp: Int)
    case ret(valuePointer: Int, returnAddressPointer: Int)
    case copy(target: Int, source: Int, description: String)
    case loadConstant(target: Int, value: Value)
    case loadGlobal(target: Int, sourceGlobal: Int, name: String)
    case storeGlobal(targetGlobal: Int, source: Int, name: String)
    case jump(address: Int)
    case jumpIfFalse(sp: Int, address: Int)
    
    public var description: String {
        switch self {
        case let .not(target, source):
            return "stack[fp+\(target)] = !stack[fp+\(source)]"
        case let .binary(binary):
            return  "stack[fp+\(binary.target)] = stack[fp+\(binary.lhs)] \(binary.name) stack[fp+\(binary.rhs)]"
        case .nop:
            return "Nop"
        case let .call(offset, argumentCount):
            return "call stack[fp+\(offset)], \(argumentCount)"
        case let .restoreFrame(sp):
            return "fp = fp - \(sp)"
        case let .ret(valuePointer, returnAddressPointer):
            return "ret value=stack[fp+\(valuePointer)], address=stack[fp+\(returnAddressPointer)]"
        case let .copy(target, source, description):
            return "stack[fp+\(target)] = stack[fp+\(source)] ; \(description)"
        case let .loadConstant(target, value):
            return "stack[fp+\(target)] = \(value.repr())"
        case let .loadGlobal(target, sourceGlobal, name):
            return "stack[fp+\(target)] = heap[\(sourceGlobal)] ; \(name)"
        case let .storeGlobal(targetGlobal, source, name):
            return "heap[\(targetGlobal)] = stack[fp+\(source)] ; \(name)"
        case let .jump(address):
            return "jump \(address)"
        case let .jumpIfFalse(sp, address):
            return "jump-if-false stack[fp+\(sp)] \(address)"
            
        }
    }
}

/**
 * A random-accessible segment of opcodes.
 */
public struct CodeSegment: CustomStringConvertible {
    private let opCodes: [OpCode]
    
    init(opCodes: [OpCode]) {
        self.opCodes = opCodes
    }
    
    init() {
        self.init(opCodes: [])
    }
    
    /**
     * Returns [OpCode] with given address.
     */
    subscript(address: Int) -> OpCode {
        get {
            return opCodes[address]
        }
    }
    
    var size: Int {
        return opCodes.count
    }
    
    func mergeWithRelocatedSegment(segment: CodeSegment) -> (CodeSegment, Int) {
        var ops = Array<OpCode>()
        let address = opCodes.count
        
        ops += opCodes
        for op in segment.opCodes {
            ops += [op.relocate(baseAddress: address)]
        }
        
        return (CodeSegment(opCodes: ops), address)
    }
    
    /**
     * Extracts given region of code, relocated so that every address makes sense
     * (assuming the addresses stay within the region).
     *
     * Useful for dumping function code for inspection.
     */
    func getRegion(address: Int, size: Int) -> CodeSegment {
        let ops = opCodes.subList(fromIndex: address, toIndex: address + size)
        
        return CodeSegment(opCodes: ops.map { $0.relocate(baseAddress: -address) })
    }
    
    public var description: String {
        return opCodes.enumerated().map { i, op in "\(i) \(op)" }.joined(separator: "\n")
    }
    
}

/**
 * Encapsulates the state of a single thread of execution.
 */
struct ThreadState: CustomStringConvertible {
    private var stack = DataSegment()
    
    /** Program counter: the next instruction to be executed */
    var pc = 0
    
    /** Frame pointer */
    var fp = 0
    
    subscript(offset: Int) -> Value {
        /**
         * Accesses data relative to current frame.
         */
        get {
            return stack[fp, offset]
        }
        
        /**
         * Accesses data relative to current frame.
         */
        set(value) {
            stack[fp + offset] = value
        }
    }
    
    
    /**
     * Returns the arguments from current stack-frame.
     */
    func getArgs(count: Int) -> Array<Value> {
        var values = Array<Value>()
        
        for i in 0...(count - 1) {
            values += [self[i]]
        }
        
        return values
    }
    
    public var description: String {
        return "  pc = \(pc)\n  fp = \(fp)\n  data = \(stack)"
    }
    
    mutating func evalBinary(op: OpCode, f: (Value, Value) -> Value) {
        guard case let .binary(binary) = op else {
            fatalError("invalid op to evalBinary: \(op.description)")
        }
        self[binary.target] = f(self[binary.lhs], self[binary.rhs])
    }
    
    mutating func evalBinaryBool(op: OpCode, f: (Value, Value) -> Bool) {
        guard case let .binary(binary) = op else {
            fatalError("invalid op to evalBinaryBool: \(op.description)")
        }
        self[binary.target] = .bool(value: f(self[binary.lhs], self[binary.rhs]))
    }
}

public struct EvaluationResult {
    public let value: Value
    public let type: Type
}

/**
 * Evaluator for opcodes.
 *
 * @see OpCode
 */
public class Evaluator {
    var globalData = DataSegment()
    let globalTypeEnvironment = GlobalStaticEnvironment()
    private var globalCode = CodeSegment()
    private let functionTranslator: FunctionTranslator
    public var trace = false
    public var optimize = true
    
    public init(trace: Bool = false) {
        self.functionTranslator = FunctionTranslator(env: globalTypeEnvironment)
        self.trace = trace
    }
    
    /**
     * Binds a global name to given value.
     */
    public func bind(name: String, value: Value, mutable: Bool = true) throws {
        let bindingReference = try globalTypeEnvironment.bind(name: name, type: value.type, mutable: mutable)
        globalData[bindingReference.binding.index] = value
    }
    
    /**
     * Evaluates code which can either be a definition, statement or expression.
     * If the code represented an expression, returns its value. Otherwise [Value.Unit] is returned.
     */
    @discardableResult public func evaluate(code: String) throws -> EvaluationResult {
        if (try LookaheadLexer(source: code).nextTokenIs(token: Token.keyword(.fun))) {
            let definition = try parseFunctionDefinition(code: code)
            try bindFunction(func: definition)
            return EvaluationResult(value: Value.unit, type: Type.unit)
        }
        else {
            let (segment, type) = try translate(code: code)
            return EvaluationResult(value: try evaluateSegment(segment: segment), type: type)
        }
    }
    
    /**
     * Loads contents of given file.
     */
    public func loadResource(source: String, file: String) throws {
        let defs = try parseFunctionDefinitions(code: source, file: file)
    
        for def in defs {
            try bindFunction(func: def)
        }
    }
    
    /**
     * Returns the names of all global bindings.
     */
    public func bindingsNames() -> Set<String> {
        return globalTypeEnvironment.bindingNames()
    }
    
    /**
     * Translates given code to opcodes and returns string representation of the opcodes.
     */
    public func dump(code: String) throws -> String {
        let exp = try parseAndTypeCheck(code: code)
        if case let .ref(bindingReference) = exp, case .function(_) = exp.type {
            let value = globalData[bindingReference.binding.index]
            guard case let .function(function) = value else {
                fatalError("expected function, got \(value)")
            }
            
            switch function {
            case let .compound(address, codeSize, _, _):
                return globalCode.getRegion(address: address, size: codeSize).description
            case .native(_, _, _):
                return "native function \(value)"
            }
        }
        else {
            return try translate(exp: exp).description
        }
    }
    
    /**
     * Compiles and binds a global function.
     */
    public func bindFunction(func: FunctionDefinition) throws {
        // We have to create the binding into global environment before calling createFunction
        // because the function might want to call itself recursively. But if createFunction fails
        // (most probably to type-checking), we need to unbind the binding.
        var binding: Binding?
        if let returnType = `func`.returnType {
            binding = try globalTypeEnvironment.bind(name: `func`.name, type: Type.function(.function(argumentTypes: `func`.args.map { $0.1 }, returnType: returnType)), mutable: false).binding
            
        }
        
        do {
            let (signature, code) = try functionTranslator.translateFunction(func: `func`, optimize: optimize)
            
            let (newGlobalCode, address) = globalCode.mergeWithRelocatedSegment(segment: code)
            globalCode = newGlobalCode
            if (binding == nil) {
                binding = try globalTypeEnvironment.bind(name: `func`.name, type: .function(signature), mutable: false).binding
            }
            
            globalData[binding!.index] = Value.function(.compound(address: address, codeSize: code.size, name: `func`.name, signature: signature))
        }
        catch {
            if (binding != nil) {
                globalTypeEnvironment.unbind(name: `func`.name)
            }
            throw error
        }
    }
    
    /**
     * Translates code to opcodes.
     */
    private func translate(code: String) throws -> (CodeSegment, Type) {
        let exp = try parseAndTypeCheck(code: code)
        return (try translate(exp: exp), exp.type)
    }
    
    public func translate(exp: TypedExpression) throws -> CodeSegment {
        let optExp: TypedExpression
        if (optimize) {
            optExp = exp.optimize()
        }
        else {
            optExp = exp
        }
        
        let blocks = optExp.translateToIR()
        
        if (optimize) {
            blocks.optimize()
        }
        
        return try blocks.translateToCode(argumentCount: 0)
    }
    
    private func parseAndTypeCheck(code: String) throws -> TypedExpression {
        return try parseExpression(code: code).typeCheck(env: globalTypeEnvironment)
    }
    
    /**
     * Evaluates given code segment.
     */
    public func evaluateSegment(segment: CodeSegment) throws -> Value {
        let (code, startAddress) = globalCode.mergeWithRelocatedSegment(segment: segment)
        let quitPointer = Value.pointer(value: -1, .code)
        
        var state = ThreadState()
        state.pc = startAddress
        state.fp = 0
        state[0] = quitPointer
        var run = true
        while(run) {
            let op = code[state.pc]
            if (trace) {
                print("\(state.pc.description.padStart(count: 4)): \(op.description.padEnd(count: 40)) [fp=\(state.fp)]")
            }
            
            state.pc += 1
            
            switch(op) {
            case let .not(target, source):
                let s = state[source]
                guard case let .bool(value) = s else {
                    fatalError("expected bool, got \(s)")
                }
                state[target] = .bool(value: !(value))
            case let .binary(binary):
                switch(binary) {
                case .add             : state.evalBinary(op: op) { l, r in l.plus(rhs: r) }
                case .subtract        : state.evalBinary(op: op) { l, r in l.minus(rhs: r) }
                case .multiply        : state.evalBinary(op: op) { l, r  in l.times(rhs: r) }
                case .divide          : state.evalBinary(op: op) { l, r  in l.div(rhs: r) }
                case .equal           : state.evalBinaryBool(op: op) { l, r in l == r }
                case .lessThan        : state.evalBinaryBool(op: op) { l, r in l.lessThan(r: r) }
                case .lessThanOrEqual : state.evalBinaryBool(op: op) { l, r in ((l == r) || (l.lessThan(r: r))) }
                case .concatString    : state.evalBinary(op: op) { l, r in l.plus(rhs: r) }
                }
            case let .loadConstant(target, value): state[target] = value
            case let .copy(target, source, _): state[target] = state[source]
            case let .loadGlobal(target, sourceGlobal, _): state[target] = globalData[sourceGlobal]
            case let .storeGlobal(targetGlobal, source, _): globalData[targetGlobal] = state[source]
            case let .jump(address): state.pc = address
            case let .jumpIfFalse(sp, address):
                let s = state[sp]
                guard case let .bool(value) = s else {
                    fatalError("expected bool, got \(s)")
                }
                if !(value) {
                    state.pc = address
                }
            case .call(_, _): try evalCall(op: op, state: &state)
            case let .restoreFrame(sp): state.fp -= sp
            case let .ret(valuePointer, returnAddressPointer):
                let returnAddress = state[returnAddressPointer]
                state[0] = state[valuePointer]
                if (returnAddress == quitPointer) {
                    run = false
                    break
                }
                guard case let .pointer(value, type) = returnAddress, type == .code else {
                    fatalError("expected bool, got \(returnAddress)")
                }
                
                state.pc = value
            case .nop: break
            }
        }
        return state[0]
    }
    
    private func evalCall(op: OpCode, state: inout ThreadState) throws {
        guard case let .call(offset, argumentCount) = op else {
            fatalError("expected call, got: \(op)")
        }
        
        guard case let .function(`func`) = state[offset] else {
            fatalError("expected function, got: \(op)")
        }
        
        state.fp += offset - argumentCount
        switch `func` {
        case let .compound(address, _, _, _):
            state[argumentCount] = Value.pointer(value: state.pc, .code)
            state.pc = address
        case let .native(`func`, _, _):
            let args = state.getArgs(count: argumentCount)
            state[0] = try `func`.function(args)
        }
        
    }
}

