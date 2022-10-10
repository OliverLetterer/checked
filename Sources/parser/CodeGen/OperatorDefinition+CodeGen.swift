//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation
import CheckedScanner

extension OperatorToken.Operator {
    var functionName: String {
        switch self {
        case .plus: return "plus"
        case .minus: return "minus"
        case .times: return "times"
        case .division: return "division"
        case .not: return "not"
        case .and: return "and"
        case .or: return "or"
        case .binaryAnd: return "binaryand"
        case .binaryOr: return "binaryor"
        case .binaryXor: return "binaryxor"
        case .equal: return "equal"
        case .assignment: return "assignment"
        case .modulo: return "module"
        case .smaller: return "smaller"
        case .smallerEqual: return "smallerequal"
        case .greater: return "greater"
        case .greaterEqual: return "greaterequal"
        }
    }
}

extension OperatorDefinition {
    func functionName(in context: Context) -> String {
        let lhs: String = (self.lhs.name?.toIdentifier() ?? "") + self.lhs.typeReference.declareReference()
        let rhs: String = (self.rhs.name?.toIdentifier() ?? "") + self.rhs.typeReference.declareReference()
        
        let arguments: String = "_" + lhs + "_" + rhs
        return (context.qualifedName + "." + "operator" + "_" + op.functionName + returns.declareReference() + arguments).toIdentifier()
    }
    
    func prototype(in context: Context) -> String {
        return "\(self.returns.declareReference()) \(functionName(in: context))(\(lhs.typeReference.declareReference()), \(rhs.typeReference.declareReference()))"
    }
    
    func call(in context: Context, lhs: String, rhs: String) -> String {
        return functionName(in: context) + "(" + lhs + ", " + rhs + ")"
    }
}
