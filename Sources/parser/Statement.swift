//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation
import CheckedScanner

public enum Statement: AST {
    case expression(Expression)
    case returnStatement(expression: Expression?, file: URL, location: Range<Int>)
    case variableDeclaration(isMutable: Bool, name: IdentifierToken, typeReference: TypeReference?, expression: Expression, file: URL, location: Range<Int>)
    case ifStatement(conditions: [Expression], statements: [Statement], elseIfs: [(conditions: [Expression], statements: [Statement])]?, elseStatements: [Statement]?, file: URL, location: Range<Int>)
    case variableIfDeclaration(isMutable: Bool, name: IdentifierToken, typeReference: TypeReference?, checked: InferredType<TypeId>, conditions: [Expression], statements: [Statement], elseIfs: [(conditions: [Expression], statements: [Statement])]?, elseStatements: [Statement], file: URL, location: Range<Int>)
    case assignmentStatement(lhs: Expression, rhs: Expression, file: URL, location: Range<Int>)
    case returnIfStatement(checked: InferredType<TypeId>, conditions: [Expression], statements: [Statement], elseIfs: [(conditions: [Expression], statements: [Statement])]?, elseStatements: [Statement], file: URL, location: Range<Int>)
    
    public var file: URL {
        switch self {
        case let .expression(expression):
            return expression.file
        case let .returnStatement(expression: _, file: file, location: _), let .variableDeclaration(isMutable: _, name: _, typeReference: _, expression: _, file: file, location: _), let .ifStatement(conditions: _, statements: _, elseIfs: _, elseStatements: _, file: file, location: _), let .variableIfDeclaration(isMutable: _, name: _, typeReference: _, checked: _, conditions: _, statements: _, elseIfs: _, elseStatements: _, file: file, location: _), let .assignmentStatement(lhs: _, rhs: _, file: file, location: _), let .returnIfStatement(checked: _, conditions: _, statements: _, elseIfs: _, elseStatements: _, file: file, location: _):
            return file
        }
    }
    
    public var location: Range<Int> {
        switch self {
        case let .expression(expression):
            return expression.location
        case let .returnStatement(expression: _, file: _, location: location), let .variableDeclaration(isMutable: _, name: _, typeReference: _, expression: _, file: _, location: location), let .ifStatement(conditions: _, statements: _, elseIfs: _, elseStatements: _, file: _, location: location), let .variableIfDeclaration(isMutable: _, name: _, typeReference: _, checked: _, conditions: _, statements: _, elseIfs: _, elseStatements: _, file: _, location: location), let .assignmentStatement(lhs: _, rhs: _, file: _, location: location), let .returnIfStatement(checked: _, conditions: _, statements: _, elseIfs: _, elseStatements: _, file: _, location: location):
            return location
        }
    }
    
