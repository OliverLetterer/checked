//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

extension FunctionId {
    func call(arguments: [String]) -> String {
        if let context = context as? CodeGenerator {
            return context.call(definition, arguments: arguments)
        } else {
            return definition.call(in: context, arguments: arguments)
        }
    }
}
