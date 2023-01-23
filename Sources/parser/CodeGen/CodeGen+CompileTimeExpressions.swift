//
//  File.swift
//
//
//  Copyright 2023 Oliver Letterer
//

import Foundation

public enum CompileTimeExpression: Equatable {
    case integerLiteral(literal: String, returns: TypeId)
    case floatingPointLiteral(literal: String, returns: TypeId)
    case booleanLiteral(literal: Bool, returns: TypeId)
    case stringLiteral(literal: String, returns: TypeId)
    
    var primitiveExpression: PrimitiveExpression {
        switch self {
        case let .integerLiteral(literal: literal, returns: returns):
            return .integerLiteralExpression(literal: literal, returns: returns)
        case let .floatingPointLiteral(literal: literal, returns: returns):
            return .floatingPointLiteralExpression(literal: literal, returns: returns)
        case let .booleanLiteral(literal: literal, returns: returns):
            return .booleanLiteralExpression(literal: literal, returns: returns)
        case let .stringLiteral(literal: literal, returns: returns):
            return .stringLiteralExpression(literal: literal, variable: "", returns: returns)
        }
    }
    
    var returns: TypeId {
        switch self {
        case let .integerLiteral(literal: _, returns: returns), let .floatingPointLiteral(literal: _, returns: returns), let .booleanLiteral(literal: _, returns: returns), let .stringLiteral(literal: _, returns: returns):
            return returns
        }
    }
    
    var integerLiteral: String {
        switch self {
        case let .integerLiteral(literal: literal, returns: _):
            return literal
        default:
            fatalError()
        }
    }
    
    var floatingPointLiteral: String {
        switch self {
        case let .floatingPointLiteral(literal: literal, returns: _):
            return literal
        default:
            fatalError()
        }
    }
    
    var bool: Bool {
        switch self {
        case let .booleanLiteral(literal: literal, returns: _):
            return literal
        default:
            fatalError()
        }
    }
    
    var string: String {
        switch self {
        case let .stringLiteral(literal: literal, returns: _):
            return literal
        default:
            fatalError()
        }
    }
}

private extension PrimitiveExpression {
    func compileTimeExpression(withVariables variables: [String: CompileTimeExpression]) -> CompileTimeExpression? {
        switch self {
        case let .integerLiteralExpression(literal: literal, returns: returns):
            return .integerLiteral(literal: literal, returns: returns)
        case let .floatingPointLiteralExpression(literal: literal, returns: returns):
            return .floatingPointLiteral(literal: literal, returns: returns)
        case let .booleanLiteralExpression(literal: literal, returns: returns):
            return .booleanLiteral(literal: literal, returns: returns)
        case let .stringLiteralExpression(literal: literal, variable: _, returns: returns):
            return .stringLiteral(literal: literal, returns: returns)
        case let .variableReferenceExpression(variable: name, returns: _):
            return variables[name]
        }
    }
}

private extension PrimitiveStatement.AssignableExpression {
    func compileTimeExpression(codeGen: CodeGen, withVariables variables: [String: CompileTimeExpression]) throws -> CompileTimeExpression? {
        switch self {
        case let .expression(expression):
            return expression.compileTimeExpression(withVariables: variables)
        case let .functionCallExpression(function: function, arguments: arguments, returns: _):
            let compileTimeArguments = arguments.compactMap({ $0.compileTimeExpression(withVariables: variables) })
            if !function.definition.isImpure, compileTimeArguments.count == arguments.count {
                return try codeGen.evaluateCompileTime(function, arguments: compileTimeArguments)
            } else {
                return nil
            }
        case let .prefixOperatorExpression(operator: op, expression: expression, returns: _):
            if !op.definition.isImpure, let compileTimeExpression = expression.compileTimeExpression(withVariables: variables) {
                return try codeGen.evaluateCompileTime(op, argument: compileTimeExpression)
            } else {
                return nil
            }
        case let .binaryOperatorExpression(op, lhs: lhs, rhs: rhs, returns: _):
            if !op.definition.isImpure, let lhsCompileTimeExpression = lhs.compileTimeExpression(withVariables: variables), let rhsCompileTimeExpression = rhs.compileTimeExpression(withVariables: variables) {
                return try codeGen.evaluateCompileTime(op, lhs: lhsCompileTimeExpression, rhs: rhsCompileTimeExpression)
            } else {
                return nil
            }
        case let .methodCallExpression(instance: instance, method: method, arguments: arguments, returns: _):
            let compileTimeArguments = arguments.compactMap({ $0.compileTimeExpression(withVariables: variables) })
            if !method.definition.isImpure, let instanceCompileTimeExpression = instance.compileTimeExpression(withVariables: variables), compileTimeArguments.count == arguments.count {
                return try codeGen.evaluateCompileTime(method, instance: instanceCompileTimeExpression, arguments: compileTimeArguments)
            } else {
                return nil
            }
        }
    }
}

