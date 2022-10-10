//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

public extension String {
    var red: String {
        return "\u{001B}[0;31m" + self + "\u{001B}[0;0m"
    }
}
