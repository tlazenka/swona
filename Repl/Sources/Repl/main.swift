import Foundation
import Swona
import LineNoise

/**
 * Implementation of Read-Eval-Print loop.
 */

extension Bool {
    var statusText: String {
        if self {
            return "on"
        }
        else {
            return "off"
        }
    }
}

extension Evaluator {
    func loadResource(file: String) throws {
        let f = Resources().children.compactMap { $0 as? File }.first { $0.filename == file }
        
        guard let data = f?.contents, let source = String(data: data, encoding: .utf8) else {
            print("Error loading file: \(file)")
            return
        }
        
        try loadResource(source: source, file: file)

    }
}

// Modified from Kotlin (Apache License, Version 2.0). See LICENSE-THIRD-PARTY in this repo
func measureTimeMillis(block: () throws -> Void) throws -> UInt64 {
    let start = DispatchTime.now()
    try block()    
    return (DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
}

let lineNoise = LineNoise()
lineNoise.preserveHistoryEdits = true

let evaluator = Evaluator()
try registerRuntimeFunctions(evaluator: evaluator)

lineNoise.setCompletionCallback {
    buffer in
    let lowercasedBuffer = buffer.lowercased()
    return evaluator.bindingsNames().filter { $0.lowercased().hasPrefix(lowercasedBuffer) }
}

try evaluator.loadResource(file: "prelude.sk")

print("Welcome to Swona, a Swift port of Siilinkari! Enjoy your stay or type 'exit' to get out.")

var showElapsedTime = false
while true {
    var line: String
    do {
        line = try lineNoise.getLine(prompt: ">>> ")
    }
    catch LinenoiseError.CTRL_C {
        exit(EXIT_SUCCESS)
    }
    catch {
        break
    }
    print()
    if line == "" {
        continue
    }
    if line == "exit" {
        break
    }
    
    lineNoise.addHistory(line)
    
    if line == ":trace" {
        evaluator.trace = !evaluator.trace;
        print("trace \(evaluator.trace.statusText)")
        continue
    }
    else if (line == ":time") {
        showElapsedTime = !showElapsedTime
        print("time \(showElapsedTime.statusText)")
        continue
    }
    else if (line == ":optimize") {
        evaluator.optimize = !evaluator.optimize
        print("optimize \(evaluator.optimize.statusText)")
        continue
    }
    
    do {
        if line.hasPrefix(":dump ") {
            print(try evaluator.dump(code: String(line.dropFirst(":dump ".count))))
        }
        else {
            while true {
                do {
                    let elapsedTime = try measureTimeMillis {
                        let evaluation = try evaluator.evaluate(code: line)
                        let value = evaluation.value
                        let type = evaluation.type
                        if evaluation.type != .unit {
                            print("\(type) = \(value.repr())")
                        }
                    }
                    if (showElapsedTime) {
                        print("time: \(elapsedTime)ms")
                    }
                    break
                }
                catch {
                    if error is UnexpectedEndOfInputException {
                        print("... ", terminator: "")
                        guard let newLine = readLine() else {
                            break
                        }
                        line = line + "\n" + newLine
                    }
                    else {
                        throw error
                    }
                }
            }
        }
    }
    catch {
        if let e = error as? SyntaxErrorException {
            print("Syntax error: \(e.errorMessage)")
            print(e.sourceLocation.toLongString())
        }
        else if let e = error as? TypeCheckException {
            print("Type checking failed: \(e.errorMessage)")
            print(e.sourceLocation.toLongString())
        }
        else {
            print(error)
        }
    }

}

print("Thank you for visiting Swona, have a nice day!")
