//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

extension MethodDefinition {
    func functionName(in context: MethodDefiningContext) -> String {
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
    
    func prototype(in context: MethodDefiningContext) -> String {
        let arguments: [String] = [ context.type.declareReference() ] + self.arguments.map({ $0.typeReference.declareReference() })
        return "\(self.returns?.declareReference() ?? "void") \(functionName(in: context))(\(arguments.joined(separator: ", ")))"
    }
    
    func call(in context: MethodDefiningContext, instance: String, arguments: [String]) -> String {
        return functionName(in: context) + "(" + instance + ", " + arguments.joined(separator: ", ") + ")"
    }
}
