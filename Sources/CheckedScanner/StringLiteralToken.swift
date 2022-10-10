//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

public struct StringLiteralToken: Token {
    public var literal: String
    public var file: URL
    public var location: Range<Int>
    
    init(literal: String, file: URL, location: Range<Int>) {
        self.literal = literal
        self.file = file
        self.location = location
    }
    
    public var description: String {
        let value = literal
            .replacingOccurrences(of: "\0", with: "\\0")
            .replacingOccurrences(of: "\t", with: "\\t")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\u{001B}", with: "\\e")
        return "`stringLiteral:\(value)`"
    }
}
