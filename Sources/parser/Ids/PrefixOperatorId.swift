//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

public struct PrefixOperatorId: TypecheckerId, Equatable, Hashable {
    public var uuid: UUID
    public var context: OperatorDefiningContext
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    public var definition: PrefixOperatorDefinition {
        return context.prefixOperators.lookup[self]!
    }
    
    public var description: String {
        return context.qualifedName + "." + definition.op.description
    }
}