private extension PrimitiveStatement {
    enum VariableUpdate {
        case assignment(name: String, value: CompileTimeExpression)
        case declaration(name: String, value: CompileTimeExpression)
    }
    
    func evaluateCompileTimeExpression(codeGen: CodeGen, _ existingVariables: [String: CompileTimeExpression]) throws -> (statements: [PrimitiveStatement], updates: [VariableUpdate]) {
        switch self {
        case let .expression(uuid: uuid, expression):
            if let result = try expression.compileTimeExpression(codeGen: codeGen, withVariables: existingVariables) {
                return ([ .expression(uuid: uuid, .expression(result.primitiveExpression)) ], [])
            } else {
                return ([ self ], [])
            }
        case let .returnStatement(uuid: uuid, expression: expression):
            if let result = expression?.compileTimeExpression(withVariables: existingVariables) {
                let expression = result.primitiveExpression
                let name = codeGen.newVariable()
                let last = PrimitiveStatement.variableDeclaration(uuid: codeGen.newUUID(), name: name, typeReference: expression.returns, expression: .expression(expression))
                return ([last, .returnStatement(uuid: uuid, expression: .variableReferenceExpression(variable: name, returns: expression.returns))], [])
            } else {
                return ([ self ], [])
            }
        case let .variableDeclaration(uuid: uuid, name: name, typeReference: typeReference, expression: expression):
            if let result = try expression?.compileTimeExpression(codeGen: codeGen, withVariables: existingVariables) {
                return ([ .variableDeclaration(uuid: uuid, name: name, typeReference: typeReference, expression: .expression(result.primitiveExpression)) ], [ .declaration(name: name, value: result) ])
            } else {
                return ([ self ], [])
            }
        case let .ifStatement(uuid: uuid, conditions: conditions, statements: statements, elseStatements: elseStatements):
            if let firstCondition = conditions.map({ $0.map({ $0.compileTimeExpression(withVariables: existingVariables) }) }).enumerated().first(where: { $0.element.allSatisfy({ $0?.bool == true }) }) {
                let (usedStatements, variables) = try codeGen.evaluateCompileTimeExpressions(statements: statements[firstCondition.offset], existingVariables: existingVariables)
                
                if usedStatements.count > 0 {
                    return ([ .scopeBlock(uuid: uuid, statements: usedStatements) ], variables.map({ VariableUpdate.assignment(name: $0.key, value: $0.value) }))
                } else {
                    return ([], [])
                }
            } else {
                let indizes = conditions.map({ $0.map({ $0.compileTimeExpression(withVariables: existingVariables) }) }).enumerated().filter({ $0.element.contains(where: { $0?.bool == false }) }).map(\.offset)
                
                if indizes.count == conditions.count {
                    if let elseStatements = elseStatements {
                        let (statements, updates) = try codeGen.evaluateCompileTimeExpressions(statements: elseStatements, existingVariables: existingVariables)
                        return (statements, updates.map({ VariableUpdate.assignment(name: $0.key, value: $0.value) }))
                    } else {
                        return ([], [])
                    }
                } else {
                    var usedConditions = conditions
                    var usedStatements = statements
                    
                    indizes.reversed().forEach({ usedConditions.remove(at: $0); usedStatements.remove(at: $0) })
                    
                    if let elseStatements = elseStatements {
                        let statements = try usedStatements.map({ try codeGen.evaluateCompileTimeExpressions(statements: $0, existingVariables: existingVariables) })
                        let usedElseStatements = try codeGen.evaluateCompileTimeExpressions(statements: elseStatements, existingVariables: existingVariables)
                        
                        var updates: [String: CompileTimeExpression] = [:]
                        let variables: Set<String> = Set(statements.flatMap(\.updates.keys) + usedElseStatements.updates.map(\.key))
                        
                        variables.forEach { name in
                            let values = statements.map({ $0.updates[name] }) + [ usedElseStatements.updates[name] ]
                            
                            guard let value = values.compactMap({ $0 }).first else {
                                return
                            }
                            
                            guard values.allSatisfy({ $0 == value }) else {
                                return
                            }
                            
                            updates[name] = value
                        }
                        
                        return ([ .ifStatement(uuid: uuid, conditions: usedConditions, statements: statements.map(\.statements), elseStatements: usedElseStatements.statements) ], updates.map({ VariableUpdate.assignment(name: $0.key, value: $0.value) }))
                    } else {
                        return try ([ .ifStatement(uuid: uuid, conditions: usedConditions, statements: usedStatements.map({ try codeGen.evaluateCompileTimeExpressions(statements: $0, existingVariables: existingVariables).statements }), elseStatements: nil) ], [])
                    }
                }
            }
        case let .assignmentStatement(uuid: uuid, lhs: lhs, rhs: rhs):
            if let result = try rhs.compileTimeExpression(codeGen: codeGen, withVariables: existingVariables), case let .variableReferenceExpression(variable: name, returns: _) = lhs {
                return ([ .assignmentStatement(uuid: uuid, lhs: lhs, rhs: .expression(result.primitiveExpression)) ], [ .assignment(name: name, value: result) ])
            } else {
                return ([ self ], [])
            }
        case let .scopeBlock(uuid: uuid, statements: statements):
            let (usedStatements, variables) = try codeGen.evaluateCompileTimeExpressions(statements: statements, existingVariables: existingVariables)
            
            if usedStatements.count > 0 {
                return ([ .scopeBlock(uuid: uuid, statements: usedStatements) ], variables.map({ VariableUpdate.assignment(name: $0.key, value: $0.value) }))
            } else {
                return ([], [])
            }
        case .retain, .release:
            fatalError()
        }
    }
}

