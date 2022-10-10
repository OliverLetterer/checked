//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

extension MethodId {
    func call(instance: String, arguments: [String]) -> String {
        if let context = context.moduleContext as? CodeGenerator {
            return context.call(definition, instance: instance, arguments: arguments)
        } else {
            return definition.call(in: context, instance: instance, arguments: arguments)
        }
    }
}
