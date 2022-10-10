//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

extension PrefixOperatorDefinition {
    func functionName(in context: Context) -> String {
        let argument: String = (self.argument.name?.toIdentifier() ?? "") + self.argument.typeReference.declareReference()
        return (context.qualifedName + "." + "prefixoperator" + "_" + op.functionName + returns.declareReference() + "_" + argument).toIdentifier()
    }
    
    func prototype(in context: Context) -> String {
        return "\(self.returns.declareReference()) \(functionName(in: context))(\(argument.typeReference.declareReference()))"
    }
    
    func call(in context: Context, argument: String) -> String {
        return functionName(in: context) + "(" + argument + ")"
    }
}
