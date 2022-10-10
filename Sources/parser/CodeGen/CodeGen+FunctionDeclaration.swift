//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

extension FunctionDeclaration: CodeGeneratable {
    public func gen(codeGen: CodeGen) throws {
        codeGen.header.append("""
        \(functionDefinition.prototype(in: checked.id.context));
        """)
        
        let arguments: String = self.arguments.map({ $0.typeReference.checked.typeId.declareReference() + " " + $0.name.toIdentifier() }).joined(separator: ", ")
        codeGen.implementation.append("""
        \(self.returns?.checked.typeId.declareReference() ?? "void") \(functionDefinition.functionName(in: checked.id.context))(\(arguments)) {
        \(RefCounter(codeGen: codeGen, statements: statements).implement().withIndent(4))
        }
        """)
    }
}
