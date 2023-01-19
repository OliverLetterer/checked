//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation
import CheckedScanner

public struct OperatorDefinition: Equatable, Hashable {
    public var op: OperatorToken.Operator
    public var isImpure: Bool
    public var lhs: FunctionDefinition.FunctionArgumentDefinition
    public var rhs: FunctionDefinition.FunctionArgumentDefinition
    public var returns: TypeId
    
    public var equals: (OperatorDefinition) -> Bool {
        return { op == $0.op && lhs == $0.lhs && rhs == $0.rhs && returns == $0.returns }
    }
}

public struct OperatorDeclaration: AST {
    public var operatorToken: KeywordToken
    public var op: OperatorToken
    public var isImpure: Bool
    public var lhs: FunctionDeclaration.FunctionArgumentDeclaration
    public var rhs: FunctionDeclaration.FunctionArgumentDeclaration
    public var returns: TypeReference
    public var openAngleBracket: OpenAngleBracketToken
    public var statements: [Statement]
    public var closeAngleBracket: CloseAngleBracketToken
    public var checked: InferredType<OperatorId>
    public var file: URL
    public var location: Range<Int>
    
    init(operatorToken: KeywordToken, op: OperatorToken, isImpure: Bool, lhs: FunctionDeclaration.FunctionArgumentDeclaration, rhs: FunctionDeclaration.FunctionArgumentDeclaration, returns: TypeReference, openAngleBracket: OpenAngleBracketToken, statements: [Statement], closeAngleBracket: CloseAngleBracketToken, checked: InferredType<OperatorId>, file: URL, location: Range<Int>) {
        self.operatorToken = operatorToken
        self.op = op
        self.isImpure = isImpure
        self.lhs = lhs
        self.rhs = rhs
        self.returns = returns
        self.openAngleBracket = openAngleBracket
        self.statements = statements
        self.closeAngleBracket = closeAngleBracket
        self.checked = checked
        self.file = file
        self.location = location
    }
    
    public var operatorDefinition: OperatorDefinition {
        return OperatorDefinition(op: op.op, isImpure: isImpure, lhs: lhs.argumentDefinition, rhs: rhs.argumentDefinition, returns: returns.checked.typeId)
    }
    
    public var description: String {
        return """
        \(type(of: self))
        - operator: \(op.op.description)
        - isImpure: \(isImpure)
        - lhs:
        \(lhs.description.withIndent(4))
        - rhs:
        \(rhs.description.withIndent(4))
        - returns: \(returns.description)
        - statements:
        \(statements.map(\.description).map({ $0.withIndent(4) }).joined(separator: "\n"))
        """
    }
}

extension OperatorDeclaration {
    public static func canParse(parser: Parser) -> Bool {
        return parser.matches(optional: [ .impure ], required: [ .operator ])
    }
    
    public static func parse(parser: Parser) throws -> OperatorDeclaration {
        var modifiers: Set<KeywordToken.Keyword> = []
        
        while let keyword = parser.peek() as? KeywordToken, keyword.keyword != .operator {
            guard !modifiers.contains(keyword.keyword) else {
                throw ParserError.modifierRedeclaration(keyword: keyword)
            }
            
            modifiers.insert(keyword.keyword)
            try! parser.drop()
        }
        
        let operatorToken = try parser.accept(.operator)
        
        guard let next = parser.peek() else {
            throw ParserError.unexpectedEndOfFile(parser: parser)
        }
        
        guard let op = next as? OperatorToken, op.op.isInfixOperator else {
            throw ParserError.unexpectedToken(parser: parser, token: next)
        }
        
        try! parser.drop()
        try parser.accept(.openParan)
        
        let lhsState = parser.saveState()
        let lhs = try FunctionDeclaration.FunctionArgumentDeclaration.parse(parser: parser)
        
        guard lhs.isAnonymous else {
            lhsState.restoreState()
            throw ParserError.unexpectedToken(parser: parser, token: parser.peek()!)
        }
        
        try parser.accept(.comma)
        
        let rhsState = parser.saveState()
        let rhs = try FunctionDeclaration.FunctionArgumentDeclaration.parse(parser: parser)
        
        guard rhs.isAnonymous else {
            rhsState.restoreState()
            throw ParserError.unexpectedToken(parser: parser, token: parser.peek()!)
        }
        
        try parser.accept(.closeParan)
        try parser.accept(.arrow)
        let returns = try TypeReference.parse(parser: parser)
        
        let openAngleBracket = try parser.accept(.openAngleBracket)
        
        let statements: [Statement] = try [Statement].parse(parser: parser)
        let closeAngleBracket = try parser.accept(.closeAngleBracket)
        return OperatorDeclaration(operatorToken: operatorToken, op: op, isImpure: modifiers.contains(.impure), lhs: lhs, rhs: rhs, returns: returns, openAngleBracket: openAngleBracket, statements: statements, closeAngleBracket: closeAngleBracket, checked: .unresolved, file: parser.file, location: operatorToken.location.lowerBound..<closeAngleBracket.location.upperBound)
    }
}
