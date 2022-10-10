//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

public struct MethodId: TypecheckerId, Equatable, Hashable {
    public var uuid: UUID
    public var context: MethodDefiningContext
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    public var definition: MethodDefinition {
        return context.methods.lookup[self]!
    }
    
    public var description: String {
        return definition.name
    }
}
