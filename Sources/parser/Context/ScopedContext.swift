//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation
import CheckedScanner

public class ScopedContext: Context, FunctionBodyContext {
    public let qualifedName: String
    
    public var isImpure: Bool {
        return functionBodyParent.isImpure
    }
    
    public var variables: (lookup: [String : VariableDefinition], locations: [String : SourceElement])
    public var codeGen: CodeGen
    public var parent: Context?
    public var functionBodyParent: FunctionBodyContext
    
    public init(codeGen: CodeGen, parent: FunctionBodyContext) throws {
        self.qualifedName = parent.qualifedName
        self.variables = ([:], [:])
        self.codeGen = codeGen
        self.parent = parent
        self.functionBodyParent = parent
    }
}
