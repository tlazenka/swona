import Swona

/**
 * Implementation of Read-Eval-Print loop.
 */

let evaluator = Evaluator()
try registerRuntimeFunctions(evaluator: evaluator)

print("Welcome to Swona, a Swift port of Siilinkari! Enjoy your stay or type 'exit' to get out.")
while true {
    print(">>> ", terminator: "")
    guard var line = readLine() else {
        break
    }
    if line == "" {
        continue
    }
    if line == "exit" {
        break
    }
    
    do {
        while true {
            do {
                let evaluation = try evaluator.evaluate(code: line)
                let value = evaluation.value
                let type = evaluation.type
                if evaluation.type != .unit {
                    print("\(type) = \(value.repr())")
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
