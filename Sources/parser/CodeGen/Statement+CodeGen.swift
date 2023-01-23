//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

extension Statement {
    func gen(refCounter: RefCounter) -> [PrimitiveStatement] {
        switch self {
        case let .expression(expression):
            let (statements, expression) = expression.gen(refCounter: refCounter)
            return statements + [ .expression(uuid: refCounter.newUUID(), expression) ]
        case let .returnStatement(expression: expression, file: _, location: _):
            if let expression = expression {
                let (statements, expression) = expression.name(refCounter: refCounter)
                return statements + [ .returnStatement(uuid: refCounter.newUUID(), expression: expression) ]
            } else {
                return [ .returnStatement(uuid: refCounter.newUUID(), expression: nil) ]
            }
        case let .variableDeclaration(isMutable: _, name: name, typeReference: _, expression: expression, file: _, location: _):
            let (statements, expression) = expression.gen(refCounter: refCounter)
            return statements + [ .variableDeclaration(uuid: refCounter.newUUID(), name: name.identifier, typeReference: expression.returns, expression: expression) ]
        case let .ifStatement(conditions: conditions, statements: statements, elseIfs: elseIfs, elseStatements: elseStatements, file: _, location: _):
            var primitiveStatements: [PrimitiveStatement] = []
            
            var primitiveConditions: [[PrimitiveExpression]] = [[]]
            var resultStatements: [[PrimitiveStatement]] = []
            
            conditions.forEach { condition in
                let (statements, expression) = condition.name(refCounter: refCounter)
                primitiveStatements.append(contentsOf: statements)
                primitiveConditions[0].append(expression)
            }
            
            resultStatements.append(statements.flatMap({ $0.gen(refCounter: refCounter) }))
            
            if let elseIfs = elseIfs {
                elseIfs.enumerated().forEach { index, pair in
                    let (conditions, statements) = pair
                    
                    primitiveConditions.append([])
                    
                    conditions.forEach { condition in
                        let (statements, expression) = condition.name(refCounter: refCounter)
                        primitiveStatements.append(contentsOf: statements)
                        primitiveConditions[index + 1].append(expression)
                    }
                    
                    resultStatements.append(statements.flatMap({ $0.gen(refCounter: refCounter) }))
                }
            }
            
            let statement = PrimitiveStatement.ifStatement(uuid: refCounter.newUUID(), conditions: primitiveConditions, statements: resultStatements, elseStatements: elseStatements?.flatMap({ $0.gen(refCounter: refCounter) }))
            
            return primitiveStatements + [ statement ]
        case let .variableIfDeclaration(isMutable: _, name: name, typeReference: _, checked: checked, conditions: conditions, statements: statements, elseIfs: elseIfs, elseStatements: elseStatements, file: _, location: _):
            var primitiveStatements: [PrimitiveStatement] = [ .variableDeclaration(uuid: refCounter.newUUID(), name: name.identifier, typeReference: checked.id, expression: nil) ]
            
            func implementLast(_ statements: [Statement]) -> [Statement] {
                let last: Statement
                switch statements.last! {
                case let .expression(expression):
                    last = .assignmentStatement(lhs: .variableReferenceExpression(variable: name, returns: expression.returns, file: file, location: location), rhs: expression, file: file, location: location)
                case let .ifStatement(conditions: conditions, statements: statements, elseIfs: elseIfs, elseStatements: elseStatements, file: file, location: location):
                    last = .ifStatement(conditions: conditions, statements: implementLast(statements), elseIfs: elseIfs?.map({ ($0.conditions, implementLast($0.statements)) }), elseStatements: elseStatements.map({ implementLast($0) }), file: file, location: location)
                default:
                    fatalError()
                }
                
                return statements.dropLast() + [ last ]
            }
            
            let elseIfStatements: [(conditions: [Expression], statements: [Statement])]?
            if let elseIfs = elseIfs {
                elseIfStatements = elseIfs.map({ value in
                    return (value.conditions, implementLast(value.statements))
                })
            } else {
                elseIfStatements = nil
            }
            
            primitiveStatements += Statement.ifStatement(conditions: conditions, statements: implementLast(statements), elseIfs: elseIfStatements, elseStatements: implementLast(elseStatements), file: file, location: location).gen(refCounter: refCounter)
            
            return primitiveStatements
        case let .assignmentStatement(lhs: lhs, rhs: rhs, file: _, location: _):
            let (lhsStatements, lhsExpression) = lhs.name(refCounter: refCounter)
            let (rhsStatements, rhsExpression) = rhs.name(refCounter: refCounter)
            
            return lhsStatements + rhsStatements + [ .assignmentStatement(uuid: refCounter.newUUID(), lhs: lhsExpression, rhs: .expression(rhsExpression)) ]
        case let .returnIfStatement(checked: _, conditions: conditions, statements: statements, elseIfs: elseIfs, elseStatements: elseStatements, file: _, location: _):
            func implementLast(_ statements: [Statement]) -> [Statement] {
                let last: Statement
                switch statements.last! {
                case let .expression(expression):
                    last = .returnStatement(expression: expression, file: file, location: location)
                case let .ifStatement(conditions: conditions, statements: statements, elseIfs: elseIfs, elseStatements: elseStatements, file: file, location: location):
                    last = .ifStatement(conditions: conditions, statements: implementLast(statements), elseIfs: elseIfs?.map({ ($0.conditions, implementLast($0.statements)) }), elseStatements: elseStatements.map({ implementLast($0) }), file: file, location: location)
                default:
                    fatalError()
                }
                
                return statements.dropLast() + [ last ]
            }
            
            let elseIfStatements: [(conditions: [Expression], statements: [Statement])]?
            if let elseIfs = elseIfs {
                elseIfStatements = elseIfs.map({ value in
                    return (value.conditions, implementLast(value.statements))
                })
            } else {
                elseIfStatements = nil
            }
            
            return Statement.ifStatement(conditions: conditions, statements: implementLast(statements), elseIfs: elseIfStatements, elseStatements: implementLast(elseStatements), file: file, location: location).gen(refCounter: refCounter)
        }
    }
}
