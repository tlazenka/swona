/**
 * Intermediate representation that is quite close to executed opcodes,
 * but leaves things like addresses and labels still abstract.
 */

public enum IR: Equatable, CustomStringConvertible {
    case not
    case add
    case subtract
    case multiply
    case divide
    case equal
    case lessThan
    case lessThanOrEqual
    case concatString
    case pop
    case dup
    case call(argumentCount: Int)
    case restoreFrame
    case ret
    case pushUnit
    case push(value: Value)
    case loadGlobal(index: Int, name: String)
    case loadArgument(index: Int, name: String)
    case storeGlobal(index: Int, name: String)
    case localFrameIR(LocalFrameIR)
    
    public enum LocalFrameIR: Equatable, CustomStringConvertible {
        case loadLocal(index: Int, name: String)
        case storeLocal(index: Int, name: String)
        
        public var stackDelta: Int {
            switch self {
            case .loadLocal: return 1
            case .storeLocal: return -1
            }
        }
        
        public var description: String {
            switch self {
            case let .loadLocal(index, name): return  "LoadLocal \(index) ; \(name)"
            case let .storeLocal(index, name): return "StoreLocal \(index) ; \(name)"
            }
        }
        
        public var localFrameOffset: Int {
            switch self {
            case let .loadLocal(index, _):
                return index
            case let .storeLocal(index, _):
                return index
            }
        }
        
    }

    public var stackDelta: Int {
        switch self {
        case .not : return 0
        case .add : return -1
        case .subtract : return -1
        case .multiply : return -1
        case .divide : return -1
        case .equal : return -1
        case .lessThan : return -1
        case .lessThanOrEqual : return -1
        case .concatString : return -1
        case .pop : return -1
        case .dup : return 1
        case let .call(argumentCount): return -argumentCount
        case .restoreFrame : return 0
        case .ret : return -1
        case .pushUnit : return 1
        case .push: return 1
        case .loadGlobal: return 1
        case .loadArgument: return 1
        case .storeGlobal: return -1
        case let .localFrameIR(localFrameIR): return localFrameIR.stackDelta
        }
    }
    
    public var description: String {
        switch self {
        case .not: return "Not"
        case .add: return "Add"
        case .subtract: return "Subtract"
        case .multiply: return "Multiply"
        case .divide: return "Divide"
        case .equal: return "Equal"
        case .lessThan: return "LessThan"
        case .lessThanOrEqual: return "LessThanOrEqual"
        case .concatString: return "ConcatString"
        case .pop: return "Pop"
        case .dup: return "Dup"
        case .call(_): return "Call"
        case .restoreFrame: return "RestoreFrame"
        case .ret: return "Ret"
        case .pushUnit: return "PushUnit"
        case let .push(value): return "Push \(value.repr())"
        case let .loadGlobal(index, name): return "LoadGlobal \(index) ; \(name)"
        case let .loadArgument(index, name): return "LoadArgument \(index) ; \(name)"
        case let .storeGlobal(index, name): return "StoreGlobal \(index) ; \(name)"
        case let .localFrameIR(localFrameIR): return localFrameIR.description
        }
    }
    
}

/**
 * Builder for building IR-stream.
 */
public class BasicBlock: CustomStringConvertible, Hashable {
    public static func == (lhs: BasicBlock, rhs: BasicBlock) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
    
    public var opCodes = [IR]()
    
    var next: BlockEnd = BlockEnd.none
    
    public init() {
    }
    
    /** How executing this blocks affects the depth of the stack */
    public var stackDelta: Int {
        return opCodes.sumBy { $0.stackDelta } + next.stackDelta
    }
    
    public var maxLocalVariableOffset: Int {
        let p: [Int?] = opCodes.map {
            switch $0 {
            case let IR.localFrameIR(localFrameIR):
                return localFrameIR.localFrameOffset
            default:
                return nil
            }
        }
        return p.compactMap { $0 }.max() ?? -1
        
    }
    
