//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

public protocol CodeGenerator {
    func declare(reference: TypeId) -> String
    func implement(floatingPointLiteral: String, for typeId: TypeId) -> String
    func implement(integerLiteral: String, for typeId: TypeId) -> String
    func implement(stringLiteral: String, codeGen: CodeGen) -> String
    func isRefCounted(_ typeId: TypeId) -> Bool
    func call(_ operatorDefinition: PrefixOperatorDefinition, argument: String) -> String
    func call(_ operatorDefinition: OperatorDefinition, lhs: String, rhs: String) -> String
    func call(_ functionDefinition: FunctionDefinition, arguments: [String]) -> String
    func call(_ methodDefinition: MethodDefinition, instance: String, arguments: [String]) -> String
}
