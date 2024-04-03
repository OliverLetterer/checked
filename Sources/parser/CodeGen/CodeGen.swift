//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

public enum CodeGenError: Error {
    case notRepresentable(value: String, type: String)
    case assertionFailure(conditionExpression: String, file: URL, line: Int, column: Int)
}

public protocol CodeGeneratable: AST {
    func gen(codeGen: CodeGen) throws
}

private protocol FunctionLikeGeneratable {
    var prototype: String { get }
    var functionName: String { get }
    var returnType: TypeReference? { get }
    var arguments: [FunctionDeclaration.FunctionArgumentDeclaration] { get }
}

extension FunctionDeclaration: FunctionLikeGeneratable {
    var prototype: String { return functionDefinition.prototype(in: checked.context) }
    var functionName: String { return functionDefinition.functionName(in: checked.context) }
    var returnType: TypeReference? { return returns }
}

extension OperatorDeclaration: FunctionLikeGeneratable {
    var prototype: String { return operatorDefinition.prototype(in: checked.context) }
    var functionName: String { return operatorDefinition.functionName(in: checked.context) }
    var returnType: TypeReference? { return returns }
    var arguments: [FunctionDeclaration.FunctionArgumentDeclaration] { return [ lhs, rhs ] }
}

extension PrefixOperatorDeclaration: FunctionLikeGeneratable {
    var prototype: String { return operatorDefinition.prototype(in: checked.context) }
    var functionName: String { return operatorDefinition.functionName(in: checked.context) }
    var returnType: TypeReference? { return returns }
    var arguments: [FunctionDeclaration.FunctionArgumentDeclaration] { return [ argument ] }
}

private extension PrimitiveStatement {
    var declaredVariable: String? {
        switch self {
        case let .variableDeclaration(uuid: _, name: name, typeReference: _, expression: _):
            return name
        default:
            return nil
        }
    }
}

public class CodeGen {
    public enum Configuration: Equatable {
        case debug
        case release
    }
    
    public var configuration: Configuration
    
    internal var header: [String] = []
    internal var implementation: [String] = []
    
    private var uuids: Set<UUID> = []
    private var lock: os_unfair_lock = .init()
    
    private var variableCount: UInt64 = 0
    private var variableLock: os_unfair_lock = .init()
    
    private var stringLiterals: [String: String] = [:]
    private var stringLiteralLock: os_unfair_lock = .init()
    
    var functions: [FunctionId: (FunctionDeclaration, [PrimitiveStatement])] = [:]
    var operators: [OperatorId: (OperatorDeclaration, [PrimitiveStatement])] = [:]
    var prefixOperators: [PrefixOperatorId: (PrefixOperatorDeclaration, [PrimitiveStatement])] = [:]
    
    init(configuration: Configuration) {
        self.configuration = configuration
    }
    
    public func newUUID() -> UUID {
        os_unfair_lock_lock(&lock)
        defer {
            os_unfair_lock_unlock(&lock)
        }
        
        var uuid = UUID()
        while uuids.contains(uuid) {
            uuid = UUID()
        }
        
        uuids.insert(uuid)
        return uuid
    }
    
    public func newVariable() -> String {
        os_unfair_lock_lock(&variableLock)
        defer {
            os_unfair_lock_unlock(&variableLock)
        }
        
        let name = "_variable_" + variableCount.description
        variableCount += 1
        return name
    }
    
    public func variable(forStringLiteral stringLiteral: String, type: TypeId) -> String {
        os_unfair_lock_lock(&stringLiteralLock)
        defer {
            os_unfair_lock_unlock(&stringLiteralLock)
        }
        
        if let variable = stringLiterals[stringLiteral] {
            return variable
        } else {
            let variable = type.implement(stringLiteral: stringLiteral)
            stringLiterals[stringLiteral] = variable
            return variable
        }
    }
    
