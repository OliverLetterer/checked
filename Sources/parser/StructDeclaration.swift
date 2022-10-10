//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation
import CheckedScanner

public struct StructDefinition: Equatable, Hashable {
    public var name: String
    
    init(name: String) {
        self.name = name
    }
}
