//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

extension PrefixOperatorId {
    func call(argument: String) -> String {
        if let context = context as? CodeGenerator {
            return context.call(definition, argument: argument)
        } else {
            return definition.call(in: context, argument: argument)
        }
    }
}
