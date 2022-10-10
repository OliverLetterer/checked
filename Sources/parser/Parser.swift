//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation
import CheckedScanner

public struct VariableDefinition: Equatable, Hashable {
    public var isMutable: Bool
    public var name: String
    public var type: TypeId
}

public enum ParserError: Error {
    case unexpectedEndOfFile(parser: Parser)
    case unexpectedToken(parser: Parser, token: any Token)
    case expectationFailed(parser: Parser, name: String, token: any Token, expected: String)
    case redeclaration(name: String, existing: SourceElement?, new: SourceElement)
    case unkownReference(name: String, reference: SourceElement)
    case expressionResultUnused(expression: Expression)
    case typeMissmatch(expected: TypeId, actual: TypeId, reference: SourceElement)
    case missingReturnStatement(reference: SourceElement)
    case blockDoesntReturnAnyValue(reference: SourceElement)
    case immutableExpressionAssignment(expression: Expression)
    case invalidMainDeclaration(main: FunctionDeclaration)
}

extension ParserError: SourceFileError {
    public var file: URL {
        switch self {
        case let .unexpectedEndOfFile(parser: parser), let .unexpectedToken(parser: parser, token: _), let .expectationFailed(parser: parser, name: _, token: _, expected: _):
            return parser.file
        case let .redeclaration(name: _, existing: _, new: sourceElement), let .unkownReference(name: _, reference: sourceElement), let .typeMissmatch(expected: _, actual: _, reference: sourceElement), let .missingReturnStatement(reference: sourceElement), let .blockDoesntReturnAnyValue(reference: sourceElement):
            return sourceElement.file
        case let .expressionResultUnused(expression: expression):
            return expression.file
        case let .immutableExpressionAssignment(expression: expression):
            return expression.file
        case let .invalidMainDeclaration(main: main):
            return main.file
        }
    }
    
    public var location: Range<Int> {
        switch self {
        case let .unexpectedEndOfFile(parser: parser):
            let count = parser.source.distance(from: parser.source.startIndex, to: parser.source.endIndex) - 1
            return count..<(count + 1)
        case let .unexpectedToken(parser: _, token: token):
            return token.location
        case let .expectationFailed(parser: _, name: _, token: token, expected: _):
            return token.location
        case let .redeclaration(name: _, existing: _, new: sourceElement):
            return sourceElement.location
        case let .unkownReference(name: _, reference: sourceElement):
            return sourceElement.location
        case let .expressionResultUnused(expression: expression):
            return expression.location
        case let .typeMissmatch(expected: _, actual: _, reference: sourceElement):
            return sourceElement.location
        case let .missingReturnStatement(reference: sourceElement):
            return sourceElement.location
        case let .blockDoesntReturnAnyValue(reference: sourceElement):
            return sourceElement.location
        case let .immutableExpressionAssignment(expression: expression):
            return expression.location
        case let .invalidMainDeclaration(main: main):
            return main.name.location
        }
    }
    
    public var failureReason: String {
        switch self {
        case .unexpectedEndOfFile(parser: _):
            return "unexpected end of file"
        case let .unexpectedToken(parser: _, token: token):
            return "unexpected token \(token.description)"
        case let .expectationFailed(parser: _, name: name, token: token, expected: value):
            return "expected \(name) \(value), found \(token.description)"
        case let .redeclaration(name: name, existing: previous, new: sourceElement):
            if let previous = previous {
                return "invalid redeclaration of \(name) \(sourceElement.content), previous declaration in \(previous.file.lastPathComponent):\(previous.sourceFileLocation.line):\(previous.sourceFileLocation.column)"
            } else {
                return "invalid redeclaration of \(name) \(sourceElement.content)"
            }
        case let .unkownReference(name: _, reference: sourceElement):
            return "unknown reference '\(sourceElement.content)'"
        case .expressionResultUnused(expression: _):
            return "expression result unused"
        case let .typeMissmatch(expected: expected, actual: actual, reference: _):
            return "expected type \(expected.description), found \(actual.description)"
        case .missingReturnStatement(reference: _):
            return "missing return statement"
        case .blockDoesntReturnAnyValue(reference: _):
            return "block does not return any value"
        case .immutableExpressionAssignment(expression: _):
            return "assignment to immutable value"
        case .invalidMainDeclaration(main: _):
            return "invalid main declaration"
        }
    }
}