    public func gen(_ topLevelDeclarations: [TopLevelDeclaration]) throws {
        header.append("""
        #include <stdbool.h>
        #include <stdio.h>
        #include <stdlib.h>
        #include <unistd.h>
        #include <memory.h>
        #include <stdatomic.h>
        """)
        
        switch configuration {
        case .debug:
            header.append("#define DEBUG")
        case .release:
            header.append("#define RELEASE")
        }

        guard let main: FunctionDeclaration = topLevelDeclarations.flatMap({ $0.functionDeclarations }).first(where: { $0.name.name == "main" && $0.arguments.count == 0 }) else {
            fatalError()
        }

        let buildIn: BuildIn = main.returns!.checked.typechecker.buildIn
        buildIn.implement(codeGen: self)
        
        try topLevelDeclarations.forEach({ try $0.gen(codeGen: self) })
        
        try evaluateCompileTimeExpressions()
        
        func generate<T: FunctionLikeGeneratable>(_ declaration: T, statements: [PrimitiveStatement]) {
            header.append(declaration.prototype + ";")
            
            let arguments: String = declaration.arguments.map({ $0.typeReference.checked.typeId.declareReference() + " " + $0.name.toIdentifier() }).joined(separator: ", ")
            implementation.append("""
            \(declaration.returnType?.checked.typeId.declareReference() ?? "void") \(declaration.functionName)(\(arguments)) {
            \(refCount(statements: statements).map({ $0.implement(codeGen: self) }).joined(separator: "\n").withIndent(4))
            }
            """)
        }
        
        functions.keys.sorted(by: { $0.definition.prototype(in: $0.context) < $1.definition.prototype(in: $1.context) }).forEach { id in
            let (declaration, statements) = functions[id]!
            generate(declaration, statements: statements)
        }
        
        operators.keys.sorted(by: { $0.definition.prototype(in: $0.context) < $1.definition.prototype(in: $1.context) }).forEach { id in
            let (declaration, statements) = operators[id]!
            generate(declaration, statements: statements)
        }
        
        prefixOperators.keys.sorted(by: { $0.definition.prototype(in: $0.context) < $1.definition.prototype(in: $1.context) }).forEach { id in
            let (declaration, statements) = prefixOperators[id]!
            generate(declaration, statements: statements)
        }
        
        let intTypes: [TypeId] = [ buildIn.Int8, buildIn.Int16, buildIn.Int32, buildIn.Int64, buildIn.UInt8, buildIn.UInt16, buildIn.UInt32, buildIn.UInt64 ]
        if main.returns!.checked.id == main.returns!.checked.typechecker.buildIn.Void {
            implementation.append("""
            int main() {
                \(main.functionDefinition.call(in: main.returns!.checked.context, arguments: []));
                return 0;
            }
            """)
        } else if intTypes.contains(main.returns!.checked.id) {
            implementation.append("""
            int main() {
                return (int)\(main.functionDefinition.call(in: main.returns!.checked.context, arguments: []));
            }
            """)
        } else {
            throw ParserError.invalidMainDeclaration(main: main)
        }

        let source = header.joined(separator: "\n\n") + "\n\n" + implementation.joined(separator: "\n\n")
        print(source)
    }
    
    func register(_ declaration: FunctionDeclaration) {
        functions[declaration.checked.id] = (declaration, removeUnusedCode(statements: declaration.statements.flatMap({ $0.gen(codeGen: self) })).statements)
    }
    
    func register(_ declaration: OperatorDeclaration) {
        operators[declaration.checked.id] = (declaration, removeUnusedCode(statements: declaration.statements.flatMap({ $0.gen(codeGen: self) })).statements)
    }
    
    func register(_ declaration: PrefixOperatorDeclaration) {
        prefixOperators[declaration.checked.id] = (declaration, removeUnusedCode(statements: declaration.statements.flatMap({ $0.gen(codeGen: self) })).statements)
    }
    
    private func evaluateCompileTimeExpressions() throws {
        try functions.forEach { (id, pair) in
            let (declaration, statements) = pair
            functions[id] = (declaration, try evaluateCompileTimeExpressions(statements: statements).statements)
            functions[id] = (declaration, removeUnusedCode(statements: functions[id]!.1).statements)
        }
        
        try operators.forEach { (id, pair) in
            let (declaration, statements) = pair
            operators[id] = (declaration, try evaluateCompileTimeExpressions(statements: statements).statements)
            operators[id] = (declaration, removeUnusedCode(statements: operators[id]!.1).statements)
        }
        
        try prefixOperators.forEach { (id, pair) in
            let (declaration, statements) = pair
            prefixOperators[id] = (declaration, try evaluateCompileTimeExpressions(statements: statements).statements)
            prefixOperators[id] = (declaration, removeUnusedCode(statements: prefixOperators[id]!.1).statements)
        }
    }
    