    public indirect enum BlockEnd: CustomStringConvertible {
        case none
        case jump(basicBlock: BasicBlock)
        case branch(trueBlock: BasicBlock, falseBlock: BasicBlock)
        
        var stackDelta: Int {
            switch self {
            case .none:
                return 0
            case .jump:
                return 0
            case .branch:
                return -1
            }
        }
     
        public var description: String {
            switch self {
            case .none:
                return "None"
            case .jump:
                return "Jump"
            case .branch:
                return "Branch"
            }
        }
        
        public var blocks: [BasicBlock] {
            switch self {
            case .none:
                return []
            case let .jump(basicBlock):
                return [basicBlock]
            case let .branch(trueBlock, falseBlock):
                return [trueBlock, falseBlock]
            }
        }

    }
    
    /**
     * Adds a new opcode.
     */
    func plusAssign(op: IR) {
        opCodes += [op]
    }
    
    public static func +=(left: BasicBlock, right: IR) {
        left.plusAssign(op: right)
    }
    
    func endWithJumpTo(next: BasicBlock) {
        guard case .none = self.next else {
            fatalError()
        }
        self.next = BlockEnd.jump(basicBlock: next)
    }
    
    public func endWithBranch(trueBlock: BasicBlock, falseBlock: BasicBlock) {
        guard case .none = self.next else {
            fatalError()
        }
        self.next = BlockEnd.branch(trueBlock: trueBlock, falseBlock: falseBlock)
    }

    public var description: String {
        return ((opCodes.map { $0.description }) + [next.description]).joined(separator: "; ")
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }
}

/**
 * Internal error thrown when we detect the translator or some optimization
 * has left the IR stack use in invalid state.
 *
 * It's always a bug in compiler if this is thrown: never an error in user program.
 */
public struct InvalidStackUseException : Error {
    let message: String
    init(_ message: String) {
        self.message = message
    }
}

/**
 * Graph of basic blocks for a single function, method etc.
 */
public struct BasicBlockGraph {
    
    public init() {
    }
    
    public let start = BasicBlock()
    
    var end: BasicBlock {
        return allBlocksInArbitraryOrder().first {
            if case BasicBlock.BlockEnd.none = $0.next {
                return true
            }
            return false
            }!
    }
    
    func optimize() {
        for block in allBlocksInArbitraryOrder() {
            block.peepholeOptimize()
        }
    }
    
    /**
     * Verifies that stack usage of the graph is valid.
     *
     * Each instruction should have a static stack depth: whenever it is called,
     * it should affect the same stack location. Since the paths through basic
     * blocks are static, we can just verify that each basic block has a consistent
     * start depth no matter what path we reach it through.
     */
    public func buildStackDepthMap() throws -> Dictionary<BasicBlock, Int> {
        var startStackDepths = [start: 0]
        
        for block in allBlocks() {
            guard let startDepth = startStackDepths[block] else {
                fatalError("no depth assigned for \(block)")
            }
            let endDepth = startDepth + block.stackDelta
            
            for next in block.next.blocks {
                let nextDepth = startStackDepths[next]
                if (nextDepth == nil) {
                    startStackDepths[next] = endDepth
                }
                else if (nextDepth != endDepth) {
                    throw InvalidStackUseException("expected \(String(describing: nextDepth)), but got \(endDepth) for \(block) -> \(next)")
                }
            }
        }
        
        let endDepth = startStackDepths[end]! + end.stackDelta
        if (endDepth != 0) {
            throw InvalidStackUseException("invalid end depth for stack: \(endDepth)")
        }
        
        return startStackDepths
    }
    
    func localVariablesCount() -> Int {
        return allBlocksInArbitraryOrder().map { $0.maxLocalVariableOffset + 1 }.max() ?? 0
    }
    
