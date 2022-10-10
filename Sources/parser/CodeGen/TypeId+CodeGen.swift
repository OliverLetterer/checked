//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

extension TypeId {
    func declareReference() -> String {
        if let codeGenerator = context as? CodeGenerator {
            return codeGenerator.declare(reference: self)
        } else {
            return context.structs.lookup[self]!.name
        }
    }
    
    func implement(booleanLiteral: Bool) -> String {
        return booleanLiteral ? "true" : "false"
    }
    
    func implement(floatingPointLiteral: String) -> String {
        if let codeGenerator = context as? CodeGenerator {
            return codeGenerator.implement(floatingPointLiteral: floatingPointLiteral, for: self)
        } else {
            return floatingPointLiteral
        }
    }
    
    func implement(integerLiteral: String) -> String {
        if let codeGenerator = context as? CodeGenerator {
            return codeGenerator.implement(integerLiteral: integerLiteral, for: self)
        } else {
            return integerLiteral
        }
    }
    
    func implement(stringLiteral: String) -> String {
        if let codeGenerator = context as? CodeGenerator {
            return codeGenerator.implement(stringLiteral: stringLiteral, codeGen: context.codeGen)
        } else {
            return stringLiteral
        }
    }
    
    var isRefCounted: Bool {
        if let codeGenerator = context as? CodeGenerator {
            return codeGenerator.isRefCounted(self)
        } else {
            return false
        }
    }
}
