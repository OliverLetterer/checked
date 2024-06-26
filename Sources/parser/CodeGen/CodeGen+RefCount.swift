//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

private extension PrimitiveExpression {
    func references(variable: String) -> Bool {
        switch self {
        case let .variableReferenceExpression(variable: name, returns: _):
            return variable == name
        default:
            return false
        }
    }
}

private extension PrimitiveStatement.AssignableExpression {
    func references(variable: String) -> Bool {
        switch self {
        case let .expression(expression):
            return expression.references(variable: variable)
        case let .binaryOperatorExpression(_, lhs: lhs, rhs: rhs, returns: _):
            return lhs.references(variable: variable) || rhs.references(variable: variable)
        case let .prefixOperatorExpression(operator: _, expression: expression, returns: _):
            return expression.references(variable: variable)
        case let .functionCallExpression(function: _, arguments: arguments, returns: _):
            return arguments.contains(where: { $0.references(variable: variable) })
        case let .methodCallExpression(instance: instance, method: _, arguments: arguments, returns: _):
            return instance.references(variable: variable) || arguments.contains(where: { $0.references(variable: variable) })
        }
    }
}

private extension PrimitiveStatement {
    func declares(variable: String) -> Bool {
        switch self {
        case let .variableDeclaration(uuid: _, name: name, typeReference: _, expression: _):
            return variable == name
        default:
            return false
        }
    }
    
    func references(variable: String) -> Bool {
        switch self {
        case let .expression(uuid: _, expression):
            return expression.references(variable: variable)
        case let .assertion(uuid: _, condition: condition, reason: reason, conditionExpression: _, module: _, file: _, line: _, column: _):
            return condition.references(variable: variable) || (reason?.references(variable: variable) ?? false)
        case let .returnStatement(uuid: _, expression: expression):
            return expression?.references(variable: variable) ?? false
        case let .variableDeclaration(uuid: _, name: _, typeReference: _, expression: expression):
            return expression?.references(variable: variable) ?? false
        case let .ifStatement(uuid: _, conditions: conditions, statements: statements, elseStatements: elseStatements):
            let conditionsReferences = conditions.contains(where: { $0.contains(where: { $0.references(variable: variable) }) })
            let statementsReferences = statements.contains(where: { $0.prefix(while: { !$0.declares(variable: variable) }).contains(where: { $0.references(variable: variable) }) })
            let elseStatementsReferences = elseStatements?.prefix(while: { !$0.declares(variable: variable) }).contains(where: { $0.references(variable: variable) }) ?? false
            
            return conditionsReferences || statementsReferences || elseStatementsReferences
        case let .assignmentStatement(uuid: _, lhs: lhs, rhs: rhs):
            return lhs.references(variable: variable) || rhs.references(variable: variable)
        case let .scopeBlock(uuid: _, statements: statements):
            return statements.prefix(while: { !$0.declares(variable: variable) }).contains(where: { $0.references(variable: variable) }) 
        case .retain, .release:
            return false
        }
    }
    
    var returns: Bool {
        switch self {
        case .returnStatement:
            return true
        default:
            return false
        }
    }
}

