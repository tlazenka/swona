extension String {
    // Modified from Kotlin (Apache License, Version 2.0). See LICENSE-THIRD-PARTY in this repo
    public func lines() -> Array<Substring> {
        return self.split(separator: "\n", omittingEmptySubsequences: false)
    }
    
    // Modified from Kotlin (Apache License, Version 2.0). See LICENSE-THIRD-PARTY in this repo
    public func substring(startOffset: Int, endOffset: Int) -> String {
        let substringStartIndex = self.index(self.startIndex, offsetBy: startOffset)
        let substringEndIndex = self.index(self.startIndex, offsetBy: endOffset)
        return String(self[substringStartIndex..<substringEndIndex])
    }
    
    // Modified from Kotlin (Apache License, Version 2.0). See LICENSE-THIRD-PARTY in this repo
    public func padEnd(count: Int, padChar: UnicodeScalar = " ") -> String {
        if count <= self.count {
            return self.substring(startOffset: 0, endOffset: self.count)
        }
        
        var result = self
        for _ in 1...(count - self.count) {
            result += String(padChar)
        }
        return result
    }
    
    // Modified from Kotlin (Apache License, Version 2.0). See LICENSE-THIRD-PARTY in this repo
    public func padStart(count: Int, padChar: UnicodeScalar = " ") -> String {
        if count <= self.count {
            return self.substring(startOffset: 0, endOffset: self.count)
        }
        var result = ""
        for _ in 1...(count - self.count) {
            result += String(padChar)
        }
        return result + self
    }
}

extension Array {
    // Modified from Kotlin (Apache License, Version 2.0). See LICENSE-THIRD-PARTY in this repo
    func subList(fromIndex: Int, toIndex: Int) -> Array {
        return Array(self[fromIndex..<toIndex])
    }
    
    // Modified from Kotlin (Apache License, Version 2.0). See LICENSE-THIRD-PARTY in this repo
    func sumBy(selector: (Element) -> Int) -> Int {
        var sum: Int = 0
        for element in self {
            sum += selector(element)
        }
        return sum
    }
    
    // Modified from Kotlin (Apache License, Version 2.0). See LICENSE-THIRD-PARTY in this repo
    func singleOrNull() -> Element? {
        if (count == 1) {
            return self[0]
        }
        else {
            return nil
        }
    }
    
    // Modified from Kotlin (Apache License, Version 2.0). See LICENSE-THIRD-PARTY in this repo
    public func single() -> Element {
        switch count {
        case 0:
            fatalError("List is empty.")
        case 1:
            return self[0]
        default:
            fatalError("List has more than one element.")
        }
    }
}

extension Int {
    public init(_ value: Bool) {
        self = value ? 1 : 0
    }
}

/*
 OrderedSet is part of the Swift.org open source project
 
 Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception
 
 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
 
 The below code was modified from the original.
 */

/// An ordered set is an ordered collection of instances of `Element` in which
/// uniqueness of the objects is guaranteed.
public struct OrderedSet<E: Hashable>: Equatable, Collection {
    public typealias Element = E
    
    var array: [Element]
    var elementToIndex: [Element: Int]
    
    /// Creates an empty ordered set.
    public init() {
        self.array = []
        self.elementToIndex = [:]
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
    public var contents: [Element] { return array }
    
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
    public var startIndex: Int { return contents.startIndex }
    public var endIndex: Int { return contents.endIndex }
    public subscript(index: Int) -> Element {
        return contents[index]
    }
}

public func == <T>(lhs: OrderedSet<T>, rhs: OrderedSet<T>) -> Bool {
    return lhs.contents == rhs.contents
}

extension OrderedSet: Hashable where Element: Hashable { }
