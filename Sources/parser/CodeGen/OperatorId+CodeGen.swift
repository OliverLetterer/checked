//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

extension OperatorId {
    func call(lhs: String, rhs: String) -> String {
        if let context = context as? CodeGenerator {
            return context.call(definition, lhs: lhs, rhs: rhs)
        } else {
            return definition.call(in: context, lhs: lhs, rhs: rhs)
        }
    }
}
