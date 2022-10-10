//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation
import CheckedScanner

public class OperatorContext: Context, VariableDefiningContext {
    public let qualifedName: String
    public var operatorDefinition: OperatorDefinition
    public var variables: (lookup: [String : VariableDefinition], locations: [String : SourceElement])
    public var codeGen: CodeGen
    public var parent: Context?
    
    public init(operatorDefinition: OperatorDefinition, codeGen: CodeGen, parent: Context) throws {
        self.qualifedName = parent.qualifedName + "." + "unknown operator"
        self.operatorDefinition = operatorDefinition
        self.variables = ([:], [:])
        self.codeGen = codeGen
        self.parent = parent
    }
}
