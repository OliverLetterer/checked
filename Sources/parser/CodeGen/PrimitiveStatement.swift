//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation
import CheckedScanner

public indirect enum PrimitiveStatement {
    public enum AssignableExpression {
        case expression(PrimitiveExpression)
        case functionCallExpression(function: FunctionId, arguments: [PrimitiveExpression], returns: TypeId)
        case prefixOperatorExpression(operator: PrefixOperatorId, expression: PrimitiveExpression, returns: TypeId)
        case binaryOperatorExpression(OperatorId, lhs: PrimitiveExpression, rhs: PrimitiveExpression, returns: TypeId)
        case methodCallExpression(instance: PrimitiveExpression, method: MethodId, arguments: [PrimitiveExpression], returns: TypeId)
        
        var returns: TypeId {
            switch self {
            case let .expression(expression):
                return expression.returns
            case let .functionCallExpression(function: _, arguments: _, returns: returns), let .prefixOperatorExpression(operator: _, expression: _, returns: returns), let .binaryOperatorExpression(_, lhs: _, rhs: _, returns: returns), let .methodCallExpression(instance: _, method: _, arguments: _, returns: returns):
                return returns
            }
        }
        
        var isImpure: Bool {
            switch self {
            case .expression:
                return false
            case let .functionCallExpression(function: function, arguments: _, returns: _):
                return function.definition.isImpure
            case let .prefixOperatorExpression(operator: op, expression: _, returns: _):
                return op.definition.isImpure
            case let .binaryOperatorExpression(op, lhs: _, rhs: _, returns: _):
                return op.definition.isImpure
            case let .methodCallExpression(instance: _, method: method, arguments: _, returns: _):
                return method.definition.isImpure
            }
        }
        
        var inputs: Set<String> {
            switch self {
            case let .expression(expression), let .prefixOperatorExpression(operator: _, expression: expression, returns: _):
                return expression.inputs
            case let .functionCallExpression(function: _, arguments: arguments, returns: _):
                return Set(arguments.flatMap(\.inputs))
            case let .binaryOperatorExpression(_, lhs: lhs, rhs: rhs, returns: _):
                return lhs.inputs.union(rhs.inputs)
            case let .methodCallExpression(instance: instance, method: _, arguments: arguments, returns: _):
                return instance.inputs.union(arguments.flatMap(\.inputs))
            }
        }
        
        func implement() -> String {
            switch self {
            case let .expression(expression):
                return expression.implement()
            case let .functionCallExpression(function: function, arguments: arguments, returns: _):
                return function.call(arguments: arguments.map({ $0.implement() }))
            case let .prefixOperatorExpression(operator: op, expression: expression, returns: _):
                return op.call(argument: expression.implement())
            case let .binaryOperatorExpression(op, lhs: lhs, rhs: rhs, returns: _):
                return op.call(lhs: lhs.implement(), rhs: rhs.implement())
            case let .methodCallExpression(instance: instance, method: method, arguments: arguments, returns: _):
                return method.call(instance: instance.implement(), arguments: arguments.map({ $0.implement() }))
            }
        }
    }
    
    case expression(uuid: UUID, AssignableExpression)
    case returnStatement(uuid: UUID, expression: PrimitiveExpression?)
    case variableDeclaration(uuid: UUID, name: String, typeReference: TypeId, expression: AssignableExpression?)
    case ifStatement(uuid: UUID, conditions: [[PrimitiveExpression]], statements: [[PrimitiveStatement]], elseStatements: [PrimitiveStatement]?)
    case assignmentStatement(uuid: UUID, lhs: PrimitiveExpression, rhs: AssignableExpression)
    case scopeBlock(uuid: UUID, statements: [PrimitiveStatement])
    case retain(String)
    case release(String)
    
    var uuid: UUID {
        switch self {
        case let .expression(uuid: uuid, _), let .returnStatement(uuid: uuid, expression: _), let .variableDeclaration(uuid: uuid, name: _, typeReference: _, expression: _), let .ifStatement(uuid: uuid, conditions: _, statements: _, elseStatements: _), let .assignmentStatement(uuid: uuid, lhs: _, rhs: _), let .scopeBlock(uuid: uuid, statements: _):
            return uuid
        case .retain, .release:
            fatalError()
        }
    }
    
    func implement() -> String {
        switch self {
        case let .expression(uuid: _, expression):
            return expression.implement() + ";"
        case let .returnStatement(uuid: _, expression: expression):
            if let expression = expression {
                return "return " + expression.implement() + ";"
            } else {
                return "return;"
            }
        case let .variableDeclaration(uuid: _, name: name, typeReference: typeReference, expression: expression):
            if let expression = expression {
                return typeReference.declareReference() + " " + name.toIdentifier() + " = " + expression.implement() + ";"
            } else {
                return typeReference.declareReference() + " " + name.toIdentifier() + ";"
            }
        case let .ifStatement(uuid: _, conditions: conditions, statements: statements, elseStatements: elseStatements):
            var result: String = ""
            
            conditions.enumerated().forEach { index, conditions in
                let prefix = index == 0 ? "if" : " else if"
                
                result += """
                \(prefix) (\(conditions.map({ "(\($0.implement()))" }).joined(separator: " && "))) {
                \(statements[index].map({ $0.implement() }).joined(separator: "\n").withIndent(4))
                }
                """
            }
            
            if let elseStatements = elseStatements {
                result += """
                 else {
                \(elseStatements.map({ $0.implement() }).joined(separator: "\n").withIndent(4))
                }
                """
            }
            
            return result
        case let .assignmentStatement(uuid: _, lhs: lhs, rhs: rhs):
            return lhs.implement() + " = " + rhs.implement() + ";"
        case let .scopeBlock(uuid: _, statements: statements):
            return """
            {
            \(statements.map({ $0.implement() }).joined(separator: "\n").withIndent(4))
            }
            """
        case let .retain(name):
            if name.hasPrefix("&") {
                return "object_retain(\(name));"
            } else {
                return "object_retain(\(name.toIdentifier()));"
            }
        case let .release(name):
            if name.hasPrefix("&") {
                return "object_release(\(name));"
            } else {
                return "object_release(\(name.toIdentifier()));"
            }
        }
    }
}
