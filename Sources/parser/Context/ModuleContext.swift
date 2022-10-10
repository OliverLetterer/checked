//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation
import CheckedScanner

public class ModuleContext: Context, FunctionDefiningContext, StructDefiningContext, OperatorDefiningContext {
    public let qualifedName: String
    public var name: String
    public var codeGen: CodeGen
    public var parent: Context?
    internal unowned var typechecker: Typechecker?
    public var functions: (lookup: [FunctionId : FunctionDefinition], cache: [String : [(FunctionId, FunctionDefinition)]], locations: [FunctionId : SourceElement])
    public var structs: (lookup: [TypeId : StructDefinition], locations: [TypeId : SourceElement], contexts: [TypeId : MethodDefiningContext])
    public var prefixOperators: (lookup: [PrefixOperatorId : PrefixOperatorDefinition], cache: [OperatorToken.Operator : [(PrefixOperatorId, PrefixOperatorDefinition)]], locations: [PrefixOperatorId : SourceElement])
    public var operators: (lookup: [OperatorId : OperatorDefinition], cache: [OperatorToken.Operator : [(OperatorId, OperatorDefinition)]], locations: [OperatorId : SourceElement])
    
    public init(name: String, codeGen: CodeGen) throws {
        self.qualifedName = name
        self.name = name
        self.codeGen = codeGen
        self.parent = nil
        self.typechecker = nil
        self.functions = ([:], [:], [:])
        self.structs = ([:], [:], [:])
        self.prefixOperators = ([:], [:], [:])
        self.operators = ([:], [:], [:])
    }
}
