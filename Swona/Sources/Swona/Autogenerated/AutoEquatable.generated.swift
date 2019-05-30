// Generated using Sourcery 0.16.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable file_length
fileprivate func compareOptionals<T>(lhs: T?, rhs: T?, compare: (_ lhs: T, _ rhs: T) -> Bool) -> Bool {
    switch (lhs, rhs) {
    case let (lValue?, rValue?):
        return compare(lValue, rValue)
    case (nil, nil):
        return true
    default:
        return false
    }
}

fileprivate func compareArrays<T>(lhs: [T], rhs: [T], compare: (_ lhs: T, _ rhs: T) -> Bool) -> Bool {
    guard lhs.count == rhs.count else { return false }
    for (idx, lhsItem) in lhs.enumerated() {
        guard compare(lhsItem, rhs[idx]) else { return false }
    }

    return true
}


// MARK: - AutoEquatable for classes, protocols, structs

// MARK: - AutoEquatable for Enums
// MARK: - Binding AutoEquatable
extension Binding: Equatable {}
public func == (lhs: Binding, rhs: Binding) -> Bool {
    switch (lhs, rhs) {
    case (.global(let lhs), .global(let rhs)):
        if lhs.name != rhs.name { return false }
        if lhs.type != rhs.type { return false }
        if lhs.index != rhs.index { return false }
        if lhs.mutable != rhs.mutable { return false }
        return true
    case (.local(let lhs), .local(let rhs)):
        if lhs.name != rhs.name { return false }
        if lhs.type != rhs.type { return false }
        if lhs.index != rhs.index { return false }
        if lhs.mutable != rhs.mutable { return false }
        return true
    case (.argument(let lhs), .argument(let rhs)):
        if lhs.name != rhs.name { return false }
        if lhs.type != rhs.type { return false }
        if lhs.index != rhs.index { return false }
        return true
    default: return false
    }
}
// MARK: - Expression AutoEquatable
extension Expression: Equatable {}
public func == (lhs: Expression, rhs: Expression) -> Bool {
    switch (lhs, rhs) {
    case (.ref(let lhs), .ref(let rhs)):
        if lhs.name != rhs.name { return false }
        if lhs.location != rhs.location { return false }
        return true
    case (.lit(let lhs), .lit(let rhs)):
        if lhs.value != rhs.value { return false }
        if lhs.location != rhs.location { return false }
        return true
    case (.not(let lhs), .not(let rhs)):
        if lhs.exp != rhs.exp { return false }
        if lhs.location != rhs.location { return false }
        return true
    case (.call(let lhs), .call(let rhs)):
        if lhs.func != rhs.func { return false }
        if lhs.args != rhs.args { return false }
        return true
    case (.binary(let lhs), .binary(let rhs)):
        return lhs == rhs
    case (.assign(let lhs), .assign(let rhs)):
        if lhs.variable != rhs.variable { return false }
        if lhs.expression != rhs.expression { return false }
        if lhs.location != rhs.location { return false }
        return true
    case (.`var`(let lhs), .`var`(let rhs)):
        if lhs.variable != rhs.variable { return false }
        if lhs.expression != rhs.expression { return false }
        if lhs.mutable != rhs.mutable { return false }
        if lhs.location != rhs.location { return false }
        return true
    case (.`if`(let lhs), .`if`(let rhs)):
        if lhs.condition != rhs.condition { return false }
        if lhs.consequent != rhs.consequent { return false }
        if lhs.alternative != rhs.alternative { return false }
        if lhs.location != rhs.location { return false }
        return true
    case (.`while`(let lhs), .`while`(let rhs)):
        if lhs.condition != rhs.condition { return false }
        if lhs.body != rhs.body { return false }
        if lhs.location != rhs.location { return false }
        return true
    case (.`expressionList`(let lhs), .`expressionList`(let rhs)):
        if lhs.expressions != rhs.expressions { return false }
        if lhs.location != rhs.location { return false }
        return true
    default: return false
    }
}
// MARK: - Expression.Binary AutoEquatable
extension Expression.Binary: Equatable {}
public func == (lhs: Expression.Binary, rhs: Expression.Binary) -> Bool {
    switch (lhs, rhs) {
    case (.plus(let lhs), .plus(let rhs)):
        if lhs.lhs != rhs.lhs { return false }
        if lhs.rhs != rhs.rhs { return false }
        if lhs.location != rhs.location { return false }
        return true
    case (.minus(let lhs), .minus(let rhs)):
        if lhs.lhs != rhs.lhs { return false }
        if lhs.rhs != rhs.rhs { return false }
        if lhs.location != rhs.location { return false }
        return true
    case (.multiply(let lhs), .multiply(let rhs)):
        if lhs.lhs != rhs.lhs { return false }
        if lhs.rhs != rhs.rhs { return false }
        if lhs.location != rhs.location { return false }
        return true
    case (.divide(let lhs), .divide(let rhs)):
        if lhs.lhs != rhs.lhs { return false }
        if lhs.rhs != rhs.rhs { return false }
        if lhs.location != rhs.location { return false }
        return true
    case (.and(let lhs), .and(let rhs)):
        if lhs.lhs != rhs.lhs { return false }
        if lhs.rhs != rhs.rhs { return false }
        if lhs.location != rhs.location { return false }
        return true
    case (.or(let lhs), .or(let rhs)):
        if lhs.lhs != rhs.lhs { return false }
        if lhs.rhs != rhs.rhs { return false }
        if lhs.location != rhs.location { return false }
        return true
    case (.relational(let lhs), .relational(let rhs)):
        if lhs.op != rhs.op { return false }
        if lhs.lhs != rhs.lhs { return false }
        if lhs.rhs != rhs.rhs { return false }
        if lhs.location != rhs.location { return false }
        return true
    default: return false
    }
}
// MARK: - IR AutoEquatable
extension IR: Equatable {}
public func == (lhs: IR, rhs: IR) -> Bool {
    switch (lhs, rhs) {
    case (.not, .not):
        return true
    case (.add, .add):
        return true
    case (.subtract, .subtract):
        return true
    case (.multiply, .multiply):
        return true
    case (.divide, .divide):
        return true
    case (.equal, .equal):
        return true
    case (.lessThan, .lessThan):
        return true
    case (.lessThanOrEqual, .lessThanOrEqual):
        return true
    case (.concatString, .concatString):
        return true
    case (.pop, .pop):
        return true
    case (.dup, .dup):
        return true
    case (.call(let lhs), .call(let rhs)):
        return lhs == rhs
    case (.restoreFrame, .restoreFrame):
        return true
    case (.ret, .ret):
        return true
    case (.pushUnit, .pushUnit):
        return true
    case (.push(let lhs), .push(let rhs)):
        return lhs == rhs
    case (.loadGlobal(let lhs), .loadGlobal(let rhs)):
        if lhs.index != rhs.index { return false }
        if lhs.name != rhs.name { return false }
        return true
    case (.loadArgument(let lhs), .loadArgument(let rhs)):
        if lhs.index != rhs.index { return false }
        if lhs.name != rhs.name { return false }
        return true
    case (.storeGlobal(let lhs), .storeGlobal(let rhs)):
        if lhs.index != rhs.index { return false }
        if lhs.name != rhs.name { return false }
        return true
    case (.localFrameIR(let lhs), .localFrameIR(let rhs)):
        return lhs == rhs
    default: return false
    }
}
// MARK: - IR.LocalFrameIR AutoEquatable
extension IR.LocalFrameIR: Equatable {}
public func == (lhs: IR.LocalFrameIR, rhs: IR.LocalFrameIR) -> Bool {
    switch (lhs, rhs) {
    case (.loadLocal(let lhs), .loadLocal(let rhs)):
        if lhs.index != rhs.index { return false }
        if lhs.name != rhs.name { return false }
        return true
    case (.storeLocal(let lhs), .storeLocal(let rhs)):
        if lhs.index != rhs.index { return false }
        if lhs.name != rhs.name { return false }
        return true
    default: return false
    }
}
// MARK: - OpCode AutoEquatable
extension OpCode: Equatable {}
public func == (lhs: OpCode, rhs: OpCode) -> Bool {
    switch (lhs, rhs) {
    case (.not(let lhs), .not(let rhs)):
        if lhs.target != rhs.target { return false }
        if lhs.source != rhs.source { return false }
        return true
    case (.binary(let lhs), .binary(let rhs)):
        return lhs == rhs
    case (.nop, .nop):
        return true
    case (.call(let lhs), .call(let rhs)):
        if lhs.offset != rhs.offset { return false }
        if lhs.argumentCount != rhs.argumentCount { return false }
        return true
    case (.restoreFrame(let lhs), .restoreFrame(let rhs)):
        return lhs == rhs
    case (.ret(let lhs), .ret(let rhs)):
        if lhs.valuePointer != rhs.valuePointer { return false }
        if lhs.returnAddressPointer != rhs.returnAddressPointer { return false }
        return true
    case (.copy(let lhs), .copy(let rhs)):
        if lhs.target != rhs.target { return false }
        if lhs.source != rhs.source { return false }
        if lhs.description != rhs.description { return false }
        return true
    case (.loadConstant(let lhs), .loadConstant(let rhs)):
        if lhs.target != rhs.target { return false }
        if lhs.value != rhs.value { return false }
        return true
    case (.loadGlobal(let lhs), .loadGlobal(let rhs)):
        if lhs.target != rhs.target { return false }
        if lhs.sourceGlobal != rhs.sourceGlobal { return false }
        if lhs.name != rhs.name { return false }
        return true
    case (.storeGlobal(let lhs), .storeGlobal(let rhs)):
        if lhs.targetGlobal != rhs.targetGlobal { return false }
        if lhs.source != rhs.source { return false }
        if lhs.name != rhs.name { return false }
        return true
    case (.jump(let lhs), .jump(let rhs)):
        return lhs == rhs
    case (.jumpIfFalse(let lhs), .jumpIfFalse(let rhs)):
        if lhs.sp != rhs.sp { return false }
        if lhs.address != rhs.address { return false }
        return true
    default: return false
    }
}
// MARK: - OpCode.Binary AutoEquatable
extension OpCode.Binary: Equatable {}
public func == (lhs: OpCode.Binary, rhs: OpCode.Binary) -> Bool {
    switch (lhs, rhs) {
    case (.add(let lhs), .add(let rhs)):
        if lhs.target != rhs.target { return false }
        if lhs.lhs != rhs.lhs { return false }
        if lhs.rhs != rhs.rhs { return false }
        return true
    case (.subtract(let lhs), .subtract(let rhs)):
        if lhs.target != rhs.target { return false }
        if lhs.lhs != rhs.lhs { return false }
        if lhs.rhs != rhs.rhs { return false }
        return true
    case (.multiply(let lhs), .multiply(let rhs)):
        if lhs.target != rhs.target { return false }
        if lhs.lhs != rhs.lhs { return false }
        if lhs.rhs != rhs.rhs { return false }
        return true
    case (.divide(let lhs), .divide(let rhs)):
        if lhs.target != rhs.target { return false }
        if lhs.lhs != rhs.lhs { return false }
        if lhs.rhs != rhs.rhs { return false }
        return true
    case (.equal(let lhs), .equal(let rhs)):
        if lhs.target != rhs.target { return false }
        if lhs.lhs != rhs.lhs { return false }
        if lhs.rhs != rhs.rhs { return false }
        return true
    case (.lessThan(let lhs), .lessThan(let rhs)):
        if lhs.target != rhs.target { return false }
        if lhs.lhs != rhs.lhs { return false }
        if lhs.rhs != rhs.rhs { return false }
        return true
    case (.lessThanOrEqual(let lhs), .lessThanOrEqual(let rhs)):
        if lhs.target != rhs.target { return false }
        if lhs.lhs != rhs.lhs { return false }
        if lhs.rhs != rhs.rhs { return false }
        return true
    case (.concatString(let lhs), .concatString(let rhs)):
        if lhs.target != rhs.target { return false }
        if lhs.lhs != rhs.lhs { return false }
        if lhs.rhs != rhs.rhs { return false }
        return true
    default: return false
    }
}
// MARK: - RelationalOp AutoEquatable
extension RelationalOp: Equatable {}
public func == (lhs: RelationalOp, rhs: RelationalOp) -> Bool {
    switch (lhs, rhs) {
    case (.equals, .equals):
        return true
    case (.notEquals, .notEquals):
        return true
    case (.lessThan, .lessThan):
        return true
    case (.lessThanOrEqual, .lessThanOrEqual):
        return true
    case (.greaterThan, .greaterThan):
        return true
    case (.greaterThanOrEqual, .greaterThanOrEqual):
        return true
    default: return false
    }
}
// MARK: - Token AutoEquatable
extension Token: Equatable {}
public func == (lhs: Token, rhs: Token) -> Bool {
    switch (lhs, rhs) {
    case (.identifier(let lhs), .identifier(let rhs)):
        return lhs == rhs
    case (.literal(let lhs), .literal(let rhs)):
        return lhs == rhs
    case (.keyword(let lhs), .keyword(let rhs)):
        return lhs == rhs
    case (.`operator`(let lhs), .`operator`(let rhs)):
        return lhs == rhs
    case (.punctuation(let lhs), .punctuation(let rhs)):
        return lhs == rhs
    default: return false
    }
}
// MARK: - Token.Keyword AutoEquatable
extension Token.Keyword: Equatable {}
public func == (lhs: Token.Keyword, rhs: Token.Keyword) -> Bool {
    switch (lhs, rhs) {
    case (.`else`, .`else`):
        return true
    case (.fun, .fun):
        return true
    case (.`if`, .`if`):
        return true
    case (.`var`, .`var`):
        return true
    case (.val, .val):
        return true
    case (.`while`, .`while`):
        return true
    default: return false
    }
}
// MARK: - Token.Operator AutoEquatable
extension Token.Operator: Equatable {}
public func == (lhs: Token.Operator, rhs: Token.Operator) -> Bool {
    switch (lhs, rhs) {
    case (.plus, .plus):
        return true
    case (.minus, .minus):
        return true
    case (.multiply, .multiply):
        return true
    case (.divide, .divide):
        return true
    case (.equalEqual, .equalEqual):
        return true
    case (.notEqual, .notEqual):
        return true
    case (.not, .not):
        return true
    case (.lessThan, .lessThan):
        return true
    case (.greaterThan, .greaterThan):
        return true
    case (.lessThanOrEqual, .lessThanOrEqual):
        return true
    case (.greaterThanOrEqual, .greaterThanOrEqual):
        return true
    case (.and, .and):
        return true
    case (.or, .or):
        return true
    default: return false
    }
}
// MARK: - Token.Punctuation AutoEquatable
extension Token.Punctuation: Equatable {}
public func == (lhs: Token.Punctuation, rhs: Token.Punctuation) -> Bool {
    switch (lhs, rhs) {
    case (.leftParen, .leftParen):
        return true
    case (.rightParen, .rightParen):
        return true
    case (.leftBrace, .leftBrace):
        return true
    case (.rightBrace, .rightBrace):
        return true
    case (.equal, .equal):
        return true
    case (.colon, .colon):
        return true
    case (.semicolon, .semicolon):
        return true
    case (.comma, .comma):
        return true
    default: return false
    }
}
// MARK: - Type AutoEquatable
extension Type: Equatable {}
public func == (lhs: Type, rhs: Type) -> Bool {
    switch (lhs, rhs) {
    case (.string, .string):
        return true
    case (.int, .int):
        return true
    case (.boolean, .boolean):
        return true
    case (.unit, .unit):
        return true
    case (.function(let lhs), .function(let rhs)):
        return lhs == rhs
    case (.array(let lhs), .array(let rhs)):
        return lhs == rhs
    default: return false
    }
}
// MARK: - Type.Function AutoEquatable
extension Type.Function: Equatable {}
public func == (lhs: Type.Function, rhs: Type.Function) -> Bool {
    switch (lhs, rhs) {
    case (.function(let lhs), .function(let rhs)):
        if lhs.argumentTypes != rhs.argumentTypes { return false }
        if lhs.returnType != rhs.returnType { return false }
        return true
    }
}
// MARK: - Value AutoEquatable
extension Value: Equatable {}
public func == (lhs: Value, rhs: Value) -> Bool {
    switch (lhs, rhs) {
    case (.unit, .unit):
        return true
    case (.string(let lhs), .string(let rhs)):
        return lhs == rhs
    case (.bool(let lhs), .bool(let rhs)):
        return lhs == rhs
    case (.integer(let lhs), .integer(let rhs)):
        return lhs == rhs
    case (.function(let lhs), .function(let rhs)):
        return lhs == rhs
    case (.array(let lhs), .array(let rhs)):
        if lhs.elements != rhs.elements { return false }
        if lhs.elementType != rhs.elementType { return false }
        return true
    case (.pointer(let lhs), .pointer(let rhs)):
        if lhs.value != rhs.value { return false }
        if lhs.1 != rhs.1 { return false }
        return true
    default: return false
    }
}
// MARK: - Value.Function AutoEquatable
extension Value.Function: Equatable {}
public func == (lhs: Value.Function, rhs: Value.Function) -> Bool {
    switch (lhs, rhs) {
    case (.compound(let lhs), .compound(let rhs)):
        if lhs.address != rhs.address { return false }
        if lhs.codeSize != rhs.codeSize { return false }
        if lhs.name != rhs.name { return false }
        if lhs.signature != rhs.signature { return false }
        return true
    case (.native(let lhs), .native(let rhs)):
        if lhs.func != rhs.func { return false }
        if lhs.name != rhs.name { return false }
        if lhs.signature != rhs.signature { return false }
        return true
    default: return false
    }
}