    func allBlocks() -> OrderedSet<BasicBlock> {
        var blocks = allBlocksInArbitraryOrder()
        
        // move the ending block to be last
        guard let endBlock = Array(blocks.filter {
            if case BasicBlock.BlockEnd.none = $0.next {
                return true
            }
            return false
        }).singleOrNull() else {
            fatalError("no unique end block")
        }
        
        blocks.remove(endBlock)
        blocks.append(endBlock)
        return blocks
    }
    
    
    private func allBlocksInArbitraryOrder() -> OrderedSet<BasicBlock> {
        var blocks = OrderedSet<BasicBlock>()
        
        func gatherBlocks(block: BasicBlock) {
            if blocks.append(block) {
                for b in block.next.blocks {
                    gatherBlocks(block: b)
                }
            }
        }
        
        gatherBlocks(block: start)
        return blocks
    }
}


extension BasicBlockGraph {
    func translateToCode(argumentCount: Int) throws -> CodeSegment {
        return try OpCodeTranslator(code: self, argumentCount: argumentCount).translate()
    }
}

public class OpCodeTranslator {
    let code: BasicBlockGraph
    let argumentCount: Int
    
    let localCount: Int
    
    init(code: BasicBlockGraph, argumentCount: Int) {
        self.code = code
        self.argumentCount = argumentCount
        self.localCount = code.localVariablesCount()
    }
    
    func translate() throws -> CodeSegment {
        let blocks = code.allBlocks()
        
        let blockAddresses = calculateAddressesForBlocks(blocks: blocks)
        let stackDepths = try code.buildStackDepthMap()
        
        var ops = Array<OpCode>()
        for block in blocks {
            ops += try translateBlock(block: block, blockAddresses: blockAddresses, stackDepths: stackDepths)
        }
        
        return CodeSegment(opCodes: ops)
    }
    
    private func translateBlock(block: BasicBlock, blockAddresses: Dictionary<BasicBlock, Int>, stackDepths: Dictionary<BasicBlock, Int>) throws -> Array<OpCode> {
        var ops1 = Array<OpCode>()
        let baseStackOffset = argumentCount + localCount // there's a +1 term from return address, but a cancelling -1 term from addressing convention
        var sp = baseStackOffset + stackDepths[block]!
        
        for op in block.opCodes {
            if (sp < baseStackOffset) {
                throw InvalidStackUseException("stack underflow")
            }
            
            ops1 += [translate(ir: op, sp: sp)]
            sp += op.stackDelta
        }
        
        let next = block.next
        switch next {
        case .none:
            break
        case let .jump(basicBlock):
            ops1 += [OpCode.jump(address: blockAddresses[basicBlock]!)]
        case let .branch(trueBlock, falseBlock):
            ops1 += [OpCode.jumpIfFalse(sp: sp, address: blockAddresses[falseBlock]!)]
            ops1 += [OpCode.jump(address: blockAddresses[trueBlock]!)]
        }
        
        return ops1
    }
    
    private func calculateAddressesForBlocks(blocks: OrderedSet<BasicBlock>) -> Dictionary<BasicBlock, Int> {
        var blockAddresses = Dictionary<BasicBlock, Int>()
        
        var nextFreeAddress = 0
        for block in blocks {
            blockAddresses[block] = nextFreeAddress
            nextFreeAddress += translatedSize(block: block)
        }
        
        return blockAddresses
    }
    
    private func translatedSize(block: BasicBlock) -> Int {
        let c: Int
        switch block.next {
        case .none:
            c = 0
        case .jump:
            c = 1
        case .branch:
            c = 2
        }
        return block.opCodes.count + c
    }
    
