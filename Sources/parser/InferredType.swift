//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

public enum InferredType<T: TypecheckerId> {
    case unresolved
    case inferred(type: T, context: Context, typechecker: Typechecker)
    
    public var description: String {
        switch self {
        case .unresolved:
            return ""
        case let .inferred(type: type, context: _, typechecker: _):
            return type.description
        }
    }
}
