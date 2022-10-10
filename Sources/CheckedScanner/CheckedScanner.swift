//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

public struct TokenStream {
    public var file: URL
    public var tokens: [any Token]
}

public enum CheckedScannerError: Error, SourceFileError {
    case unexpectedEndOfFile(scanner: CheckedScanner)
    case unexpectedCharacter(scanner: CheckedScanner, location: Int)
    case noNewLineAtEndOfFile(scanner: CheckedScanner)
    
    public var file: URL {
        switch self {
        case let .unexpectedEndOfFile(scanner: scanner), let .unexpectedCharacter(scanner: scanner, location: _), let .noNewLineAtEndOfFile(scanner: scanner):
            return scanner.file
        }
    }
    
    public var location: Range<Int> {
        switch self {
        case let .unexpectedEndOfFile(scanner: scanner), let .noNewLineAtEndOfFile(scanner: scanner):
            let count = scanner.source.distance(from: scanner.source.startIndex, to: scanner.source.endIndex) - 1
            return count..<(count + 1)
        case let .unexpectedCharacter(scanner: _, location: location):
            return location..<(location + 1)
        }
    }
    
    public var failureReason: String {
        switch self {
        case .unexpectedEndOfFile:
            return "unexpected end of file"
        case .unexpectedCharacter:
            return "unexpected character \"\(content)\""
        case .noNewLineAtEndOfFile:
            return "no new line at end of file"
        }
    }
}

private extension OperatorToken.Operator {
    init?(character: Character) {
        switch character {
        case "+": self = .plus
        case "-": self = .minus
        case "*": self = .times
        case "/": self = .division
        case "!": self = .not
        case "&": self = .binaryAnd
        case "|": self = .binaryOr
        case "^": self = .binaryXor
        case "%": self = .modulo
        case "=": self = .assignment
        case "<": self = .smaller
        case ">": self = .greater
        default: return nil
        }
    }
}

public class CheckedScanner {
    fileprivate let file: URL
    fileprivate let source: String
    private var currentIndex: (number: Int, index: String.Index)
    
    private init(file: URL, source: String) {
        self.file = file
        self.source = source
        self.currentIndex = (0, source.startIndex)
    }
    
    private func parse() throws -> TokenStream {
        var tokens: [any Token] = []
        
        let identifierStarts: String = "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        
        while let current = peek() {
            if false {
                
            } else if current == "\n" {
                tokens.append(NewLineToken(file: file, location: currentIndex.number..<(currentIndex.number + 1)))
                try! drop()
            } else if current.isWhitespace {
                try! drop()
            } else if identifierStarts.contains(current) {
                tokens.append(try parseIdentifier())
            } else if current == "." {
                tokens.append(DotToken(file: file, location: currentIndex.number..<(currentIndex.number + 1)))
                try! drop()
            } else if current == ":" {
                tokens.append(ColonToken(file: file, location: currentIndex.number..<(currentIndex.number + 1)))
                try! drop()
            } else if current == "," {
                tokens.append(CommaToken(file: file, location: currentIndex.number..<(currentIndex.number + 1)))
                try! drop()
            } else if current == "(" {
                tokens.append(OpenParanToken(file: file, location: currentIndex.number..<(currentIndex.number + 1)))
                try! drop()
            } else if current == ")" {
                tokens.append(CloseParanToken(file: file, location: currentIndex.number..<(currentIndex.number + 1)))
                try! drop()
            } else if current == "{" {
                tokens.append(OpenAngleBracketToken(file: file, location: currentIndex.number..<(currentIndex.number + 1)))
                try! drop()
            } else if current == "}" {
                tokens.append(CloseAngleBracketToken(file: file, location: currentIndex.number..<(currentIndex.number + 1)))
                try! drop()
            } else if let op = OperatorToken.Operator(character: current), op == .minus {
                func operatorToken() {
                    tokens.append(OperatorToken(op: op, file: file, location: currentIndex.number..<(currentIndex.number + 1)))
                    try! drop()
                }
                
                if let nextCharacter = peek(offset: 2) {
                    if nextCharacter.isNumber {
                        tokens.append(try parseNumberLiteral())
                    } else if let next = OperatorToken.Operator(character: nextCharacter), next == .greater {
                        tokens.append(ArrowToken(file: file, location: currentIndex.number..<(currentIndex.number + 2)))
                        try! drop()
                        try! drop()
                    } else {
                        operatorToken()
                    }
                } else {
                    operatorToken()
                }
            } else if current.isNumber {
                tokens.append(try parseNumberLiteral())
            } else if current == "\"" {
                tokens.append(try parseStringLiteral())
            } else if let op = OperatorToken.Operator(character: current) {
                tokens.append(OperatorToken(op: op, file: file, location: currentIndex.number..<(currentIndex.number + 1)))
                try! drop()
            } else {
                throw CheckedScannerError.unexpectedCharacter(scanner: self, location: currentIndex.number)
            }
        }
        
        if tokens.count > 0 {
            var index = 0
            while index < tokens.count - 1 {
                if let current = tokens[index] as? OperatorToken, let next = tokens[index + 1] as? OperatorToken, current.location.upperBound == next.location.lowerBound {
                    switch (current.op, next.op) {
                    case (.binaryAnd, .binaryAnd):
                        tokens[index] = OperatorToken(op: .and, file: current.file, location: current.location.lowerBound..<next.location.upperBound)
                        tokens.remove(at: index + 1)
                    case (.binaryOr, .binaryOr):
                        tokens[index] = OperatorToken(op: .or, file: current.file, location: current.location.lowerBound..<next.location.upperBound)
                        tokens.remove(at: index + 1)
                    case (.assignment, .assignment):
                        tokens[index] = OperatorToken(op: .equal, file: current.file, location: current.location.lowerBound..<next.location.upperBound)
                        tokens.remove(at: index + 1)
                    case (.smaller, .assignment):
                        tokens[index] = OperatorToken(op: .smallerEqual, file: current.file, location: current.location.lowerBound..<next.location.upperBound)
                        tokens.remove(at: index + 1)
                    case (.greater, .assignment):
                        tokens[index] = OperatorToken(op: .greaterEqual, file: current.file, location: current.location.lowerBound..<next.location.upperBound)
                        tokens.remove(at: index + 1)
                    default:
                        break
                    }
                }
                
                index += 1
            }
        }
        
        guard tokens.last is NewLineToken else {
            throw CheckedScannerError.noNewLineAtEndOfFile(scanner: self)
        }
        
        return TokenStream(file: file, tokens: tokens)
    }
    
