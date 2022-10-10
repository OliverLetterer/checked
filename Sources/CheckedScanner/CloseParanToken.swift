//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

public struct CloseParanToken: Token {
    public var file: URL
    public var location: Range<Int>
    
    init(file: URL, location: Range<Int>) {
        self.file = file
        self.location = location
    }
    
    public var description: String {
        return "`)`"
    }
}