    public var description: String {
        switch self {
        case let .expression(expression):
            return """
            ExpressionStatement
            \(expression.description.withIndent(4))
            """
        case let .returnStatement(expression: expression, file: _, location: _):
            if let expression = expression {
                return """
                ReturnStatement
                \(expression.description.withIndent(4))
                """
            } else {
                return """
                ReturnStatement
                """
            }
        case let .variableDeclaration(isMutable: isMutable, name: name, typeReference: typeReference, expression: expression, file: _, location: _):
            return """
            VariableDeclaration
            - isMutable: \(isMutable)
            - name: \(name.identifier)
            - typeReference: \(typeReference?.name ?? "")
            - expression
            \(expression.description.withIndent(4))
            """
        case let .ifStatement(conditions: conditions, statements: statements, elseIfs: elseIfs, elseStatements: elseStatements, file: _, location: _):
            var components: [String] = []
            components.append("""
            IfStatement
            - conditions
            \(conditions.map(\.description).joined(separator: "\n").withIndent(4))
            - statements
            \(statements.map(\.description).joined(separator: "\n").withIndent(4))
            """)
            
            if let elseIfs = elseIfs {
                elseIfs.forEach { elseIf in
                    let (conditions, statements) = elseIf
                    
                    components.append("""
                    ElseIfStatement
                    - conditions
                    \(conditions.map(\.description).joined(separator: "\n").withIndent(4))
                    - statements
                    \(statements.map(\.description).joined(separator: "\n").withIndent(4))
                    """)
                }
            }
            
            if let elseStatements = elseStatements {
                components.append("""
                ElseStatement
                - statements
                \(elseStatements.map(\.description).joined(separator: "\n").withIndent(4))
                """)
            }
            
            return components.joined(separator: "\n")
        case let .variableIfDeclaration(isMutable: isMutable, name: name, typeReference: typeReference, checked: _, conditions: conditions, statements: statements, elseIfs: elseIfs, elseStatements: elseStatements, file: _, location: _):
            var components: [String] = []
            components.append("""
            VariableIfDeclaration
            - isMutable: \(isMutable)
            - name: \(name.identifier)
            - typeReference: \(typeReference?.name ?? "")
            IfStatement
            - conditions
            \(conditions.map(\.description).map({ $0.withIndent(4) }).joined(separator: "\n"))
            - statements
            \(statements.map(\.description).map({ $0.withIndent(4) }).joined(separator: "\n"))
            """)
            
            if let elseIfs = elseIfs {
                elseIfs.forEach { elseIf in
                    let (conditions, statements) = elseIf
                    
                    components.append("""
                    ElseIfStatement
                    - conditions
                    \(conditions.map(\.description).joined(separator: "\n").withIndent(4))
                    - statements
                    \(statements.map(\.description).joined(separator: "\n").withIndent(4))
                    """)
                }
            }
            
            components.append("""
            ElseStatement
            - statements
            \(elseStatements.map(\.description).joined(separator: "\n").withIndent(4))
            """)
            
            return components.joined(separator: "\n")
        case let .assignmentStatement(lhs: lhs, rhs: rhs, file: _, location: _):
            return """
            AssignmentStatement
            - lhs
            \(lhs.description.withIndent(4))
            - rhs
            \(rhs.description.withIndent(4))
            """
        case let .returnIfStatement(checked: _, conditions: conditions, statements: statements, elseIfs: elseIfs, elseStatements: elseStatements, file: _, location: _):
            var components: [String] = []
            components.append("""
            ReturnIfStatement
            IfStatement
            - conditions
            \(conditions.map(\.description).map({ $0.withIndent(4) }).joined(separator: "\n"))
            - statements
            \(statements.map(\.description).map({ $0.withIndent(4) }).joined(separator: "\n"))
            """)
            
            if let elseIfs = elseIfs {
                elseIfs.forEach { elseIf in
                    let (conditions, statements) = elseIf
                    
                    components.append("""
                    ElseIfStatement
                    - conditions
                    \(conditions.map(\.description).joined(separator: "\n").withIndent(4))
                    - statements
                    \(statements.map(\.description).joined(separator: "\n").withIndent(4))
                    """)
                }
            }
            
            components.append("""
            ElseStatement
            - statements
            \(elseStatements.map(\.description).joined(separator: "\n").withIndent(4))
            """)
            
            return components.joined(separator: "\n")
        }
    }
}

extension Statement {
    public static func canParse(parser: Parser) -> Bool {
        return true
    }
    
