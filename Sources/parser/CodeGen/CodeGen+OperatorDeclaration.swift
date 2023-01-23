//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

extension OperatorDeclaration: CodeGeneratable {
    public func gen(codeGen: CodeGen) throws {
        codeGen.register(self)
    }
}
