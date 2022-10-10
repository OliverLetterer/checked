//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

extension TopLevelDeclaration: CodeGeneratable {
    public func gen(codeGen: CodeGen) throws {
        try prefixOperatorDeclarations.forEach({ try $0.gen(codeGen: codeGen) })
        try operatorDeclarations.forEach({ try $0.gen(codeGen: codeGen) })
        try functionDeclarations.forEach({ try $0.gen(codeGen: codeGen) })
    }
}
