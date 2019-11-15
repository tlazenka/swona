extension TypedExpression {
    public func optimize() -> TypedExpression {
        return evaluateConstantExpressions()
    }
    
    public func evaluateConstantExpressions() -> TypedExpression {
        return eval(env: ConstantBindingEnv())
    }
    
    fileprivate func eval(env: ConstantBindingEnv) -> TypedExpression {
        switch self {
        case let .ref(bindingReference):
            guard let result = env[bindingReference] else {
                return self
            }
            return .lit(value: result, type: type)
        case .lit:
            return self
        case let .call(`func`, args, type):
            return .call(func: `func`.eval(env: env), args: args.map { $0.eval(env: env) }, type: type)
        case let .not(exp):
            let optExp = exp.eval(env: env)
            switch optExp {
            case let .lit(value, _):
                guard case let .bool(boolValue) = value else {
                    fatalError("invalid lit value: \(value.description)")
                }
                return .lit(value: .bool(value: !(boolValue)), type: Type.boolean)
            case let .not(exp):
                return exp
            default:
                return .not(exp: optExp)
            }
        case let .binary(binary):
            let optLhs = binary.lhs.eval(env: env)
            let optRhs = binary.rhs.eval(env: env)
            switch (optLhs, optRhs) {
            case let (.lit(lvalue, _), .lit(rvalue, _)):
                if case let .relational(op, _, _) = binary {
                    return .lit(value: Value.bool(value: op.evaluate(lhs: lvalue, rhs: rvalue)), type: .boolean)
                }
                if case .string = lvalue, case .concatString(_, _) = binary {
                    return .lit(value: lvalue.plus(rhs: rvalue), type: .string)
                }
                if case .integer(_) = lvalue, case let .integer(rvalueInt) = rvalue {
                    switch binary {
                    case .plus:
                        return .lit(value: lvalue.plus(rhs: rvalue), type: .int)
                    case .minus:
                        return .lit(value: lvalue.minus(rhs: rvalue), type: .int)
                    case .divide:
                        if (rvalueInt == 0) {
                            break
                        }
                        return .lit(value: lvalue.div(rhs: rvalue), type: .int)
                    case .multiply:
                        return .lit(value: lvalue.times(rhs: rvalue), type: .int)
                    default:
                        #warning("Remodel")
                        fatalError("invalid operation on integers: \(binary)")
                    }
                    
                }
            default:
                break
            }
            switch binary {
            case .plus:
                return .binary(.plus(lhs: optLhs, rhs: optRhs, type: type))
            case .minus:
                return .binary(.minus(lhs: optLhs, rhs: optRhs, type: type))
            case .multiply:
                return .binary(.multiply(lhs: optLhs, rhs: optRhs, type: type))
            case .divide:
                return .binary(.divide(lhs: optLhs, rhs: optRhs, type: type))
            case .concatString:
                return .binary(.concatString(lhs: optLhs, rhs: optRhs))
            case let .relational(op, _, _):
                return .binary(.relational(op: op, lhs: optLhs, rhs: optRhs))
                
            }
        case let .assign(variable, expression):
            return .assign(variable: variable, expression: expression.eval(env: env))
        case let .var(variable, expression):
            let value = expression.eval(env: env)
            if case let .lit(v, _) = value, v.mayInline, !(variable.mutable) {
                env[variable] = v
            }
            return .var(variable: variable, expression: value)
        case let .if(condition, consequent, alternative, type):
            let optCondition = condition.eval(env: env)
            if case let .lit(optCondition) = optCondition, case let .bool(value) = optCondition.value {
                if (value) {
                    return consequent.eval(env: env.child())
                }
                else {
                    return alternative?.eval(env: env.child()) ?? TypedExpression.empty
                }
            }
            return .if(condition: optCondition, consequent: consequent.eval(env: env.child()), alternative: alternative?.eval(env: env.child()), type: type);
        case let .while(condition, body):
            let optCondition = condition.eval(env: env)
            if case let .lit(optCondition) = optCondition, case let .bool(value) = optCondition.value, value == false {
                return TypedExpression.empty
            }
            return .while(condition: optCondition, body: body.eval(env: env.child()))
        case let .expressionList(expressions, type):
            let childEnv = env.child()
            return expressions.singleOrNull()?.eval(env: childEnv) ?? .expressionList(expressions: expressions.map { $0.eval(env: childEnv) }, type: type)
        }
    }
}

extension RelationalOp {
    
