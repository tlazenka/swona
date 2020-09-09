/**
 * Statically known information about a variable.
 *
 * Includes name and type for all variables, in addition to the knowledge
 * whether the variable is global or local. Local variables are accessed
 * directly with their index in frame, whereas global variables are accessed
 * in global environment by name.
 */
public enum Binding: CustomStringConvertible {
    case global(name: String, type: Type, index: Int, mutable: Bool)
    case local(name: String, type: Type, index: Int, mutable: Bool)
    case argument(name: String, type: Type, index: Int)

    public var index: Int {
        switch self {
        case let .global(_, _, index, _),
             let .local(_, _, index, _),
             let .argument(_, _, index):
            return index
        }
    }

    public var mutable: Bool {
        switch self {
        case let .global(_, _, _, mutable),
             let .local(_, _, _, mutable):
            return mutable
        case .argument:
            return false
        }
    }

    public var description: String {
        switch self {
        case let .global(name, _, index, _):
            return "[Global \(index) (\(name))]"
        case let .local(name, _, index, _):
            return "[Local \(index) (\(name))]"
        case let .argument(name, _, index):
            return "[Argument \(index) (\(name))]"
        }
    }

    public var name: String {
        switch self {
        case let .global(name, _, _, _),
             let .local(name, _, _, _),
             let .argument(name, _, _):
            return name
        }
    }

    public var type: Type {
        switch self {
        case let .argument(_, type, _),
             let .global(_, type, _, _),
             let .local(_, type, _, _):
            return type
        }
    }
}

public class BindingReference: Hashable, CustomStringConvertible {
    public static func == (lhs: BindingReference, rhs: BindingReference) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }

    let binding: Binding

    init(binding: Binding) {
        self.binding = binding
    }

    public var type: Type { binding.type }
    public var name: String { binding.name }
    public var description: String { binding.description }
    public var mutable: Bool { binding.mutable }
}

/**
 * Exception thrown when variable is rebound.
 *
 * This should never be thrown since type-checking should find all rebindings.
 */
struct VariableAlreadyBoundException: Error {
    let message: String

    init(name: String) {
        message = "variable already bound: \(name)"
    }
}

/**
 * Mapping from variable names to [Binding]s.
 */
public protocol StaticEnvironment: AnyObject {
    var parent: StaticEnvironment? { get }

    var bindings: [String: BindingReference] { get set }

    /**
     * Create a new binding to be installed in this environment.
     */
    func newBinding(name: String, type: Type, mutable: Bool) -> BindingReference

    /**
     * Returns a new child scope for current environment.
     *
     * Child environment inherits all bindings of the parent environment,
     * but may rebind variables. The variables defined inside the nested
     * environment are not visible outside.
     */
    func newScope() -> StaticEnvironment
}

extension StaticEnvironment {
    /**
     * Returns the binding of given variable.
     */
    subscript(name: String) -> BindingReference? {
        bindings[name] ?? parent?[name]
    }

    /**
     * Create a new binding for variable having given [name] and [type].
     * For global environment, this creates a new entry in the global mappings.
     * For local environments, this allocates a slot in current environment frame.
     *
     * @throws VariableAlreadyBoundException if variable is already bound in this scope
     */
    @discardableResult public func bind(name: String, type: Type, mutable: Bool = true) throws -> BindingReference {
        if bindings.keys.contains(name) {
            throw VariableAlreadyBoundException(name: name)
        }

        let binding = newBinding(name: name, type: type, mutable: mutable)
        bindings[name] = binding
        return binding
    }

    /**
     * Removes this binding from global environment, allowing it to be reused.
     */
    func unbind(name: String) {
        bindings.removeValue(forKey: name)
    }

    func bindingNames() -> Set<String> {
        Set(bindings.keys)
    }
}

/**
 * Global environment.
 */
public class GlobalStaticEnvironment: StaticEnvironment {
    private var bindingIndexSequence = 0

    public var parent: StaticEnvironment? { nil }

    public var bindings: [String: BindingReference] = [:]

    public init() {}

    public func newBinding(name: String, type: Type, mutable: Bool) -> BindingReference {
        let result = BindingReference(binding: Binding.global(name: name, type: type, index: bindingIndexSequence, mutable: mutable))
        bindingIndexSequence += 1
        return result
    }

    public func newScope() -> StaticEnvironment {
        LocalFrameEnvironment(parent: self)
    }

    public func newScope(args: [(String, Type)]) -> StaticEnvironment {
        LocalFrameEnvironment(parent: self, args: args)
    }
}

/**
 * Top level local environment. When there are multiple scopes that can share
 * the same frame, the top level scope will be [LocalFrameEnvironment] and the
 * child scopes will be [LocalFrameChildScope]s. This means that each child scooe
 * may shadow bindings created above, but they will still get unique indices.
 */
class LocalFrameEnvironment: StaticEnvironment {
    var parent: StaticEnvironment?

    var bindings: [String: BindingReference] = [:]

    private var bindingIndexSequence = 0

    init(parent: StaticEnvironment) {
        self.parent = parent
    }

    init(parent: StaticEnvironment, args: [(String, Type)]) {
        self.parent = parent
        args.enumerated().forEach { index, pair in
            let (name, type) = pair
            bindings[name] = BindingReference(binding: Binding.argument(name: name, type: type, index: index))
        }
    }

    func newBinding(name: String, type: Type, mutable: Bool) -> BindingReference {
        let result = BindingReference(binding: Binding.local(name: name, type: type, index: bindingIndexSequence, mutable: mutable))
        bindingIndexSequence += 1
        return result
    }

    func newScope() -> StaticEnvironment {
        LocalFrameChildScope(parent: self, frame: self)
    }
}

/**
 * Environment for child scopes which share frame with their parent, but still provide
 * new scope for names.
 */
class LocalFrameChildScope: StaticEnvironment {
    var parent: StaticEnvironment?

    var bindings: [String: BindingReference] = [:]

    var frame: LocalFrameEnvironment

    init(parent: StaticEnvironment, frame: LocalFrameEnvironment) {
        self.parent = parent
        self.frame = frame
    }

    func newBinding(name: String, type: Type, mutable: Bool) -> BindingReference {
        frame.newBinding(name: name, type: type, mutable: mutable)
    }

    func newScope() -> StaticEnvironment {
        LocalFrameChildScope(parent: self, frame: frame)
    }
}
