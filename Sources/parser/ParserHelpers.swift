//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation
import CheckedScanner

internal protocol ParserAcceptable<TokenType> {
    associatedtype TokenType: Token
    
    static var name: String { get }
    var description: String { get }
    
    func equals(other: some Token) -> Bool
}

extension ParserAcceptable {
    func equals(other: some Token) -> Bool {
        return TokenType.self == type(of: other)
    }
}

internal struct DotAcceptable: ParserAcceptable {
    typealias TokenType = DotToken
    
    static var name: String { return "dot" }
    var description: String { return "." }
}

extension ParserAcceptable where Self == DotAcceptable {
    static var dot: Self { DotAcceptable() }
}

internal struct CommaAcceptable: ParserAcceptable {
    typealias TokenType = CommaToken
    
    static var name: String { return "comma" }
    var description: String { return "," }
}

extension ParserAcceptable where Self == CommaAcceptable {
    static var comma: Self { CommaAcceptable() }
}

internal struct ColonAcceptable: ParserAcceptable {
    typealias TokenType = ColonToken
    
    static var name: String { return "colon" }
    var description: String { return ":" }
}

extension ParserAcceptable where Self == ColonAcceptable {
    static var colon: Self { ColonAcceptable() }
}

internal struct NewLineAcceptable: ParserAcceptable {
    typealias TokenType = NewLineToken
    
    static var name: String { return "statement termination" }
    var description: String { return "new line" }
}

extension ParserAcceptable where Self == NewLineAcceptable {
    static var newLine: Self { NewLineAcceptable() }
}

internal struct ArrowAcceptable: ParserAcceptable {
    typealias TokenType = ArrowToken
    
    static var name: String { return "arrow" }
    var description: String { return "->" }
}

extension ParserAcceptable where Self == ArrowAcceptable {
    static var arrow: Self { ArrowAcceptable() }
}

internal struct OpenParanAcceptable: ParserAcceptable {
    typealias TokenType = OpenParanToken
    
    static var name: String { return "parenthesis" }
    var description: String { return "(" }
}

extension ParserAcceptable where Self == OpenParanAcceptable {
    static var openParan: Self { OpenParanAcceptable() }
}

internal struct CloseParanAcceptable: ParserAcceptable {
    typealias TokenType = CloseParanToken
    
    static var name: String { return "parenthesis" }
    var description: String { return ")" }
}

extension ParserAcceptable where Self == CloseParanAcceptable {
    static var closeParan: Self { CloseParanAcceptable() }
}

internal struct OpenAngleBracketAcceptable: ParserAcceptable {
    typealias TokenType = OpenAngleBracketToken
    
    static var name: String { return "parenthesis" }
    var description: String { return "{" }
}

extension ParserAcceptable where Self == OpenAngleBracketAcceptable {
    static var openAngleBracket: Self { OpenAngleBracketAcceptable() }
}

internal struct CloseAngleBracketAcceptable: ParserAcceptable {
    typealias TokenType = CloseAngleBracketToken
    
    static var name: String { return "parenthesis" }
    var description: String { return "}" }
}

extension ParserAcceptable where Self == CloseAngleBracketAcceptable {
    static var closeAngleBracket: Self { CloseAngleBracketAcceptable() }
}

internal struct OperatorAcceptable: ParserAcceptable {
    typealias TokenType = OperatorToken
    
    var op: OperatorToken.Operator
    
    static var name: String { return "operator" }
    var description: String { return op.description }
    
    func equals(other: some Token) -> Bool {
        guard let other = other as? TokenType else {
            return false
        }
        
        return op == other.op
    }
}

extension ParserAcceptable where Self == OperatorAcceptable {
    static var plus: Self { OperatorAcceptable(op: .plus) }
    static var minus: Self { OperatorAcceptable(op: .minus) }
    static var times: Self { OperatorAcceptable(op: .times) }
    static var division: Self { OperatorAcceptable(op: .division) }
    static var not: Self { OperatorAcceptable(op: .not) }
    static var and: Self { OperatorAcceptable(op: .and) }
    static var or: Self { OperatorAcceptable(op: .or) }
    static var binaryAnd: Self { OperatorAcceptable(op: .binaryAnd) }
    static var binaryOr: Self { OperatorAcceptable(op: .binaryOr) }
    static var binaryXor: Self { OperatorAcceptable(op: .binaryXor) }
    static var equal: Self { OperatorAcceptable(op: .equal) }
    static var assignment: Self { OperatorAcceptable(op: .assignment) }
    static var modulo: Self { OperatorAcceptable(op: .modulo) }
    static var smaller: Self { OperatorAcceptable(op: .smaller) }
    static var smallerEqual: Self { OperatorAcceptable(op: .smallerEqual) }
    static var greater: Self { OperatorAcceptable(op: .greater) }
    static var greaterEqual: Self { OperatorAcceptable(op: .greaterEqual) }
}

internal struct KeywordAcceptable: ParserAcceptable {
    typealias TokenType = KeywordToken
    
    var keyword: KeywordToken.Keyword
    
    static var name: String { return "keyword" }
    var description: String { return keyword.rawValue }
    
    func equals(other: some Token) -> Bool {
        guard let other = other as? TokenType else {
            return false
        }
        
        return keyword == other.keyword
    }
}

extension ParserAcceptable where Self == KeywordAcceptable {
    static var `let`: Self { KeywordAcceptable(keyword: .let) }
    static var `var`: Self { KeywordAcceptable(keyword: .var) }
    static var `func`: Self { KeywordAcceptable(keyword: .func) }
    static var `_`: Self { KeywordAcceptable(keyword: ._) }
    static var `operator`: Self { KeywordAcceptable(keyword: .operator) }
    static var `if`: Self { KeywordAcceptable(keyword: .if) }
    static var `else`: Self { KeywordAcceptable(keyword: .else) }
    static var `prefix`: Self { KeywordAcceptable(keyword: .prefix) }
    static var `return`: Self { KeywordAcceptable(keyword: .return) }
    static var impure: Self { KeywordAcceptable(keyword: .impure) }
}
