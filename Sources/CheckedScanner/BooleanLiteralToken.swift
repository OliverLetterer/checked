//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

public struct BooleanLiteralToken: Token {
    public var literal: Bool
    public var file: URL
    public var location: Range<Int>
    
    init(literal: Bool, file: URL, location: Range<Int>) {
        self.literal = literal
        self.file = file
        self.location = location
    }
    
    public var description: String {
        return "`booleanLiteral:\(literal)`"
    }
}
