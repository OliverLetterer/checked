//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

public struct KeywordToken: Token {
    public enum Keyword: String, Equatable, Hashable {
        case `let`
        case `var`
        case `func`
        case `_`
        case `operator`
        case `if`
        case `else`
        case `prefix`
        case `return`
    }
    
    public var keyword: Keyword
    public var file: URL
    public var location: Range<Int>
    
    init(keyword: Keyword, file: URL, location: Range<Int>) {
        self.keyword = keyword
        self.file = file
        self.location = location
    }
    
    public var description: String {
        return "`keyword:\(keyword.rawValue)`"
    }
}
