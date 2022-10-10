//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

extension FunctionDefinition {
    func functionName(in context: Context) -> String {
        let returnType: String
        if let returns = self.returns {
            returnType = returns.declareReference()
        } else {
            returnType = ""
        }
        
        let arguments: String
        if self.arguments.count == 0 {
            arguments = ""
        } else {
            arguments = "_" + self.arguments.map({ ($0.name?.toIdentifier() ?? "") + $0.typeReference.declareReference() }).joined(separator: "_")
        }
        return (context.qualifedName + "." + name + returnType + arguments).toIdentifier()
    }
    
    func prototype(in context: Context) -> String {
        return "\(self.returns?.declareReference() ?? "void") \(functionName(in: context))(\(arguments.map({ $0.typeReference.declareReference() }).joined(separator: ", ")))"
    }
    
    func call(in context: Context, arguments: [String]) -> String {
        return functionName(in: context) + "(" + arguments.joined(separator: ", ") + ")"
    }
}