    func translate(ir: IR, sp: Int) -> OpCode {
        switch ir {
        case IR.not: return OpCode.not(target: sp, source: sp)
        case IR.add: return OpCode.binary(.add(target: sp - 1, lhs: sp - 1, rhs: sp))
        case IR.subtract: return OpCode.binary(.subtract(target: sp - 1, lhs: sp - 1, rhs: sp))
        case IR.multiply: return OpCode.binary(.multiply(target: sp - 1, lhs: sp - 1, rhs: sp))
        case IR.divide: return OpCode.binary(.divide(target: sp - 1, lhs: sp - 1, rhs: sp))
        case IR.equal: return OpCode.binary(.equal(target: sp - 1, lhs: sp - 1, rhs: sp))
        case IR.lessThan: return OpCode.binary(.lessThan(target: sp - 1, lhs: sp - 1, rhs: sp))
        case IR.lessThanOrEqual: return OpCode.binary(.lessThanOrEqual(target: sp - 1, lhs: sp - 1, rhs: sp))
        case IR.concatString: return OpCode.binary(.concatString(target: sp - 1, lhs: sp - 1, rhs: sp))
        case IR.pop: return OpCode.nop
        case IR.dup: return OpCode.copy(target: sp + 1, source: sp, description: "dup")
        case let IR.call(argumentCount): return OpCode.call(offset: sp, argumentCount: argumentCount)
        case IR.restoreFrame: return OpCode.restoreFrame(sp: sp)
        case IR.ret: return OpCode.ret(valuePointer: sp, returnAddressPointer: returnAddressOffset())
        case IR.pushUnit: return OpCode.loadConstant(target: sp + 1, value: Value.unit)
        case let IR.push(value): return OpCode.loadConstant(target: sp + 1, value: value)
        case let IR.loadGlobal(index, name): return OpCode.loadGlobal(target: sp + 1, sourceGlobal: index, name: name)
        case let IR.localFrameIR(localFrameIR):
            switch localFrameIR {
            case let .loadLocal(index, name):
                return OpCode.copy(target: sp + 1, source: localOffset(index: index), description: "load local \(name)")
            case let .storeLocal(index, name):
                return OpCode.copy(target: localOffset(index: index), source: sp, description: "store local \(name)")
            }
        case let IR.loadArgument(index, name): return OpCode.copy(target: sp + 1, source: argumentOffset(index: index), description: "load arg \(name)")
        case let IR.storeGlobal(index, name): return OpCode.storeGlobal(targetGlobal: index, source: sp, name: name)
        }
    }
    
    private func argumentOffset(index: Int) -> Int {
        return index
    }
    
    private func returnAddressOffset() -> Int {
        return argumentCount
    }
    
    private func localOffset(index: Int) -> Int {
        return argumentCount + 1 + index
    }
}

/**
 * Creates a callable function from given expression.
 */
class FunctionTranslator {
    let env: GlobalStaticEnvironment
    
    init(env: GlobalStaticEnvironment) {
        self.env = env
    }
    
    func translateFunction(func: FunctionDefinition, optimize: Bool) throws -> (Type.Function, CodeSegment) {
        var typedExp = try `func`.body.typeCheck(env: env.newScope(args: `func`.args))
        if (optimize) {
            typedExp = typedExp.optimize()
        }
        
        if let returnType = `func`.returnType {
            try typedExp.expectAssignableTo(expectedType: returnType, location: `func`.body.location)
        }
        
        let basicBlocks = typedExp.translateToIR()
        
        if (optimize) {
            basicBlocks.optimize()
        }
        
        return (Type.Function.function(argumentTypes: `func`.args.map { $0.1 }, returnType: typedExp.type), try basicBlocks.translateToCode(argumentCount: `func`.args.count))
    }
}


extension TypedExpression {
    func translateToIR() -> BasicBlockGraph {
        let translator = Translator()
        translator.emitCode(typedExpression: self)
        translator.basicBlocks.end += IR.ret
        return translator.basicBlocks
    }
}

public class Translator {
    
    let basicBlocks = BasicBlockGraph()
    private var currentBlock: BasicBlock
    
    init() {
        currentBlock = basicBlocks.start
    }
    
