//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation
import CheckedScanner

public class MethodContext: Context, MethodDefiningContext {
    public let qualifedName: String
    public var type: TypeId
    public var methods: (lookup: [MethodId : MethodDefinition], cache: [String : [(MethodId, MethodDefinition)]], locations: [MethodId : SourceElement])
    public var codeGen: CodeGen
    public var parent: Context?
    
    public init(type: TypeId, codeGen: CodeGen, parent: Context) throws {
        self.qualifedName = parent.qualifedName + "." + type.context.structs.lookup[type]!.name
        self.type = type
        self.methods = ([:], [:], [:])
        self.codeGen = codeGen
        self.parent = parent
    }
}
