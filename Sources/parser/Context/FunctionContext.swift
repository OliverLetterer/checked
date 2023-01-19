//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation
import CheckedScanner

public class FunctionContext: Context, FunctionBodyContext {
    public let qualifedName: String
    
    public var isImpure: Bool {
        return functionDefinition.isImpure
    }
    
    public var functionDefinition: FunctionDefinition
    public var variables: (lookup: [String : VariableDefinition], locations: [String : SourceElement])
    public var codeGen: CodeGen
    public var parent: Context?
    
    public init(functionDefinition: FunctionDefinition, codeGen: CodeGen, parent: Context) throws {
        self.qualifedName = parent.qualifedName + "." + "unkown function"
        self.functionDefinition = functionDefinition
        self.variables = ([:], [:])
        self.codeGen = codeGen
        self.parent = parent
    }
}