protocol ParserState {
    func restoreState()
}

private struct _ParserState: ParserState {
    let parser: Parser
    let currentIndex: Int
    
    init(parser: Parser, currentIndex: Int) {
        self.parser = parser
        self.currentIndex = currentIndex
    }
    
    func restoreState() {
        parser.currentIndex = currentIndex
    }
}

public class Parser {
    internal let file: URL
    internal let source: String
    private let tokenStream: TokenStream
    
    fileprivate var currentIndex: Int
    
    private init(file: URL, source: String, tokenStream: TokenStream) {
        self.file = file
        self.source = source
        self.tokenStream = tokenStream
        
        currentIndex = 0
    }
    
    private func parse() throws -> TopLevelDeclaration {
        return try TopLevelDeclaration.parse(parser: self)
    }
    
    internal func saveState() -> ParserState {
        return _ParserState(parser: self, currentIndex: currentIndex)
    }
    
    internal func peek(offset: Int = 1) -> (any Token)? {
        guard (currentIndex + offset - 1) < tokenStream.tokens.count else {
            return nil
        }
        
        return tokenStream.tokens[currentIndex + offset - 1]
    }
    
    @discardableResult
    internal func drop() throws -> any Token {
        guard currentIndex < tokenStream.tokens.count else {
            throw ParserError.unexpectedEndOfFile(parser: self)
        }
        
        let token = tokenStream.tokens[currentIndex]
        currentIndex += 1
        return token
    }
    
    @discardableResult
    internal func accept(_ keyword: KeywordToken.Keyword) throws -> KeywordToken {
        guard let next = peek() else {
            throw ParserError.unexpectedEndOfFile(parser: self)
        }
        
        guard let keywordToken = next as? KeywordToken, keywordToken.keyword == keyword else {
            throw ParserError.expectationFailed(parser: self, name: "keyword", token: next, expected: keyword.rawValue)
        }
        
        try! drop()
        return keywordToken
    }
    
    @discardableResult
    internal func accept(_ op: OperatorToken.Operator) throws -> OperatorToken {
        guard let next = peek() else {
            throw ParserError.unexpectedEndOfFile(parser: self)
        }
        
        guard let opToken = next as? OperatorToken, opToken.op == op else {
            throw ParserError.expectationFailed(parser: self, name: "operator", token: next, expected: op.description)
        }
        
        try! drop()
        return opToken
    }
    
    @discardableResult
    internal func accept<TokenType: Token, Acceptable: ParserAcceptable<TokenType>>(_ value: Acceptable) throws -> TokenType {
        guard let next = peek() else {
            throw ParserError.unexpectedEndOfFile(parser: self)
        }
        
        guard let keywordToken = next as? TokenType else {
            throw ParserError.expectationFailed(parser: self, name: Acceptable.name, token: next, expected: value.description)
        }
        
        try! drop()
        return keywordToken
    }
    
    internal func matches(optional: [any ParserAcceptable] = [], required: any ParserAcceptable) -> Bool {
        var i = 1
        while let next = peek(offset: i) {
            if required.equals(other: next) {
                return true
            } else if optional.contains(where: { $0.equals(other: next) }) {
                i += 1
                continue
            } else {
                break
            }
        }
        
        return false
    }
    
    internal func matches(optional: [any ParserAcceptable] = [], required: [any ParserAcceptable]) -> Bool {
        guard required.count > 0 else {
            fatalError()
        }
        
        var offset = 1
        var accepted = 0
        while let next = peek(offset: offset) {
            if required[accepted].equals(other: next) {
                offset += 1
                accepted += 1
                
                if accepted == required.count {
                    return true
                }
            } else if optional.contains(where: { $0.equals(other: next) }) {
                offset += 1
                continue
            } else {
                break
            }
        }
        
        return false
    }
    
    public static func parse(file: URL) throws -> TopLevelDeclaration {
        guard let data = FileManager.default.contents(atPath: file.path), let string = String(data: data, encoding: .utf8) else {
            fatalError("File not found: \(file)")
        }
        
        let tokenStream = try CheckedScanner.parse(file: file)
        return try Parser(file: file, source: string, tokenStream: tokenStream).parse()
    }
}
