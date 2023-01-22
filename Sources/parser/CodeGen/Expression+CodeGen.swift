//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

extension Expression {
    func gen(refCounter: RefCounter) -> ([PrimitiveStatement], PrimitiveStatement.AssignableExpression) {
        switch self {
        case let .functionCallExpression(name: _, function: checked, arguments: arguments, returns: returns, file: _, location: _):
            var primitiveStatements: [PrimitiveStatement] = []
            var primitiveArguments: [PrimitiveExpression] = []

            arguments.forEach { argument in
                let (newStatements, expression) = argument.expression.name(refCounter: refCounter)

                primitiveStatements.append(contentsOf: newStatements)
                primitiveArguments.append(expression)
            }

            return (primitiveStatements, .functionCallExpression(function: checked.id, arguments: primitiveArguments, returns: returns.id))
        case let .groupedExpression(expression: expression, returns: _, file: _, location: _):
            return expression.gen(refCounter: refCounter)
        case .integerLiteralExpression, .floatingPointLiteralExpression, .booleanLiteralExpression, .stringLiteralExpression, .variableReferenceExpression:
            return ([], .expression(name(refCounter: refCounter).1))
        case let .prefixOperatorExpression(operator: _, checked: checked, expression: expression, returns: returns, file: _, location: _):
            let (statements, expression) = expression.name(refCounter: refCounter)
            return (statements, .prefixOperatorExpression(operator: checked.id, expression: expression, returns: returns.id))
        case let .binaryOperatorExpression(operator: op, checked: checked, lhs: lhs, rhs: rhs, returns: returns, file: file, location: _):
            func defaultOrder() -> ([PrimitiveStatement], PrimitiveStatement.AssignableExpression) {
                let (lhsStatements, lhsExpression) = lhs.name(refCounter: refCounter)
                let (rhsStatements, rhsExpression) = rhs.name(refCounter: refCounter)

                return (lhsStatements + rhsStatements, .binaryOperatorExpression(checked.id, lhs: lhsExpression, rhs: rhsExpression, returns: returns.id))
            }

            switch rhs {
            case let .binaryOperatorExpression(operator: rhsOp, checked: rhsChecked, lhs: rhsLhs, rhs: rhsRhs, returns: rhsReturns, file: rhsFile, location: _):
                if rhsOp.op.precedence > op.op.precedence {
                    let resultLhs = Expression.binaryOperatorExpression(operator: op, checked: checked, lhs: lhs, rhs: rhsLhs, returns: returns, file: file, location: lhs.location.lowerBound..<rhsLhs.location.upperBound)
                    return Expression.binaryOperatorExpression(operator: rhsOp, checked: rhsChecked, lhs: resultLhs, rhs: rhsRhs, returns: rhsReturns, file: rhsFile, location: resultLhs.location.lowerBound..<rhsRhs.location.upperBound).gen(refCounter: refCounter)
                } else {
                    return defaultOrder()
                }
            default:
                return defaultOrder()
            }
        case let .methodCallExpression(instance: instance, name: _, method: method, arguments: arguments, returns: returns, file: _, location: _):
            let (instanceStatements, instanceExpression) = instance.name(refCounter: refCounter)
            var primitiveStatements: [PrimitiveStatement] = []
            var primitiveArguments: [PrimitiveExpression] = []

            arguments.forEach { argument in
                let (newStatements, expression) = argument.expression.name(refCounter: refCounter)

                primitiveStatements.append(contentsOf: newStatements)
                primitiveArguments.append(expression)
            }

            return (instanceStatements + primitiveStatements, .methodCallExpression(instance: instanceExpression, method: method.id, arguments: primitiveArguments, returns: returns.id))
        }
    }
    
    func name(refCounter: RefCounter) -> ([PrimitiveStatement], PrimitiveExpression) {
        switch self {
        case .functionCallExpression, .groupedExpression, .prefixOperatorExpression, .binaryOperatorExpression, .methodCallExpression:
            let (primitiveStatements, expression) = gen(refCounter: refCounter)

            let name = refCounter.codeGen.newVariable()
            let last = PrimitiveStatement.variableDeclaration(uuid: refCounter.newUUID(), name: name, typeReference: returns.id, expression: expression)

            return (primitiveStatements + [ last ], .variableReferenceExpression(variable: name, returns: returns.id))
        case let .integerLiteralExpression(literal: literal, returns: returns, file: _, location: _):
            return ([], .integerLiteralExpression(literal: literal, returns: returns.id))
        case let .floatingPointLiteralExpression(literal: literal, returns: returns, file: _, location: _):
            return ([], .floatingPointLiteralExpression(literal: literal, returns: returns.id))
        case let .booleanLiteralExpression(literal: literal, returns: returns, file: _, location: _):
            return ([], .booleanLiteralExpression(literal: literal, returns: returns.id))
        case let .stringLiteralExpression(literal: literal, returns: returns, file: _, location: _):
            let variable = returns.id.implement(stringLiteral: literal)
            return ([], .stringLiteralExpression(literal: literal, variable: variable, returns: returns.id))
        case let .variableReferenceExpression(variable: variable, returns: returns, file: _, location: _):
            return ([], .variableReferenceExpression(variable: variable.identifier, returns: returns.id))
        }
    }
}
