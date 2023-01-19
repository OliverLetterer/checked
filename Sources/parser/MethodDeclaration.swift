//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation
import CheckedScanner

public struct MethodDefinition: Hashable {
    public var name: String
    public var isImpure: Bool
    public var arguments: [FunctionDefinition.FunctionArgumentDefinition]
    public var returns: TypeId?
    
    init(name: String, isImpure: Bool, arguments: [FunctionDefinition.FunctionArgumentDefinition], returns: TypeId?) {
        self.name = name
        self.isImpure = isImpure
        self.arguments = arguments
        self.returns = returns
    }
    
    public func inferredReturnType(in context: Context) -> TypeId {
        if returns == nil {
            return context.moduleContext.typechecker!.buildIn.Void
        } else {
            return returns!
        }
    }
    
    public var equals: (MethodDefinition) -> Bool {
        return { name == $0.name && arguments == $0.arguments && returns == $0.returns }
    }
}

public struct MethodDeclaration: AST {
    public var name: FunctionDeclaration.NameDeclaration
    public var isImpure: Bool
    public var arguments: [FunctionDeclaration.FunctionArgumentDeclaration]
    public var returns: TypeReference?
    public var openAngleBracket: OpenAngleBracketToken
    public var statements: [Statement]
    public var closeAngleBracket: CloseAngleBracketToken
    public var checked: InferredType<MethodId>
    public var file: URL
    public var location: Range<Int>
    
    init(name: FunctionDeclaration.NameDeclaration, isImpure: Bool, arguments: [FunctionDeclaration.FunctionArgumentDeclaration], returns: TypeReference?, openAngleBracket: OpenAngleBracketToken, statements: [Statement], closeAngleBracket: CloseAngleBracketToken, checked: InferredType<MethodId>, file: URL, location: Range<Int>) {
        self.name = name
        self.isImpure = isImpure
        self.arguments = arguments
        self.returns = returns
        self.openAngleBracket = openAngleBracket
        self.statements = statements
        self.closeAngleBracket = closeAngleBracket
        self.checked = checked
        self.file = file
        self.location = location
    }
    
    public var functionDefinition: MethodDefinition {
        return MethodDefinition(name: name.name, isImpure: isImpure, arguments: arguments.map(\.argumentDefinition), returns: returns?.checked.typeId)
    }
    
    public var description: String {
        return """
        \(type(of: self))
        - name: \(name.name)
        - isImpure: \(isImpure)
        - arguments:
        \(arguments.map(\.description).map({ $0.withIndent(4) }).joined(separator: "\n"))
        - returns: \(returns?.description ?? "Void")
        - statements:
        \(statements.map(\.description).map({ $0.withIndent(4) }).joined(separator: "\n"))
        """
    }
}

extension MethodDeclaration {
    public static func canParse(parser: Parser) -> Bool {
        return parser.matches(optional: [ .impure ], required: .func)
    }
    
    public static func parse(parser: Parser) throws -> MethodDeclaration {
        var modifiers: Set<KeywordToken.Keyword> = []
        
        while let keyword = parser.peek() as? KeywordToken, keyword.keyword != .func {
            guard !modifiers.contains(keyword.keyword) else {
                throw ParserError.modifierRedeclaration(keyword: keyword)
            }
            
            modifiers.insert(keyword.keyword)
            try! parser.drop()
        }
        
        let first = try parser.accept(.func)
        
        guard let name = parser.peek() else {
            throw ParserError.unexpectedEndOfFile(parser: parser)
        }
        
        guard let name = name as? IdentifierToken else {
            throw ParserError.unexpectedToken(parser: parser, token: name)
        }
        
        try! parser.drop()
        
        try parser.accept(.openParan)
        
        var arguments: [FunctionDeclaration.FunctionArgumentDeclaration] = []
        while let argumentsStart = parser.peek() {
            if arguments.count > 0 {
                if argumentsStart is CloseParanToken {
                    break
                } else if argumentsStart is CommaToken {
                    try! parser.drop()
                    arguments.append(try FunctionDeclaration.FunctionArgumentDeclaration.parse(parser: parser))
                } else {
                    throw ParserError.unexpectedToken(parser: parser, token: argumentsStart)
                }
            } else {
                if argumentsStart is CloseParanToken {
                    break
                }
                
                arguments.append(try FunctionDeclaration.FunctionArgumentDeclaration.parse(parser: parser))
            }
        }
        
        try parser.accept(.closeParan)
        
        let returns: TypeReference?
        if parser.matches(required: .arrow) {
            try! parser.accept(.arrow)
            returns = try TypeReference.parse(parser: parser)
        } else {
            returns = nil
        }
        
        let openAngleBracket = try parser.accept(.openAngleBracket)
        
        let statements: [Statement] = try [Statement].parse(parser: parser)
        let closeAngleBracket = try parser.accept(.closeAngleBracket)
        return MethodDeclaration(name: FunctionDeclaration.NameDeclaration(name: name.identifier, file: parser.file, location: name.location), isImpure: modifiers.contains(.impure), arguments: arguments, returns: returns, openAngleBracket: openAngleBracket, statements: statements, closeAngleBracket: closeAngleBracket, checked: .unresolved, file: parser.file, location: first.location.lowerBound..<closeAngleBracket.location.upperBound)
    }
}
