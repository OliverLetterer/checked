//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

public struct IntegerLiteralToken: Token {
    public var literal: String
    public var file: URL
    public var location: Range<Int>
    
    init(literal: String, file: URL, location: Range<Int>) {
        self.literal = literal
        self.file = file
        self.location = location
    }
    
    public var description: String {
        return "`integerLiteral:\(literal)`"
    }
}
