//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

extension PrefixOperatorDeclaration: CodeGeneratable {
    public func gen(codeGen: CodeGen) throws {
        codeGen.header.append("""
        \(operatorDefinition.prototype(in: checked.id.context));
        """)
        
        codeGen.implementation.append("""
        \(self.returns.checked.typeId.declareReference()) \(operatorDefinition.functionName(in: checked.id.context))(\(argument.typeReference.checked.id.declareReference()) \(argument.name.toIdentifier())) {
        \(RefCounter(codeGen: codeGen, statements: statements).implement().withIndent(4))
        }
        """)
    }
}