    private func parseNumberLiteral() throws -> any Token {
        var buffer: String = String()
        var isNegative: Bool = false
        var hasComma: Bool = false
        
        let start = currentIndex.number
        
        while let current = peek() {
            if current == "-" {
                guard !isNegative else {
                    throw CheckedScannerError.unexpectedCharacter(scanner: self, location: currentIndex.number)
                }
                
                isNegative = true
                buffer.append(current)
                try! drop()
            } else if current == ".", let next = peek(offset: 2), next.isNumber {
                guard !hasComma else {
                    throw CheckedScannerError.unexpectedCharacter(scanner: self, location: currentIndex.number)
                }
                
                hasComma = true
                buffer.append(current)
                buffer.append(next)
                try! drop()
                try! drop()
            } else if current == "_" {
                buffer.append(current)
                try! drop()
            } else if current.isNumber {
                buffer.append(current)
                try! drop()
            } else {
                break
            }
        }
        
        guard buffer.count > 0 else {
            throw CheckedScannerError.unexpectedEndOfFile(scanner: self)
        }
        
        let end = currentIndex.number
        
        if hasComma {
            return FloatingPointLiteralToken(literal: buffer, file: file, location: start..<end)
        } else {
            return IntegerLiteralToken(literal: buffer, file: file, location: start..<end)
        }
    }
    
    private func parseIdentifier() throws -> any Token {
        var buffer: String = String()
        
        let start = currentIndex.number
        
        let breakingCharacters: String = OperatorToken.Operator.allCases.filter({ $0.description.count == 1 }).map(\.description).joined(separator: "") + "(){}.,:; \n"
        
        while let current = peek() {
            if breakingCharacters.contains(current) {
                break
            } else {
                buffer.append(current)
                try! drop()
            }
        }
        
        guard buffer.count > 0 else {
            throw CheckedScannerError.unexpectedEndOfFile(scanner: self)
        }
        
        let end = currentIndex.number
        
        if let keyword = KeywordToken.Keyword(rawValue: buffer) {
            return KeywordToken(keyword: keyword, file: file, location: start..<end)
        } else if buffer == "true" {
            return BooleanLiteralToken(literal: true, file: file, location: start..<end)
        } else if buffer == "false" {
            return BooleanLiteralToken(literal: false, file: file, location: start..<end)
        } else {
            return IdentifierToken(identifier: buffer, file: file, location: start..<end)
        }
    }
    
    private func parseStringLiteral() throws -> any Token {
        guard let first = peek() else {
            throw CheckedScannerError.unexpectedEndOfFile(scanner: self)
        }
        
        guard first == "\"" else {
            throw CheckedScannerError.unexpectedCharacter(scanner: self, location: currentIndex.number)
        }
        
        var buffer: String = String()
        var hasEnd: Bool = false
        
        let start = currentIndex.number
        try! drop()

        while let current = peek() {
            if current == "\\", let next = peek(offset: 2) {
                switch next {
                case "0": buffer.append("\0")
                case "t": buffer.append("\t")
                case "n": buffer.append("\n")
                case "r": buffer.append("\r")
                case "e": buffer.append("\u{001B}")
                case "\"": buffer.append("\"")
                case "\n": buffer.append("\n")
                default: throw CheckedScannerError.unexpectedCharacter(scanner: self, location: currentIndex.number + 1)
                }
                
                try! drop()
                try! drop()
            } else if current == "\n" {
                throw CheckedScannerError.unexpectedCharacter(scanner: self, location: currentIndex.number)
            } else if current == "\"" {
                hasEnd = true
                try! drop()
                break
            } else {
                buffer.append(current)
                try! drop()
            }
        }

        guard hasEnd else {
            throw CheckedScannerError.unexpectedEndOfFile(scanner: self)
        }

        let end = currentIndex.number
        return StringLiteralToken(literal: buffer, file: file, location: start..<end)
    }
    
    private func drop() throws {
        guard currentIndex.index < source.endIndex else {
            throw CheckedScannerError.unexpectedEndOfFile(scanner: self)
        }
        
        currentIndex.number += 1
        currentIndex.index = source.index(after: currentIndex.index)
    }
    
    private func peek(offset: Int = 1) -> Character? {
        let index = source.index(currentIndex.index, offsetBy: offset - 1)
        guard index < source.endIndex else {
            return nil
        }
        
        return source[index]
    }
    
    public static func parse(file: URL) throws -> TokenStream {
        guard let data = FileManager.default.contents(atPath: file.path), let string = String(data: data, encoding: .utf8) else {
            fatalError("File not found: \(file)")
        }
        
        return try CheckedScanner(file: file, source: string).parse()
    }
}
