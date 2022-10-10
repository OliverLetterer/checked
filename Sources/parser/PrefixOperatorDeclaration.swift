//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation
import CheckedScanner

public struct PrefixOperatorDefinition: Equatable, Hashable {
    public var op: OperatorToken.Operator
    public var argument: FunctionDefinition.FunctionArgumentDefinition
    public var returns: TypeId
    
    public var equals: (PrefixOperatorDefinition) -> Bool {
        return { op == $0.op && argument == $0.argument && returns == $0.returns }
    }
}

public struct PrefixOperatorDeclaration: AST {
    public var prefixToken: KeywordToken
    public var operatorToken: KeywordToken
    public var op: OperatorToken
    public var argument: FunctionDeclaration.FunctionArgumentDeclaration
    public var returns: TypeReference
    public var openAngleBracket: OpenAngleBracketToken
    public var statements: [Statement]
    public var closeAngleBracket: CloseAngleBracketToken
    public var checked: InferredType<PrefixOperatorId>
    public var file: URL
    public var location: Range<Int>
    
    init(prefixToken: KeywordToken, operatorToken: KeywordToken, op: OperatorToken, argument: FunctionDeclaration.FunctionArgumentDeclaration, returns: TypeReference, openAngleBracket: OpenAngleBracketToken, statements: [Statement], closeAngleBracket: CloseAngleBracketToken, checked: InferredType<PrefixOperatorId>, file: URL, location: Range<Int>) {
        self.prefixToken = prefixToken
        self.operatorToken = operatorToken
        self.op = op
        self.argument = argument
        self.returns = returns
        self.openAngleBracket = openAngleBracket
        self.statements = statements
        self.closeAngleBracket = closeAngleBracket
        self.checked = checked
        self.file = file
        self.location = location
    }
    
    public var operatorDefinition: PrefixOperatorDefinition {
        return PrefixOperatorDefinition(op: op.op, argument: argument.argumentDefinition, returns: returns.checked.typeId)
    }
    
    public var description: String {
        return """
        \(type(of: self))
        - operator: \(op.op.description)
        - argument:
        \(argument.description.withIndent(4))
        - returns: \(returns.description)
        - statements:
        \(statements.map(\.description).map({ $0.withIndent(4) }).joined(separator: "\n"))
        """
    }
}

extension PrefixOperatorDeclaration {
    public static func canParse(parser: Parser) -> Bool {
        return parser.matches(required: [ .prefix, .operator ])
    }
    
    public static func parse(parser: Parser) throws -> PrefixOperatorDeclaration {
        let prefixToken = try parser.accept(.prefix)
        let operatorToken = try parser.accept(.operator)
        
        guard let next = parser.peek() else {
            throw ParserError.unexpectedEndOfFile(parser: parser)
        }
        
        guard let op = next as? OperatorToken, op.op.isPrefixOperator else {
            throw ParserError.unexpectedToken(parser: parser, token: next)
        }
        
        try! parser.drop()
        try parser.accept(.openParan)
        
        let state = parser.saveState()
        let argument = try FunctionDeclaration.FunctionArgumentDeclaration.parse(parser: parser)
        
        guard argument.isAnonymous else {
            state.restoreState()
            throw ParserError.unexpectedToken(parser: parser, token: parser.peek()!)
        }
        
        try parser.accept(.closeParan)
        try parser.accept(.arrow)
        let returns = try TypeReference.parse(parser: parser)
        
        let openAngleBracket = try parser.accept(.openAngleBracket)
        
        let statements: [Statement] = try [Statement].parse(parser: parser)
        let closeAngleBracket = try parser.accept(.closeAngleBracket)
        return PrefixOperatorDeclaration(prefixToken: prefixToken, operatorToken: operatorToken, op: op, argument: argument, returns: returns, openAngleBracket: openAngleBracket, statements: statements, closeAngleBracket: closeAngleBracket, checked: .unresolved, file: parser.file, location: prefixToken.location.lowerBound..<closeAngleBracket.location.upperBound)
    }
}
