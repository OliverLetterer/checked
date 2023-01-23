//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

extension FunctionDeclaration: CodeGeneratable {
    public func gen(codeGen: CodeGen) throws {
        codeGen.register(self)
    }
}