extension CodeGen {
    func refCount(statements: [PrimitiveStatement], existingVariables: Set<String> = [], uninitializedVariables: Set<String> = []) -> [PrimitiveStatement] {
        var trackedExistingVariables: [String: UUID] = [:]
        var trackedVariables: [String: UUID] = [:]
        
        var finished: Bool = false
        statements.forEach { statement in
            if finished {
                return
            }
            
            existingVariables.filter({ trackedVariables[$0] == nil }).forEach { name in
                if statement.references(variable: name) {
                    trackedExistingVariables[name] = statement.uuid
                }
            }
            
            trackedVariables.forEach { value in
                if statement.references(variable: value.key) {
                    trackedVariables[value.key] = statement.uuid
                }
            }
            
            if case let .variableDeclaration(uuid: uuid, name: name, typeReference: typeReference, expression: _) = statement, typeReference.isRefCounted {
                trackedVariables[name] = uuid
            }
            
            if statement.returns {
                finished = true
            }
        }
        
        struct DeclaredVariable {
            var name: String
            var freed: Bool
        }
        
        var freedExistingVariables: Set<String> = []
        var usedVariables: [DeclaredVariable] = []
        var topReleases: [PrimitiveStatement] = []
        var uninitializedVariable: String? = nil
        var didReturn: Bool = false
        let returnedStatements = statements.flatMap { statement -> [PrimitiveStatement] in
            if didReturn {
                return [ statement ]
            }
            
            guard !statement.returns else {
                topReleases.append(contentsOf: existingVariables.subtracting(freedExistingVariables).filter({ variable in usedVariables.contains(where: { $0.name == variable }) }).sorted().map({ .release($0) }))
                topReleases.append(contentsOf: existingVariables.subtracting(freedExistingVariables).filter({ variable in !usedVariables.contains(where: { $0.name == variable }) }).filter({ !statement.references(variable: $0) }).sorted().map({ .release($0) }))
                
                didReturn = true
                
                switch statement {
                case let .ifStatement(uuid: uuid, conditions: conditions, statements: statements, elseStatements: elseStatements):
                    let variables = existingVariables.subtracting(freedExistingVariables).filter({ variable in !usedVariables.contains(where: { $0.name == variable }) }).filter({ statement.references(variable: $0) }).union(usedVariables.filter({ !$0.freed }).map(\.name))
                    let uninitialized = uninitializedVariables.union(uninitializedVariable.map({ [ $0 ] }) ?? [])
                    return [ .ifStatement(uuid: uuid, conditions: conditions, statements: statements.map({ refCount(statements: $0, existingVariables: variables, uninitializedVariables: uninitialized) }), elseStatements: elseStatements.map({ refCount(statements: $0, existingVariables: variables, uninitializedVariables: uninitialized) })) ]
                default:
                    return [ statement ]
                }
            }
            
            let hadUninitializedVariable: Bool = uninitializedVariable != nil
            
            func referenceCountExpression(expression: PrimitiveStatement.AssignableExpression?) -> [PrimitiveStatement] {
                guard let expression = expression else {
                    return []
                }
                
                switch expression {
                case let .expression(expression):
                    switch expression {
                    case let .variableReferenceExpression(variable: variable, returns: _):
                        return [ .retain(variable) ]
                    case let .stringLiteralExpression(literal: literal, returns: returns):
                        return [ .retain(variable(forStringLiteral: literal, type: returns)) ]
                    default:
                        return []
                    }
                default:
                    return []
                }
            }
            
            let refCountedStatements: [PrimitiveStatement]
            switch statement {
            case .expression, .assertion, .returnStatement:
                refCountedStatements = [ statement ]
            case let .ifStatement(uuid: uuid, conditions: conditions, statements: statements, elseStatements: elseStatements):
                let variables = existingVariables.subtracting(freedExistingVariables).filter({ variable in !usedVariables.contains(where: { $0.name == variable }) }).union(usedVariables.filter({ !$0.freed }).map(\.name))
                let uninitialized = uninitializedVariables.union(uninitializedVariable.map({ [ $0 ] }) ?? [])
                refCountedStatements = [ .ifStatement(uuid: uuid, conditions: conditions, statements: statements.map({ refCount(statements: $0, existingVariables: variables, uninitializedVariables: uninitialized) }), elseStatements: elseStatements.map({ refCount(statements: $0, existingVariables: variables, uninitializedVariables: uninitialized) })) ]
            case let .assignmentStatement(uuid: _, lhs: lhs, rhs: rhs):
                if !lhs.returns.isRefCounted {
                    refCountedStatements = [ statement ]
                } else {
                    let lhsRelease: [PrimitiveStatement]
                    if uninitializedVariables.contains(lhs.implement(codeGen: self)) {
                        lhsRelease = []
                    } else {
                        lhsRelease = [ .release(lhs.implement(codeGen: self)) ]
                    }
                    
                    refCountedStatements = referenceCountExpression(expression: rhs) + lhsRelease + [ statement ]
                }
            case let .scopeBlock(uuid: uuid, statements: statements):
                let variables = existingVariables.subtracting(freedExistingVariables).filter({ variable in !usedVariables.contains(where: { $0.name == variable }) }).union(usedVariables.filter({ !$0.freed }).map(\.name))
                let uninitialized = uninitializedVariables.union(uninitializedVariable.map({ [ $0 ] }) ?? [])
                refCountedStatements = [ .scopeBlock(uuid: uuid, statements: refCount(statements: statements, existingVariables: variables, uninitializedVariables: uninitialized)) ]
            case let .variableDeclaration(uuid: _, name: name, typeReference: typeReference, expression: expression):
                if !typeReference.isRefCounted {
                    refCountedStatements = [ statement ]
                } else {
                    usedVariables.append(DeclaredVariable(name: name, freed: false))
                    
                    if expression == nil {
                        uninitializedVariable = name
                    }
                    
                    refCountedStatements = referenceCountExpression(expression: expression) + [ statement ]
                }
            case .retain, .release:
                fatalError()
            }
            
            var releases: [PrimitiveStatement] = []
            trackedExistingVariables.filter({ $0.value == refCountedStatements.last!.uuid }).sorted(by: { $0.key < $1.key }).forEach { value in
                freedExistingVariables.insert(value.key)
                releases.append(.release(value.key))
            }
            
            trackedVariables.filter({ $0.value == refCountedStatements.last!.uuid }).sorted(by: { $0.key < $1.key }).forEach { value in
                if let index = usedVariables.firstIndex(where: { $0.name == value.key }) {
                    usedVariables[index].freed = true
                }
                releases.append(.release(value.key))
            }
            
            if uninitializedVariable != nil, hadUninitializedVariable {
                uninitializedVariable = nil
            }
            
            return refCountedStatements + releases
        }
        
        return topReleases + returnedStatements
    }
}
