//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

extension MethodDeclaration: CodeGeneratable {
    public func gen(codeGen: CodeGen) throws {
        codeGen.header.append("""
        \(functionDefinition.prototype(in: checked.id.context));
        """)
        
        let arguments: [String] = [ "\(checked.id.context.type.declareReference()) self" ] + self.arguments.map({ $0.typeReference.checked.typeId.declareReference() + " " + $0.name.toIdentifier() })
        codeGen.implementation.append("""
        \(self.returns?.checked.typeId.declareReference() ?? "void") \(functionDefinition.functionName(in: checked.id.context))(\(arguments.joined(separator: ", "))) {
        \(RefCounter(codeGen: codeGen, statements: statements).implement().withIndent(4))
        }
        """)
    }
}
