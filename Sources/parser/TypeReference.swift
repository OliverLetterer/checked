//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation
import CheckedScanner

public struct TypeReference: AST {
    public var name: String
    public var checked: InferredType<TypeId> = .unresolved
    public var file: URL
    public var location: Range<Int>
    
    init(name: String, file: URL, location: Range<Int>) {
        self.name = name
        self.file = file
        self.location = location
    }
    
    public var description: String {
        return """
        \(checked.description)
        """
    }
}

extension TypeReference {
    public static func canParse(parser: Parser) -> Bool {
        return true
    }
    
    public static func parse(parser: Parser) throws -> TypeReference {
        guard let next = parser.peek() else {
            throw ParserError.unexpectedEndOfFile(parser: parser)
        }
        
        guard let identifier = next as? IdentifierToken else {
            throw ParserError.unexpectedToken(parser: parser, token: next)
        }
        
        try! parser.drop()
        
        return TypeReference(name: identifier.identifier, file: parser.file, location: identifier.location)
    }
}
