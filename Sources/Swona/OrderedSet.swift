/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors

 The below code was modified from the original.
 */

// See https://github.com/apple/swift-package-manager/blob/1444b46dbc13477f027959e4d59e520747fc8382/swift-tools-support-core/Sources/TSCBasic/OrderedSet.swift

/// An ordered set is an ordered collection of instances of `Element` in which
/// uniqueness of the objects is guaranteed.
public struct OrderedSet<E: Hashable>: Equatable, Collection {
    public typealias Element = E

    var array: [Element]
    var elementToIndex: [Element: Int]

    /// Creates an empty ordered set.
    public init() {
        array = []
        elementToIndex = [:]
    }

    /// Creates an ordered set with the contents of `array`.
    ///
    /// If an element occurs more than once in `element`, only the first one
    /// will be included.
    public init(_ array: [Element]) {
        self.init()
        for element in array {
            append(element)
        }
    }

    /// Returns the contents of the set as an array.
    public var contents: [Element] { array }

    /// Adds an element to the ordered set.
    ///
    /// If it already contains the element, then the set is unchanged.
    ///
    /// - returns: True if the item was inserted.
    @discardableResult
    public mutating func append(_ newElement: Element) -> Bool {
        guard elementToIndex[newElement] == nil else {
            return false
        }

        array.append(newElement)
        elementToIndex[newElement] = array.count - 1

        return true
    }

    /// Remove an element.
    @discardableResult public mutating func remove(_ element: Element) -> Bool {
        guard let index = elementToIndex[element] else {
            return false
        }
        array.remove(at: index)
        elementToIndex[element] = nil
        for (e, i) in elementToIndex {
            guard i >= index else {
                continue
            }
            elementToIndex[e] = i - 1
        }

        return true
    }
}

extension OrderedSet: ExpressibleByArrayLiteral {
    /// Create an instance initialized with `elements`.
    ///
    /// If an element occurs more than once in `element`, only the first one
    /// will be included.
    public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
}

extension OrderedSet: RandomAccessCollection {
    public var startIndex: Int { contents.startIndex }
    public var endIndex: Int { contents.endIndex }
    public subscript(index: Int) -> Element {
        contents[index]
    }
}

public func == <T>(lhs: OrderedSet<T>, rhs: OrderedSet<T>) -> Bool {
    lhs.contents == rhs.contents
}

extension OrderedSet: Hashable where Element: Hashable {}