    func emitCode(typedExpression: TypedExpression) {
        switch typedExpression {
        case let .ref(bindingReference):
            emitLoad(binding: bindingReference.binding)
        case let .lit(value, _):
            currentBlock += IR.push(value: value)
        case let .not(exp):
            emitCode(typedExpression: exp)
            currentBlock += IR.not
        case let .binary(binary):
            emitCode(binary: binary)
        case let .call(`func`, args, _):
            args.forEach { emitCode(typedExpression: $0) }
            emitCode(typedExpression: `func`)
            currentBlock += IR.call(argumentCount: args.count)
            currentBlock += IR.restoreFrame
        case let .expressionList(expressions, _):
            currentBlock += IR.pushUnit
            expressions.forEach { expression in
                currentBlock += IR.pop
                emitCode(typedExpression: expression)
            }
        case let .assign(variable, expression):
            emitCode(typedExpression: expression)
            emitStore(binding: variable.binding)
            currentBlock += IR.pushUnit
        case let .var(variable, expression):
            emitCode(typedExpression: expression)
            emitStore(binding: variable.binding)
            currentBlock += IR.pushUnit
        case let .if(condition, consequent, alternative, _):
            emitCode(typedExpression: condition)
            
            let afterBlock = BasicBlock()
            
            
            if let alternative = alternative {
                let trueBlock = BasicBlock()
                let falseBlock = BasicBlock()
                
                currentBlock.endWithBranch(trueBlock: trueBlock, falseBlock: falseBlock)
                
                currentBlock = trueBlock
                emitCode(typedExpression: consequent)
                currentBlock.endWithJumpTo(next: afterBlock)
                
                currentBlock = falseBlock
                emitCode(typedExpression: alternative)
                
                currentBlock.endWithJumpTo(next: afterBlock)
                
            }
            else {
                let trueBlock = BasicBlock()
                
                currentBlock.endWithBranch(trueBlock: trueBlock, falseBlock: afterBlock)
                
                currentBlock = trueBlock
                emitCode(typedExpression: consequent)
                currentBlock += IR.pop
                currentBlock.endWithJumpTo(next: afterBlock)
                
                afterBlock += IR.pushUnit
            }
            
            currentBlock = afterBlock
        case let .while(condition, body):
            
            let loopHead = BasicBlock()
            let loopBody = BasicBlock()
            let afterLoop = BasicBlock()
            
            currentBlock.endWithJumpTo(next: loopHead)
            
            currentBlock = loopHead
            emitCode(typedExpression: condition)
            currentBlock.endWithBranch(trueBlock: loopBody, falseBlock: afterLoop)
            
            currentBlock = loopBody
            emitCode(typedExpression: body)
            currentBlock += IR.pop
            currentBlock.endWithJumpTo(next: loopHead)
            
            currentBlock = afterLoop
            currentBlock += IR.pushUnit
        }
    }
    
    func emitCode(binary: TypedExpression.Binary) {
        emitCode(typedExpression: binary.lhs)
        emitCode(typedExpression: binary.rhs)
        switch binary {
        case .plus:
            currentBlock += IR.add
        case .minus:
            currentBlock += IR.subtract
        case .multiply:
            currentBlock += IR.multiply
        case .divide:
            currentBlock += IR.divide
        case .concatString:
            currentBlock += IR.concatString
        case let .relational(op, _, _):
            emitCode(relationalOp: op)
            
        }
    }
    
    func emitCode(relationalOp: RelationalOp) {
        switch relationalOp {
        case .equals:
            currentBlock += .equal
        case .notEquals:
            currentBlock += IR.equal
            currentBlock += IR.not
        case .lessThan:
            currentBlock += IR.lessThan
        case .lessThanOrEqual:
            currentBlock += IR.lessThanOrEqual
        case .greaterThan:
            currentBlock += IR.lessThanOrEqual
            currentBlock += IR.not
        case .greaterThanOrEqual:
            currentBlock += IR.lessThan
            currentBlock += IR.not
        }
    }
    
    func emitStore(binding: Binding) {
        switch binding {
        case let .local(name, _, index, _):
            currentBlock += .localFrameIR(.storeLocal(index: index, name: name))
        case let .global(name, _, index, _):
            currentBlock += .storeGlobal(index: index, name: name)
        case .argument:
            fatalError("can't store into arguments")
        }
    }
    
    func emitLoad(binding: Binding) {
        switch binding {
        case let .local(name, _, index, _):
            currentBlock += .localFrameIR(.loadLocal(index: index, name: name))
        case let .global(name, _, index, _):
            currentBlock += .loadGlobal(index: index, name: name)
        case let .argument(name, _, index):
            currentBlock += .loadArgument(index: index, name: name)
        }
    }
}
