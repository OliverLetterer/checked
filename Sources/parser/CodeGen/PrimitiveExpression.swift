//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation
import CheckedScanner

public enum PrimitiveExpression {
    case integerLiteralExpression(literal: String, returns: TypeId)
    case floatingPointLiteralExpression(literal: String, returns: TypeId)
    case booleanLiteralExpression(literal: Bool, returns: TypeId)
    case stringLiteralExpression(literal: String, returns: TypeId)
    case variableReferenceExpression(variable: String, returns: TypeId)
    
    var inputs: Set<String> {
        switch self {
        case let .variableReferenceExpression(variable: variable, returns: _):
            return [ variable ]
        default:
            return []
        }
    }
    
    var returns: TypeId {
        switch self {
        case let .integerLiteralExpression(literal: _, returns: returns), let .floatingPointLiteralExpression(literal: _, returns: returns), let .booleanLiteralExpression(literal: _, returns: returns), let .stringLiteralExpression(literal: _, returns: returns), let .variableReferenceExpression(variable: _, returns: returns):
            return returns
        }
    }
    
    func implement(codeGen: CodeGen) -> String {
        switch self {
        case let .integerLiteralExpression(literal: literal, returns: returns):
            return returns.implement(integerLiteral: literal)
        case let .floatingPointLiteralExpression(literal: literal, returns: returns):
            return returns.implement(floatingPointLiteral: literal)
        case let .booleanLiteralExpression(literal: literal, returns: returns):
            return returns.implement(booleanLiteral: literal)
        case let .stringLiteralExpression(literal: literal, returns: returns):
            return codeGen.variable(forStringLiteral: literal, type: returns)
        case let .variableReferenceExpression(variable: variable, returns: _):
            return variable.toIdentifier()
        }
    }
}
