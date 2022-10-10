//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

public struct IdentifierToken: Token {
    public var identifier: String
    public var file: URL
    public var location: Range<Int>
    
    init(identifier: String, file: URL, location: Range<Int>) {
        self.identifier = identifier
        self.file = file
        self.location = location
    }
    
    public var description: String {
        return "`identifier:\(identifier)`"
    }
}