extension CodeGen {
    func evaluateCompileTime(_ op: PrefixOperatorId, argument: CompileTimeExpression) throws -> CompileTimeExpression {
        assert(!op.definition.isImpure)
        
        if let context = op.context as? CodeGenerator {
            return try context.evaluateCompileTimeOperator(op, argument: argument)
        } else {
            let variables: [String: CompileTimeExpression] = [ prefixOperators[op]!.0.argument.name: argument ]
            return try evaluateFunctionBody(variables: variables, statements: prefixOperators[op]!.1).result!
        }
    }
    
    func evaluateCompileTime(_ op: OperatorId, lhs: CompileTimeExpression, rhs: CompileTimeExpression) throws -> CompileTimeExpression {
        assert(!op.definition.isImpure)
        
        if let context = op.context as? CodeGenerator {
            return try context.evaluateCompileTimeOperator(op, lhs: lhs, rhs: rhs)
        } else {
            let variables: [String: CompileTimeExpression] = [ operators[op]!.0.lhs.name: lhs, operators[op]!.0.rhs.name: rhs ]
            return try evaluateFunctionBody(variables: variables, statements: operators[op]!.1).result!
        }
    }
    
    func evaluateCompileTime(_ function: FunctionId, arguments: [CompileTimeExpression]) throws -> CompileTimeExpression {
        assert(!function.definition.isImpure)
        
        if let context = function.context as? CodeGenerator {
            return try context.evaluateCompileTimeFunction(function, arguments: arguments)
        } else {
            var variables: [String: CompileTimeExpression] = [:]
            functions[function]!.0.arguments.enumerated().forEach { index, argument in
                variables[argument.name] = arguments[index]
            }
            return try evaluateFunctionBody(variables: variables, statements: functions[function]!.1).result!
        }
    }
    
