//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation
import CheckedScanner

public struct TopLevelDeclaration: AST {
    public var functionDeclarations: [FunctionDeclaration]
    public var operatorDeclarations: [OperatorDeclaration]
    public var prefixOperatorDeclarations: [PrefixOperatorDeclaration]
    public var file: URL
    public var location: Range<Int>
    
    init(functionDeclarations: [FunctionDeclaration], operatorDeclarations: [OperatorDeclaration], prefixOperatorDeclarations: [PrefixOperatorDeclaration], file: URL, location: Range<Int>) {
        self.functionDeclarations = functionDeclarations
        self.operatorDeclarations = operatorDeclarations
        self.prefixOperatorDeclarations = prefixOperatorDeclarations
        self.file = file
        self.location = location
    }
    
    public var description: String {
        return """
        \(type(of: self))
        - functionDeclarations:
        \(functionDeclarations.map(\.description).map({ $0.withIndent(4) }).joined(separator: "\n"))
        - operatorDeclarations:
        \(operatorDeclarations.map(\.description).map({ $0.withIndent(4) }).joined(separator: "\n"))
        - prefixOperatorDeclarations:
        \(prefixOperatorDeclarations.map(\.description).map({ $0.withIndent(4) }).joined(separator: "\n"))
        """
    }
}

extension TopLevelDeclaration {
    public static func canParse(parser: Parser) -> Bool {
        return true
    }
    
    public static func parse(parser: Parser) throws -> TopLevelDeclaration {
        var functionDeclarations: [FunctionDeclaration] = []
        var operatorDeclarations: [OperatorDeclaration] = []
        var prefixOperatorDeclarations: [PrefixOperatorDeclaration] = []
        
        while let next = parser.peek() {
            if next is NewLineToken {
                try! parser.drop()
                continue
            }
            
            if FunctionDeclaration.canParse(parser: parser) {
                functionDeclarations.append(try FunctionDeclaration.parse(parser: parser))
                continue
            } else if PrefixOperatorDeclaration.canParse(parser: parser) {
                prefixOperatorDeclarations.append(try PrefixOperatorDeclaration.parse(parser: parser))
                continue
            } else if OperatorDeclaration.canParse(parser: parser) {
                operatorDeclarations.append(try OperatorDeclaration.parse(parser: parser))
                continue
            }
            
            throw ParserError.unexpectedToken(parser: parser, token: next)
        }
        
        let count = parser.source.distance(from: parser.source.startIndex, to: parser.source.endIndex)
        return TopLevelDeclaration(functionDeclarations: functionDeclarations, operatorDeclarations: operatorDeclarations, prefixOperatorDeclarations: prefixOperatorDeclarations, file: parser.file, location: 0..<count)
    }
}
