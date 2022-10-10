//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation
import CheckedScanner

public protocol AST: SourceElement {
    var description: String { get }
    
    static func canParse(parser: Parser) -> Bool
    static func parse(parser: Parser) throws -> Self
}

internal extension String {
    func withIndent(_ indent: Int) -> String {
        return split(separator: "\n").map({ String(repeating: " ", count: indent) + $0 }).joined(separator: "\n")
    }
}