    func evaluateCompileTime(_ method: MethodId, instance: CompileTimeExpression, arguments: [CompileTimeExpression]) throws -> CompileTimeExpression {
        assert(!method.definition.isImpure)
        
        if let context = method.context.moduleContext as? CodeGenerator {
            return try context.evaluateCompileTimeMethod(method, instance: instance, arguments: arguments)
        } else {
            fatalError()
        }
    }
    
    func evaluateFunctionBody(variables: [String: CompileTimeExpression], statements: [PrimitiveStatement]) throws -> (result: CompileTimeExpression?, updates: [String: CompileTimeExpression]) {
        var trackedVariables: [String: CompileTimeExpression] = variables
        var declaredVariables: [String: CompileTimeExpression?] = [:]
        
        func existingVariables() -> [String: CompileTimeExpression] {
            var variables = trackedVariables
            declaredVariables.filter({ $0.value != nil }).forEach({ variables[$0] = $1! })
            return variables
        }
        
        var result: CompileTimeExpression? = nil
        
        try statements.forEach { statement in
            if result != nil {
                return
            }
            
            switch statement {
            case .expression:
                break
            case let .returnStatement(uuid: _, expression: expression):
                result = expression!.compileTimeExpression(withVariables: existingVariables())!
            case let .variableDeclaration(uuid: _, name: name, typeReference: _, expression: expression):
                declaredVariables[name] = try expression?.compileTimeExpression(codeGen: self, withVariables: existingVariables())
            case let .ifStatement(uuid: _, conditions: conditions, statements: statements, elseStatements: elseStatements):
                let usedStatements: [PrimitiveStatement]
                if let firstCondition = conditions.map({ $0.map({ $0.compileTimeExpression(withVariables: existingVariables()) }) }).enumerated().first(where: { $0.element.allSatisfy({ $0?.bool == true }) }) {
                    usedStatements = statements[firstCondition.offset]
                } else {
                    usedStatements = elseStatements!
                }
                
                let (value, updates) = try evaluateFunctionBody(variables: existingVariables(), statements: usedStatements)
                if let value = value {
                    result = value
                } else {
                    updates.forEach { name, value in
                        if declaredVariables[name] != nil {
                            declaredVariables[name] = value
                        } else {
                            trackedVariables[name] = value
                        }
                    }
                }
            case let .assignmentStatement(uuid: _, lhs: lhs, rhs: rhs):
                if case let .variableReferenceExpression(variable: name, returns: _) = lhs, let compileTimeExpression = try rhs.compileTimeExpression(codeGen: self, withVariables: existingVariables()) {
                    if declaredVariables[name] != nil {
                        declaredVariables[name] = compileTimeExpression
                    } else {
                        trackedVariables[name] = compileTimeExpression
                    }
                }
            case let .scopeBlock(uuid: _, statements: statements):
                let (value, updates) = try evaluateFunctionBody(variables: existingVariables(), statements: statements)
                if let value = value {
                    result = value
                } else {
                    updates.forEach { name, value in
                        if declaredVariables[name] != nil {
                            declaredVariables[name] = value
                        } else {
                            trackedVariables[name] = value
                        }
                    }
                }
            case .retain, .release:
                fatalError()
            }
        }
        
        return (result, trackedVariables)
    }
    
    func evaluateCompileTimeExpressions(statements: [PrimitiveStatement], existingVariables: [String: CompileTimeExpression] = [:]) throws -> (statements: [PrimitiveStatement], updates: [String: CompileTimeExpression]) {
        var trackedVariables: [String: CompileTimeExpression] = [:]
        var declaredVariables: [String: CompileTimeExpression] = [:]
        
        func variables() -> [String: CompileTimeExpression] {
            var variables = trackedVariables
            declaredVariables.forEach({ variables[$0] = $1 })
            return variables
        }
        
        let statements = try statements.flatMap { statement -> [PrimitiveStatement] in
            let (statements, updates) = try statement.evaluateCompileTimeExpression(codeGen: self, variables())
            
            updates.forEach { update in
                switch update {
                case let .assignment(name: name, value: value):
                    if declaredVariables[name] != nil {
                        declaredVariables[name] = value
                    } else {
                        trackedVariables[name] = value
                    }
                case let .declaration(name: name, value: value):
                    trackedVariables[name] = value
                }
            }
            
            return statements
        }
        return (statements, trackedVariables)
    }
}
