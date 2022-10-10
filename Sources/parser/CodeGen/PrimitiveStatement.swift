//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation
import CheckedScanner

public indirect enum PrimitiveStatement {
    public enum AssignmentExpression {
        case expression(PrimitiveExpression)
        case functionCallExpression(function: FunctionId, arguments: [PrimitiveExpression], returns: TypeId)
        case prefixOperatorExpression(operator: PrefixOperatorId, expression: PrimitiveExpression, returns: TypeId)
        case binaryOperatorExpression(OperatorId, lhs: PrimitiveExpression, rhs: PrimitiveExpression, returns: TypeId)
        case methodCallExpression(instance: PrimitiveExpression, method: MethodId, arguments: [PrimitiveExpression], returns: TypeId)
        
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
    
    case expression(uuid: UUID, AssignmentExpression)
    case returnStatement(uuid: UUID, expression: PrimitiveExpression?)
    case variableDeclaration(uuid: UUID, name: String, typeReference: TypeId, expression: AssignmentExpression?)
    case ifStatement(uuid: UUID, conditions: [PrimitiveExpression], statements: [PrimitiveStatement], elseIfs: [(conditions: [PrimitiveExpression], statements: [PrimitiveStatement])]?, elseStatements: [PrimitiveStatement]?)
    case assignmentStatement(uuid: UUID, lhs: PrimitiveExpression, rhs: AssignmentExpression)
    case retain(String)
    case release(String)
    
    var uuid: UUID {
        switch self {
        case let .expression(uuid: uuid, _), let .returnStatement(uuid: uuid, expression: _), let .variableDeclaration(uuid: uuid, name: _, typeReference: _, expression: _), let .ifStatement(uuid: uuid, conditions: _, statements: _, elseIfs: _, elseStatements: _), let .assignmentStatement(uuid: uuid, lhs: _, rhs: _):
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
            if typeReference == typeReference.context.moduleContext.typechecker!.buildIn.Void {
                if let expression = expression {
                    return expression.implement() + ";"
                } else {
                    return ""
                }
            } else {
                if let expression = expression {
                    return typeReference.declareReference() + " " + name.toIdentifier() + " = " + expression.implement() + ";"
                } else {
                    return typeReference.declareReference() + " " + name.toIdentifier() + ";"
                }
            }
        case let .ifStatement(uuid: _, conditions: conditions, statements: statements, elseIfs: elseIfs, elseStatements: elseStatements):
            var result = """
            if (\(conditions.map({ "(\($0.implement()))" }).joined(separator: " && "))) {
            \(statements.map({ $0.implement() }).joined(separator: "\n").withIndent(4))
            }
            """
            
            if let elseIfs = elseIfs {
                elseIfs.forEach { elseIf in
                    result += """
                     else if (\(elseIf.conditions.map({ "(\($0.implement()))" }).joined(separator: " && "))) {
                    \(elseIf.statements.map({ $0.implement() }).joined(separator: "\n").withIndent(4))
                    }
                    """
                }
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
