/*
 * Copyright 2010-2018 JetBrains s.r.o. and Kotlin Programming Language contributors.
 * Use of this source code is governed by the Apache 2.0 license that can be found in the
 * https://github.com/JetBrains/kotlin/blob/master/license/LICENSE.txt file.
 *
 * The below code was modified from the original.
 */

extension String {
    // Modified from Kotlin (Apache License, Version 2.0). See LICENSE in this repo
    public func lines() -> [Substring] {
        split(separator: "\n", omittingEmptySubsequences: false)
    }

    // Modified from Kotlin (Apache License, Version 2.0). See LICENSE in this repo
    public func substring(startOffset: Int, endOffset: Int) -> String {
        let substringStartIndex = index(startIndex, offsetBy: startOffset)
        let substringEndIndex = index(startIndex, offsetBy: endOffset)
        return String(self[substringStartIndex ..< substringEndIndex])
    }

    // Modified from Kotlin (Apache License, Version 2.0). See LICENSE in this repo
    public func padEnd(count: Int, padChar: UnicodeScalar = " ") -> String {
        if count <= self.count {
            return substring(startOffset: 0, endOffset: self.count)
        }

        var result = self
        for _ in 1 ... (count - self.count) {
            result += String(padChar)
        }
        return result
    }

    // Modified from Kotlin (Apache License, Version 2.0). See LICENSE in this repo
    public func padStart(count: Int, padChar: UnicodeScalar = " ") -> String {
        if count <= self.count {
            return substring(startOffset: 0, endOffset: self.count)
        }
        var result = ""
        for _ in 1 ... (count - self.count) {
            result += String(padChar)
        }
        return result + self
    }
}

extension Array {
    // Modified from Kotlin (Apache License, Version 2.0). See LICENSE in this repo
    func subList(fromIndex: Int, toIndex: Int) -> Array {
        Array(self[fromIndex ..< toIndex])
    }

    // Modified from Kotlin (Apache License, Version 2.0). See LICENSE in this repo
    func sumBy(selector: (Element) -> Int) -> Int {
        var sum: Int = 0
        for element in self {
            sum += selector(element)
        }
        return sum
    }

    // Modified from Kotlin (Apache License, Version 2.0). See LICENSE in this repo
    func singleOrNull() -> Element? {
        if count == 1 {
            return self[0]
        } else {
            return nil
        }
    }

    // Modified from Kotlin (Apache License, Version 2.0). See LICENSE in this repo
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