    func evaluate(lhs: Value, rhs: Value) -> Bool {
        switch self {
        case .equals:
            return lhs == rhs
        case .notEquals:
            return lhs != rhs
        case .lessThan:
            return lhs.lessThan(r: rhs)
        case .lessThanOrEqual:
            return (lhs.lessThan(r: rhs)) || (lhs == rhs)
        case .greaterThan:
            return rhs.lessThan(r: lhs)
        case .greaterThanOrEqual:
            return (rhs.lessThan(r: lhs)) || (lhs == rhs)
        }
    }
}

/**
 * Environment containing all constant bindings.
 */
private class ConstantBindingEnv {
    
    private let parent: ConstantBindingEnv?
    
    init(parent: ConstantBindingEnv? = nil) {
        self.parent = parent
    }
    
    private var constantBindings = [BindingReference:Value]()
    
    func child() -> ConstantBindingEnv {
        return ConstantBindingEnv(parent: self)
    }
    
    subscript(binding: BindingReference) -> Value? {
        set(value) {
            constantBindings[binding] = value
        }
        get {
            return constantBindings[binding] ?? parent?[binding]
        }
    }
}

extension BasicBlock {
    /**
     * Performs local optimizations to IR by looking at a small window of successive
     * instructions.
     */
    public func peepholeOptimize() {
        var modified = false
        repeat {
            modified = false
            for optimizer in optimizers {
                if (optimizer.optimize(basicBlock: self)) {
                    modified = true
                }
            }
            
        } while (modified)
    }
}

/** List of optimizers to run. */
private let optimizers: [PeepholeOptimizer] = [
    RedundantLoadStoreOptimizer(),
    RedundantLoadOptimizer(),
    RedundantPushUnitPopOptimizer(),
]

/**
 * Base class for peephole optimizers. Optimizers will implement the abstract
 * [optimizeWindow] method which will then get called with each [windowSize] sized
 * window of the [BasicBlock] to optimize.
 */
private protocol PeepholeOptimizer {
    
    var windowSize: Int { get }
    
    /**
     * Try to optimize a window of IR-sequence. If the optimizer detects
     * a pattern it can optimize, it will return a list of instructions
     * replacing the instructions of the original window. Otherwise it
     * will return null.
     */
    func optimizeWindow(window: Array<IR>) -> Array<IR>?
}

extension PeepholeOptimizer {
    /**
     * Apply optimizations to given [basicBlock].
     *
     * @return True if block was modified
     */
    #warning("Optimize")
    func optimize(basicBlock: BasicBlock) -> Bool {
        precondition(windowSize > 0)

        var modified = false
        
        var opCodes = basicBlock.opCodes
        var i = 0
        while i < opCodes.count {
            let end = i + windowSize
            let window = opCodes[i..<min(end, opCodes.count)]
            let left = opCodes[0..<i]
            let right = opCodes[min(end, opCodes.count)..<opCodes.count]
            let optimized = (window.count > 1) ? (optimizeWindow(window: Array(window))) : (nil)
            opCodes = Array(left) + (optimized ?? Array(window)) + right
            if optimized != nil {
                modified = true
            }
            i += 1
        }
        basicBlock.opCodes = opCodes
        
        return modified
    }
}

/**
 * Loading a variable by storing to same variable is a no-op: remove instructions.
 */
private struct RedundantLoadStoreOptimizer : PeepholeOptimizer {
    var windowSize: Int { return 2 }
    
    func optimizeWindow(window: Array<IR>) -> Array<IR>? {
        let first = window[0]
        let second = window[1]
        
        if case let .localFrameIR(localIR1) = first, case let .loadLocal(l1) = localIR1, case let .localFrameIR(localIR2) = second, case let .storeLocal(l2) = localIR2, l1.index == l2.index {
            return []
        }
        else {
            return nil
        }
    }
}

/**
 * Storing a variable and then loading the same variable can be replaced by dup + store.
 */
private struct RedundantLoadOptimizer : PeepholeOptimizer {
    var windowSize: Int { return 2 }
    
    func optimizeWindow(window: Array<IR>) -> Array<IR>? {
        let first = window[0]
        let second = window[1]
        
        if case let .localFrameIR(localIR1) = first, case let .storeLocal(l1) = localIR1, case let .localFrameIR(localIR2) = second, case let .loadLocal(l2) = localIR2, l1.index == l2.index {
            return [IR.dup, first]
        }
        else {
            return nil
        }
    }
    
}

/**
 * Removes PushUnit + Pop -combinations
 */
private struct RedundantPushUnitPopOptimizer: PeepholeOptimizer {
    var windowSize: Int { return 2 }
    
    func optimizeWindow(window: Array<IR>) -> Array<IR>? {
        let first = window[0]
        let second = window[1]
        
        if case .pushUnit = first, case .pop = second {
            return []
        }
        else {
            return nil
        }
    }
}


