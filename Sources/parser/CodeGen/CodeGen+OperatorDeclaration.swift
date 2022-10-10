//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

extension OperatorDeclaration: CodeGeneratable {
    public func gen(codeGen: CodeGen) throws {
        codeGen.header.append("""
        \(operatorDefinition.prototype(in: checked.id.context));
        """)
        
        codeGen.implementation.append("""
        \(self.returns.checked.typeId.declareReference()) \(operatorDefinition.functionName(in: checked.id.context))(\(lhs.typeReference.checked.id.declareReference()) \(lhs.name.toIdentifier()), \(rhs.typeReference.checked.id.declareReference()) \(rhs.name.toIdentifier())) {
        \(RefCounter(codeGen: codeGen, statements: statements).implement().withIndent(4))
        }
        """)
    }
}
