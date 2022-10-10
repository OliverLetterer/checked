//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation
import CheckedScanner

public struct FunctionDefinition: Hashable {
    public struct FunctionArgumentDefinition: Equatable, Hashable {
        public var name: String?
        public var typeReference: TypeId
    }
    
    public var name: String
    public var arguments: [FunctionArgumentDefinition]
    public var returns: TypeId?
    
    init(name: String, arguments: [FunctionArgumentDefinition], returns: TypeId?) {
        self.name = name
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
    
    public var equals: (FunctionDefinition) -> Bool {
        return { name == $0.name && arguments == $0.arguments && returns == $0.returns }
    }
}

public struct FunctionDeclaration: AST {
    public struct NameDeclaration: SourceElement {
        public var name: String
        public var file: URL
        public var location: Range<Int>
    }
    
    public struct FunctionArgumentDeclaration: AST {
        public var isAnonymous: Bool
        public var name: String
        public var typeReference: TypeReference
        public var file: URL
        public var location: Range<Int>
        
        init(isAnonymous: Bool, name: String, typeReference: TypeReference, file: URL, location: Range<Int>) {
            self.isAnonymous = isAnonymous
            self.name = name
            self.typeReference = typeReference
            self.file = file
            self.location = location
        }
        
        public var argumentDefinition: FunctionDefinition.FunctionArgumentDefinition {
            return FunctionDefinition.FunctionArgumentDefinition(name: isAnonymous ? nil : name, typeReference: typeReference.checked.typeId)
        }
        
        public var description: String {
            return """
            \(type(of: self))
            - isAnonymous: \(isAnonymous)
            - name: \(name)
            - typeReference: \(typeReference.description)
            """
        }
    }
    
    public var name: NameDeclaration
    public var arguments: [FunctionArgumentDeclaration]
    public var returns: TypeReference?
    public var openAngleBracket: OpenAngleBracketToken
    public var statements: [Statement]
    public var closeAngleBracket: CloseAngleBracketToken
    public var checked: InferredType<FunctionId>
    public var file: URL
    public var location: Range<Int>
    
    init(name: NameDeclaration, arguments: [FunctionArgumentDeclaration], returns: TypeReference?, openAngleBracket: OpenAngleBracketToken, statements: [Statement], closeAngleBracket: CloseAngleBracketToken, checked: InferredType<FunctionId>, file: URL, location: Range<Int>) {
        self.name = name
        self.arguments = arguments
        self.returns = returns
        self.openAngleBracket = openAngleBracket
        self.statements = statements
        self.closeAngleBracket = closeAngleBracket
        self.checked = checked
        self.file = file
        self.location = location
    }
    
    public var functionDefinition: FunctionDefinition {
        return FunctionDefinition(name: name.name, arguments: arguments.map(\.argumentDefinition), returns: returns?.checked.typeId)
    }
    
    public var description: String {
        return """
        \(type(of: self))
        - name: \(name.name)
        - arguments:
        \(arguments.map(\.description).map({ $0.withIndent(4) }).joined(separator: "\n"))
        - returns: \(returns?.description ?? "Void")
        - statements:
        \(statements.map(\.description).map({ $0.withIndent(4) }).joined(separator: "\n"))
        """
    }
}

extension Array where Element == Statement {
    public static func parse(parser: Parser) throws -> [Statement] {
        var statements: [Statement] = []
        while let next = parser.peek() {
            if next is NewLineToken {
                try! parser.drop()
                continue
            } else if next is CloseAngleBracketToken {
                break
            }
            
            statements.append(try Statement.parse(parser: parser))
        }
        
        return statements
    }
}

extension FunctionDeclaration {
    public static func canParse(parser: Parser) -> Bool {
        return parser.matches(required: .func)
    }
    
    public static func parse(parser: Parser) throws -> FunctionDeclaration {
        let first = try parser.accept(.func)
        
        guard let name = parser.peek() else {
            throw ParserError.unexpectedEndOfFile(parser: parser)
        }
        
        guard let name = name as? IdentifierToken else {
            throw ParserError.unexpectedToken(parser: parser, token: name)
        }
        
        try! parser.drop()
        
        try parser.accept(.openParan)
        
        var arguments: [FunctionArgumentDeclaration] = []
        while let argumentsStart = parser.peek() {
            if arguments.count > 0 {
                if argumentsStart is CloseParanToken {
                    break
                } else if argumentsStart is CommaToken {
                    try! parser.drop()
                    arguments.append(try FunctionArgumentDeclaration.parse(parser: parser))
                } else {
                    throw ParserError.unexpectedToken(parser: parser, token: argumentsStart)
                }
            } else {
                if argumentsStart is CloseParanToken {
                    break
                }
                
                arguments.append(try FunctionArgumentDeclaration.parse(parser: parser))
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
        return FunctionDeclaration(name: NameDeclaration(name: name.identifier, file: parser.file, location: name.location), arguments: arguments, returns: returns, openAngleBracket: openAngleBracket, statements: statements, closeAngleBracket: closeAngleBracket, checked: .unresolved, file: parser.file, location: first.location.lowerBound..<closeAngleBracket.location.upperBound)
    }
}

extension FunctionDeclaration.FunctionArgumentDeclaration {
    public static func canParse(parser: Parser) -> Bool {
        return parser.matches(required: ._) || parser.peek() is IdentifierToken
    }
    
    public static func parse(parser: Parser) throws -> FunctionDeclaration.FunctionArgumentDeclaration {
        guard let first = parser.peek() else {
            throw ParserError.unexpectedEndOfFile(parser: parser)
        }
        
        let isAnonymous: Bool
        if let keyword = first as? KeywordToken, keyword.keyword == ._ {
            isAnonymous = true
            try! parser.drop()
        } else {
            isAnonymous = false
        }
        
        guard let name = parser.peek() else {
            throw ParserError.unexpectedEndOfFile(parser: parser)
        }
        
        guard let name = name as? IdentifierToken else {
            throw ParserError.unexpectedToken(parser: parser, token: name)
        }
        
        try! parser.drop()
        try parser.accept(.colon)
        let typeReference = try TypeReference.parse(parser: parser)
        
        return FunctionDeclaration.FunctionArgumentDeclaration(isAnonymous: isAnonymous, name: name.identifier, typeReference: typeReference, file: parser.file, location: first.location.lowerBound..<typeReference.location.upperBound)
    }
}
