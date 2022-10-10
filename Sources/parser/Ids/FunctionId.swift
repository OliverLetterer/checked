//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

public struct FunctionId: TypecheckerId, Equatable, Hashable {
    public var uuid: UUID
    public var context: FunctionDefiningContext
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    public var definition: FunctionDefinition {
        return context.functions.lookup[self]!
    }
    
    public var description: String {
        return definition.name
    }
}