    public static func parse(parser: Parser) throws -> Statement {
        guard let next = parser.peek() else {
            throw ParserError.unexpectedEndOfFile(parser: parser)
        }
        
        let result: Statement
        if let keyword = next as? KeywordToken, keyword.keyword == .return {
            guard let after = parser.peek(offset: 2) else {
                throw ParserError.unexpectedEndOfFile(parser: parser)
            }
            
            try! parser.drop()
            
            if after is NewLineToken {
                result = .returnStatement(expression: nil, file: parser.file, location: keyword.location)
            } else if let next = after as? KeywordToken, next.keyword == .if {
                try! parser.drop()
                
                var conditions: [Expression] = []
                conditions.append(try Expression.parse(parser: parser))
                
                while parser.peek() is CommaToken {
                    try parser.accept(.comma)
                    conditions.append(try Expression.parse(parser: parser))
                }
                
                try parser.accept(.openAngleBracket)
                
                let statements: [Statement] = try [Statement].parse(parser: parser)
                var closeAngleBracket = try parser.accept(.closeAngleBracket)
                
                guard statements.count > 0 else {
                    throw ParserError.blockDoesntReturnAnyValue(reference: next)
                }
                
                var elseIfs: [(conditions: [Expression], statements: [Statement])] = []
                var elseStatements: [Statement]? = nil
                var elseKeyword: KeywordToken? = nil
                
                while let next = parser.peek() as? KeywordToken, next.keyword == .else {
                    elseKeyword = next
                    try! parser.drop()
                    
                    if let next = parser.peek() as? KeywordToken, next.keyword == .if {
                        try! parser.drop()
                        
                        var conditions: [Expression] = []
                        conditions.append(try Expression.parse(parser: parser))
                        
                        while parser.peek() is CommaToken {
                            try parser.accept(.comma)
                            conditions.append(try Expression.parse(parser: parser))
                        }
                        
                        try parser.accept(.openAngleBracket)
                        
                        let statements: [Statement] = try [Statement].parse(parser: parser)
                        closeAngleBracket = try parser.accept(.closeAngleBracket)
                        elseIfs.append((conditions, statements))
                        
                        guard statements.count > 0 else {
                            throw ParserError.blockDoesntReturnAnyValue(reference: next)
                        }
                    } else {
                        try parser.accept(.openAngleBracket)
                        elseStatements = try [Statement].parse(parser: parser)
                        closeAngleBracket = try parser.accept(.closeAngleBracket)
                        break
                    }
                }
                
                guard let elseStatements = elseStatements, let elseKeyword = elseKeyword else {
                    guard let next = parser.peek() else {
                        throw ParserError.unexpectedEndOfFile(parser: parser)
                    }
                    
                    throw ParserError.unexpectedToken(parser: parser, token: next)
                }
                
                guard elseStatements.count > 0 else {
                    throw ParserError.blockDoesntReturnAnyValue(reference: elseKeyword)
                }

                result = .returnIfStatement(checked: .unresolved, conditions: conditions, statements: statements, elseIfs: elseIfs.count > 0 ? elseIfs : nil, elseStatements: elseStatements, file: parser.file, location: keyword.location.lowerBound..<closeAngleBracket.location.upperBound)
            } else {
                let expression = try Expression.parse(parser: parser)
                result = .returnStatement(expression: expression, file: parser.file, location: keyword.location.lowerBound..<expression.location.upperBound)
            }
        } else if let keyword = next as? KeywordToken, keyword.keyword == .let || keyword.keyword == .var {
            guard let after = parser.peek(offset: 2) else {
                throw ParserError.unexpectedEndOfFile(parser: parser)
            }
            
            try! parser.drop()
            
            guard let name = after as? IdentifierToken else {
                throw ParserError.unexpectedToken(parser: parser, token: after)
            }
            
            try! parser.drop()
            let typeReference: TypeReference?
            if parser.peek() is ColonToken {
                try parser.accept(.colon)
                typeReference = try TypeReference.parse(parser: parser)
            } else {
                typeReference = nil
            }
            
            try parser.accept(.assignment)
            
            if let next = parser.peek() as? KeywordToken, next.keyword == .if {
                try! parser.drop()
                
                var conditions: [Expression] = []
                conditions.append(try Expression.parse(parser: parser))
                
                while parser.peek() is CommaToken {
                    try parser.accept(.comma)
                    conditions.append(try Expression.parse(parser: parser))
                }
                
                try parser.accept(.openAngleBracket)
                
                let statements: [Statement] = try [Statement].parse(parser: parser)
                var closeAngleBracket = try parser.accept(.closeAngleBracket)
                
                guard statements.count > 0 else {
                    throw ParserError.blockDoesntReturnAnyValue(reference: next)
                }
                
                var elseIfs: [(conditions: [Expression], statements: [Statement])] = []
                var elseStatements: [Statement]? = nil
                var elseKeyword: KeywordToken? = nil
                
                while let next = parser.peek() as? KeywordToken, next.keyword == .else {
                    elseKeyword = next
                    try! parser.drop()
                    
                    if let next = parser.peek() as? KeywordToken, next.keyword == .if {
                        try! parser.drop()
                        
                        var conditions: [Expression] = []
                        conditions.append(try Expression.parse(parser: parser))
                        
                        while parser.peek() is CommaToken {
                            try parser.accept(.comma)
                            conditions.append(try Expression.parse(parser: parser))
                        }
                        
                        try parser.accept(.openAngleBracket)
                        
                        let statements: [Statement] = try [Statement].parse(parser: parser)
                        closeAngleBracket = try parser.accept(.closeAngleBracket)
                        elseIfs.append((conditions, statements))
                        
                        guard statements.count > 0 else {
                            throw ParserError.blockDoesntReturnAnyValue(reference: next)
                        }
                    } else {
                        try parser.accept(.openAngleBracket)
                        elseStatements = try [Statement].parse(parser: parser)
                        closeAngleBracket = try parser.accept(.closeAngleBracket)
                        break
                    }
                }
                
                guard let elseStatements = elseStatements, let elseKeyword = elseKeyword else {
                    guard let next = parser.peek() else {
                        throw ParserError.unexpectedEndOfFile(parser: parser)
                    }
                    
                    throw ParserError.unexpectedToken(parser: parser, token: next)
                }
                
                guard elseStatements.count > 0 else {
                    throw ParserError.blockDoesntReturnAnyValue(reference: elseKeyword)
                }

                result = .variableIfDeclaration(isMutable: keyword.keyword == .var, name: name, typeReference: typeReference, checked: .unresolved, conditions: conditions, statements: statements, elseIfs: elseIfs.count > 0 ? elseIfs : nil, elseStatements: elseStatements, file: parser.file, location: keyword.location.lowerBound..<closeAngleBracket.location.upperBound)
            } else {
                let expression = try Expression.parse(parser: parser)
                result = .variableDeclaration(isMutable: keyword.keyword == .var, name: name, typeReference: typeReference, expression: expression, file: parser.file, location: keyword.location.lowerBound..<expression.location.upperBound)
            }
        } else if let keyword = next as? KeywordToken, keyword.keyword == .if {
            try! parser.drop()
            
            var conditions: [Expression] = []
            conditions.append(try Expression.parse(parser: parser))
            
            while parser.peek() is CommaToken {
                try parser.accept(.comma)
                conditions.append(try Expression.parse(parser: parser))
            }
            
            try parser.accept(.openAngleBracket)
            
            let statements: [Statement] = try [Statement].parse(parser: parser)
            var closeAngleBracket = try parser.accept(.closeAngleBracket)
            
            var elseIfs: [(conditions: [Expression], statements: [Statement])] = []
            var elseStatements: [Statement]? = nil
            
            while let next = parser.peek() as? KeywordToken, next.keyword == .else {
                try! parser.drop()
                
                if let next = parser.peek() as? KeywordToken, next.keyword == .if {
                    try! parser.drop()
                    
                    var conditions: [Expression] = []
                    conditions.append(try Expression.parse(parser: parser))
                    
                    while parser.peek() is CommaToken {
                        try parser.accept(.comma)
                        conditions.append(try Expression.parse(parser: parser))
                    }
                    
                    try parser.accept(.openAngleBracket)
                    
                    let statements: [Statement] = try [Statement].parse(parser: parser)
                    closeAngleBracket = try parser.accept(.closeAngleBracket)
                    elseIfs.append((conditions, statements))
                } else {
                    try parser.accept(.openAngleBracket)
                    elseStatements = try [Statement].parse(parser: parser)
                    closeAngleBracket = try parser.accept(.closeAngleBracket)
                    break
                }
            }
            
            result = .ifStatement(conditions: conditions, statements: statements, elseIfs: elseIfs.count > 0 ? elseIfs : nil, elseStatements: elseStatements, file: parser.file, location: keyword.location.lowerBound..<closeAngleBracket.location.upperBound)
        } else {
            let expression = try Expression.parse(parser: parser)
            
            if let next = parser.peek() as? OperatorToken, next.op == .assignment {
                try parser.accept(.assignment)
                
                let rhs = try Expression.parse(parser: parser)
                result = .assignmentStatement(lhs: expression, rhs: rhs, file: parser.file, location: expression.location.lowerBound..<rhs.location.upperBound)
            } else {
                result = .expression(expression)
            }
        }
        
        try parser.accept(.newLine)
        return result
    }
}
