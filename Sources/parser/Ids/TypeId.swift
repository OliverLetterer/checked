//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

public struct TypeId: TypecheckerId, Equatable, Hashable {
    public var uuid: UUID
    public var context: StructDefiningContext
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    public var description: String {
        return context.qualifedName + "." + context.structs.lookup[self]!.name
    }
}
