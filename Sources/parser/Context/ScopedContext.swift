//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation
import CheckedScanner

public class ScopedContext: Context, VariableDefiningContext {
    public let qualifedName: String
    public var variables: (lookup: [String : VariableDefinition], locations: [String : SourceElement])
    public var codeGen: CodeGen
    public var parent: Context?
    
    public init(codeGen: CodeGen, parent: Context) throws {
        self.qualifedName = parent.qualifedName
        self.variables = ([:], [:])
        self.codeGen = codeGen
        self.parent = parent
    }
}
