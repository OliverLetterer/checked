//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

public struct ArrowToken: Token {
    public var file: URL
    public var location: Range<Int>
    
    init(file: URL, location: Range<Int>) {
        self.file = file
        self.location = location
    }
    
    public var description: String {
        return "`->`"
    }
}