    private func removeUnusedCode(statements: [PrimitiveStatement], outerVariables: Set<String> = []) -> (statements: [PrimitiveStatement], requiredVariables: Set<String>) {
        var result: [PrimitiveStatement] = []
        var requiredVariables: Set<String> = outerVariables.subtracting(Set(statements.compactMap({ $0.declaredVariable })))
        
        statements.reversed().forEach { statement in
            switch statement {
            case let .expression(uuid: _, expression):
                if expression.isImpure {
                    result.append(statement)
                    requiredVariables.formUnion(expression.inputs)
                }
            case let .assertion(uuid: _, condition: condition, reason: reason, conditionExpression: _, file: _, line: _, column: _):
                result.append(statement)
                requiredVariables.formUnion(condition.inputs)
                
                if let reason = reason {
                    requiredVariables.formUnion(reason.inputs)
                }
            case let .returnStatement(uuid: _, expression: expression):
                result.removeAll()
                requiredVariables.removeAll()

                if let expression = expression {
                    requiredVariables.formUnion(expression.inputs)
                }

                result.append(statement)
            case let .variableDeclaration(uuid: uuid, name: name, typeReference: typeReference, expression: expression):
                if requiredVariables.contains(name) {
                    result.append(statement)
                    requiredVariables.remove(name)

                    if let expression = expression {
                        requiredVariables.formUnion(expression.inputs)
                    }
                } else {
                    if let expression = expression {
                        if expression.isImpure {
                            if typeReference.isRefCounted {
                                result.append(statement)
                                requiredVariables.formUnion(expression.inputs)
                            } else {
                                result.append(.expression(uuid: uuid, expression))
                                requiredVariables.formUnion(expression.inputs)
                            }
                        }
                    }
                }
                
                if outerVariables.contains(name) {
                    requiredVariables.insert(name)
                }
            case let .ifStatement(uuid: uuid, conditions: conditions, statements: statements, elseStatements: elseStatements):
                let usedStatements = statements.map({ removeUnusedCode(statements: $0, outerVariables: requiredVariables) })
                let usedElseStatements = elseStatements.flatMap({ let result = removeUnusedCode(statements: $0, outerVariables: requiredVariables); return result.statements.count > 0 ? result : nil })
                
                result.append(.ifStatement(uuid: uuid, conditions: conditions, statements: usedStatements.map(\.statements), elseStatements: usedElseStatements?.statements))
                
                requiredVariables.formUnion(conditions.flatMap({ $0.flatMap(\.inputs) }))
                requiredVariables.formUnion(usedStatements.flatMap(\.requiredVariables))
                requiredVariables.formUnion(usedElseStatements?.requiredVariables ?? [])
            case let .assignmentStatement(uuid: uuid, lhs: lhs, rhs: rhs):
                switch lhs {
                case let .variableReferenceExpression(variable: name, returns: _):
                    if requiredVariables.contains(name) {
                        result.append(statement)
                        requiredVariables.formUnion(rhs.inputs)
                    } else if rhs.isImpure {
                        result.append(.expression(uuid: uuid, rhs))
                        requiredVariables.formUnion(rhs.inputs)
                    }
                default:
                    break
                }
            case let .scopeBlock(uuid: uuid, statements: statements):
                let (usedStatements, variables) = removeUnusedCode(statements: statements, outerVariables: requiredVariables)
                
                if usedStatements.count > 0 {
                    result.append(.scopeBlock(uuid: uuid, statements: usedStatements))
                    requiredVariables.formUnion(variables)
                }
            case .retain, .release:
                fatalError()
            }
        }
        
        return (result.reversed(), requiredVariables)
    }
}
