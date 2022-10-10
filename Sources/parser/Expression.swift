//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation
import CheckedScanner

public indirect enum Expression: AST {
    case functionCallExpression(name: IdentifierToken, function: InferredType<FunctionId>, arguments: [FunctionCallArgument], returns: InferredType<TypeId>, file: URL, location: Range<Int>)
    case groupedExpression(expression: Expression, returns: InferredType<TypeId>, file: URL, location: Range<Int>)
    case integerLiteralExpression(literal: String, returns: InferredType<TypeId>, file: URL, location: Range<Int>)
    case floatingPointLiteralExpression(literal: String, returns: InferredType<TypeId>, file: URL, location: Range<Int>)
    case booleanLiteralExpression(literal: Bool, returns: InferredType<TypeId>, file: URL, location: Range<Int>)
    case stringLiteralExpression(literal: String, returns: InferredType<TypeId>, file: URL, location: Range<Int>)
    case prefixOperatorExpression(operator: OperatorToken.Operator, checked: InferredType<PrefixOperatorId>, expression: Expression, returns: InferredType<TypeId>, file: URL, location: Range<Int>)
    case variableReferenceExpression(variable: IdentifierToken, returns: InferredType<TypeId>, file: URL, location: Range<Int>)
    case binaryOperatorExpression(operator: OperatorToken.Operator, checked: InferredType<OperatorId>, lhs: Expression, rhs: Expression, returns: InferredType<TypeId>, file: URL, location: Range<Int>)
    case methodCallExpression(instance: Expression, name: IdentifierToken, method: InferredType<MethodId>, arguments: [FunctionCallArgument], returns: InferredType<TypeId>, file: URL, location: Range<Int>)
    
    public struct FunctionCallArgument: AST {
        public var name: String?
        public var expression: Expression
        public var file: URL
        public var location: Range<Int>
        
        public var description: String {
            return """
            \(type(of: self))
            - name: \(name ?? "")
            - expression:
            \(expression.description.withIndent(4))
            """
        }
    }
    
    public var file: URL {
        switch self {
        case let .functionCallExpression(name: _, function: _, arguments: _, returns: _, file: file, location: _), let .groupedExpression(expression: _, returns: _, file: file, location: _), let .integerLiteralExpression(literal: _, returns: _, file: file, location: _), let .floatingPointLiteralExpression(literal: _, returns: _, file: file, location: _), let .booleanLiteralExpression(literal: _, returns: _, file: file, location: _), let .stringLiteralExpression(literal: _, returns: _, file: file, location: _), let .prefixOperatorExpression(operator: _, checked: _, expression: _, returns: _, file: file, location: _), let .variableReferenceExpression(variable: _, returns: _, file: file, location: _), let .binaryOperatorExpression(operator: _, checked: _, lhs: _, rhs: _, returns: _, file: file, location: _), let .methodCallExpression(instance: _, name: _, method: _, arguments: _, returns: _, file: file, location: _):
            return file
        }
    }
    
    public var location: Range<Int> {
        switch self {
        case let .functionCallExpression(name: _, function: _, arguments: _, returns: _, file: _, location: location), let .groupedExpression(expression: _, returns: _, file: _, location: location), let .integerLiteralExpression(literal: _, returns: _, file: _, location: location), let .floatingPointLiteralExpression(literal: _, returns: _, file: _, location: location), let .booleanLiteralExpression(literal: _, returns: _, file: _, location: location), let .stringLiteralExpression(literal: _, returns: _, file: _, location: location), let .prefixOperatorExpression(operator: _, checked: _, expression: _, returns: _, file: _, location: location), let .variableReferenceExpression(variable: _, returns: _, file: _, location: location), let .binaryOperatorExpression(operator: _, checked: _, lhs: _, rhs: _, returns: _, file: _, location: location), let .methodCallExpression(instance: _, name: _, method: _, arguments: _, returns: _, file: _, location: location):
            return location
        }
    }
    
    public var description: String {
        switch self {
        case let .functionCallExpression(name: name, function: _, arguments: arguments, returns: returns, file: _, location: _):
            return """
            FunctionCallExpression
            - name: \(name.identifier)
            - arguments:
            \(arguments.map({ $0.description.withIndent(4) }).joined(separator: "\n"))
            - returns: \(returns.description)
            """
        case let .groupedExpression(expression: expression, returns: returns, file: _, location: _):
            return """
            GroupedExpression
            - returns: \(returns.description)
            \(expression.description.withIndent(4))
            """
        case let .integerLiteralExpression(literal: literal, returns: returns, file: _, location: _):
            return """
            IntegerLiteralExpression
            - literal: \(literal)
            - returns: \(returns.description)
            """
        case let .floatingPointLiteralExpression(literal: literal, returns: returns, file: _, location: _):
            return """
            FloatingPointLiteralExpression
            - literal: \(literal)
            - returns: \(returns.description)
            """
        case let .booleanLiteralExpression(literal: literal, returns: returns, file: _, location: _):
            return """
            BooleanLiteralExpression
            - literal: \(literal)
            - returns: \(returns.description)
            """
        case let .stringLiteralExpression(literal: literal, returns: returns, file: _, location: _):
            return """
            StringLiteralExpression
            - literal: \(literal)
            - returns: \(returns.description)
            """
        case let .prefixOperatorExpression(operator: op, checked: _, expression: expression, returns: returns, file: _, location: _):
            return """
            PrefixOperatorExpression
            - operator: \(op.description)
            - returns: \(returns.description)
            \(expression.description.withIndent(4))
            """
        case let .variableReferenceExpression(variable: variable, returns: returns, file: _, location: _):
            return """
            VariableReferenceExpression
            - name: \(variable.identifier)
            - returns: \(returns.description)
            """
        case let .binaryOperatorExpression(operator: op, checked: _, lhs: lhs, rhs: rhs, returns: returns, file: _, location: _):
            return """
            BinaryOperatorExpression
            - operator: \(op.description)
            - lhs:
            \(lhs.description.withIndent(4))
            - rhs
            \(rhs.description.withIndent(4))
            - returns: \(returns.description)
            """
        case let .methodCallExpression(instance: instance, name: name, method: _, arguments: arguments, returns: returns, file: _, location: _):
            return """
            MethodCallExpression
            - instance:
            \(instance.description.withIndent(4))
            - name: \(name.identifier)
            - arguments:
            \(arguments.map({ $0.description.withIndent(4) }).joined(separator: "\n"))
            - returns: \(returns.description)
            """
        }
    }
    
    public func possibleReturnTypes(in context: Context) -> [TypeId] {
        switch self {
        case let .functionCallExpression(name: name, function: _, arguments: arguments, returns: _, file: _, location: _):
            var functions = context.searchFunctions(name.identifier, predicate: { $0.arguments.count == arguments.count })
            for (index, argument) in arguments.enumerated() {
                functions = functions.filter({ $0.definition.arguments[index].name == argument.name }).filter({ function in
                    argument.expression.possibleReturnTypes(in: context).contains(function.definition.arguments[index].typeReference)
                })
            }

            return functions.map({ $0.definition.inferredReturnType(in: context) })
        case let .groupedExpression(expression: expression, returns: _, file: _, location: _):
            return expression.possibleReturnTypes(in: context)
        case let .integerLiteralExpression(literal: literal, returns: _, file: _, location: _):
            let buildIn = context.moduleContext.typechecker!.buildIn
            if literal.hasPrefix("-") {
                return [buildIn.Int64, buildIn.Int32, buildIn.Int16, buildIn.Int8]
            } else {
                return [buildIn.Int64, buildIn.Int32, buildIn.Int16, buildIn.Int8, buildIn.UInt64, buildIn.UInt32, buildIn.UInt16, buildIn.UInt8]
            }
        case .floatingPointLiteralExpression:
            let buildIn = context.moduleContext.typechecker!.buildIn
            return [buildIn.Double, buildIn.Float]
        case .booleanLiteralExpression:
            let buildIn = context.moduleContext.typechecker!.buildIn
            return [buildIn.Bool]
        case .stringLiteralExpression:
            let buildIn = context.moduleContext.typechecker!.buildIn
            return [buildIn.String]
        case let .prefixOperatorExpression(operator: op, checked: _, expression: expression, returns: _, file: _, location: _):
            return expression.possibleReturnTypes(in: context).flatMap { typeReference -> [PrefixOperatorId] in
                context.searchPrefixOperators(op, predicate: { $0.argument.typeReference == typeReference })
            }.map(\.definition.returns)
        case let .variableReferenceExpression(variable: variable, returns: _, file: _, location: _):
            if let inferredType = context.lookupVariable(variable.identifier) {
                return [ inferredType.type ]
            } else {
                return []
            }
        case let .binaryOperatorExpression(operator: op, checked: _, lhs: lhs, rhs: rhs, returns: _, file: _, location: _):
            var operators = context.searchOperators(op, predicate: { _ in true })

            let lhsPossibleReturnsTypes = lhs.possibleReturnTypes(in: context)
            operators = operators.filter({ lhsPossibleReturnsTypes.contains($0.definition.lhs.typeReference) })

            let rhsPossibleReturnsTypes = rhs.possibleReturnTypes(in: context)
            operators = operators.filter({ rhsPossibleReturnsTypes.contains($0.definition.rhs.typeReference) })

            return operators.map(\.definition.returns)
        case let .methodCallExpression(instance: instance, name: name, method: _, arguments: arguments, returns: _, file: _, location: _):
            var methods = instance.possibleReturnTypes(in: context).flatMap { type -> [MethodId] in
                return context.searchMethods(type, name: name.identifier, predicate: { $0.arguments.count == arguments.count })
            }
            for (index, argument) in arguments.enumerated() {
                methods = methods.filter({ $0.definition.arguments[index].name == argument.name }).filter({ function in
                    argument.expression.possibleReturnTypes(in: context).contains(function.definition.arguments[index].typeReference)
                })
            }

            return methods.map({ $0.definition.inferredReturnType(in: context) })
        }
    }
    
    public var returns: InferredType<TypeId> {
        switch self {
        case let .functionCallExpression(name: _, function: _, arguments: _, returns: returns, file: _, location: _), let .groupedExpression(expression: _, returns: returns, file: _, location: _), let .integerLiteralExpression(literal: _, returns: returns, file: _, location: _), let .floatingPointLiteralExpression(literal: _, returns: returns, file: _, location: _), let .booleanLiteralExpression(literal: _, returns: returns, file: _, location: _), let .stringLiteralExpression(literal: _, returns: returns, file: _, location: _), let .prefixOperatorExpression(operator: _, checked: _, expression: _, returns: returns, file: _, location: _), let .variableReferenceExpression(variable: _, returns: returns, file: _, location: _), let .binaryOperatorExpression(operator: _, checked: _, lhs: _, rhs: _, returns: returns, file: _, location: _), let .methodCallExpression(instance: _, name: _, method: _, arguments: _, returns: returns, file: _, location: _):
            return returns
        }
    }
}

extension Expression {
    public static func canParse(parser: Parser) -> Bool {
        return true
    }
    
    public static func parse(parser: Parser) throws -> Expression {
        guard let next = parser.peek() else {
            throw ParserError.unexpectedEndOfFile(parser: parser)
        }
        
        let result: Expression
        if next is OpenParanToken {
            let openParan = try parser.accept(.openParan)
            let expression = try Expression.parse(parser: parser)
            let closeParan = try parser.accept(.closeParan)
            
            result = .groupedExpression(expression: expression, returns: .unresolved, file: parser.file, location: openParan.location.lowerBound..<closeParan.location.upperBound)
        } else if let integerLiteral = next as? IntegerLiteralToken {
            try! parser.drop()
            result = .integerLiteralExpression(literal: integerLiteral.literal, returns: .unresolved, file: parser.file, location: integerLiteral.location)
        } else if let floatingPointLiteral = next as? FloatingPointLiteralToken {
            try! parser.drop()
            result = .floatingPointLiteralExpression(literal: floatingPointLiteral.literal, returns: .unresolved, file: parser.file, location: floatingPointLiteral.location)
        } else if let booleanLiteral = next as? BooleanLiteralToken {
            try! parser.drop()
            result = .booleanLiteralExpression(literal: booleanLiteral.literal, returns: .unresolved, file: parser.file, location: booleanLiteral.location)
        } else if let stringLiteral = next as? StringLiteralToken {
            try! parser.drop()
            result = .stringLiteralExpression(literal: stringLiteral.literal, returns: .unresolved, file: parser.file, location: stringLiteral.location)
        } else if let op = next as? OperatorToken, op.op.isPrefixOperator {
            try! parser.drop()
            let expression = try Expression.parse(parser: parser)
            
            result = .prefixOperatorExpression(operator: op.op, checked: .unresolved, expression: expression, returns: .unresolved, file: parser.file, location: op.location.lowerBound..<expression.location.upperBound)
        } else if let identifier = next as? IdentifierToken, let openParan = parser.peek(offset: 2) as? OpenParanToken, identifier.location.upperBound == openParan.location.lowerBound {
            try! parser.drop()
            try! parser.drop()
            
            var arguments: [FunctionCallArgument] = []
            while let next = parser.peek(), !(next is CloseParanToken) {
                if arguments.count > 0 {
                    try parser.accept(.comma)
                    arguments.append(try FunctionCallArgument.parse(parser: parser))
                } else {
                    arguments.append(try FunctionCallArgument.parse(parser: parser))
                }
            }
            
            let closeParan = try parser.accept(.closeParan)
            
            result = .functionCallExpression(name: identifier, function: .unresolved, arguments: arguments, returns: .unresolved, file: parser.file, location: identifier.location.lowerBound..<closeParan.location.upperBound)
        } else if let identifier = next as? IdentifierToken {
            try! parser.drop()
            result = .variableReferenceExpression(variable: identifier, returns: .unresolved, file: parser.file, location: identifier.location)
        } else {
            throw ParserError.unexpectedToken(parser: parser, token: next)
        }
        
        var methodResult = result
        while let dot = parser.peek() as? DotToken {
            if let identifier = parser.peek(offset: 2) as? IdentifierToken, let openParan = parser.peek(offset: 3) as? OpenParanToken, identifier.location.upperBound == openParan.location.lowerBound {
                try! parser.drop()
                try! parser.drop()
                try! parser.drop()
                
                var arguments: [FunctionCallArgument] = []
                while let next = parser.peek(), !(next is CloseParanToken) {
                    if arguments.count > 0 {
                        try parser.accept(.comma)
                        arguments.append(try FunctionCallArgument.parse(parser: parser))
                    } else {
                        arguments.append(try FunctionCallArgument.parse(parser: parser))
                    }
                }
                
                let closeParan = try parser.accept(.closeParan)
                methodResult = .methodCallExpression(instance: methodResult, name: identifier, method: .unresolved, arguments: arguments, returns: .unresolved, file: parser.file, location: identifier.location.lowerBound..<closeParan.location.upperBound)
            } else {
                throw ParserError.unexpectedToken(parser: parser, token: dot)
            }
        }
        
        if let op = parser.peek() as? OperatorToken, op.op.isInfixOperator {
            try! parser.drop()
            let rhs = try Expression.parse(parser: parser)
            
            return .binaryOperatorExpression(operator: op.op, checked: .unresolved, lhs: methodResult, rhs: rhs, returns: .unresolved, file: parser.file, location: result.location.lowerBound..<rhs.location.upperBound)
        }
        
        return methodResult
    }
}

extension Expression.FunctionCallArgument {
    public static func canParse(parser: Parser) -> Bool {
        return true
    }
    
    public static func parse(parser: Parser) throws -> Expression.FunctionCallArgument {
        guard let next = parser.peek() else {
            throw ParserError.unexpectedEndOfFile(parser: parser)
        }
        
        if let next = next as? IdentifierToken, parser.peek(offset: 2) is ColonToken {
            try! parser.drop()
            try! parser.drop()
            
            let expression = try Expression.parse(parser: parser)
            return Expression.FunctionCallArgument(name: next.identifier, expression: expression, file: parser.file, location: next.location.lowerBound..<expression.location.upperBound)
        }
        
        let expression = try Expression.parse(parser: parser)
        return Expression.FunctionCallArgument(expression: expression, file: parser.file, location: expression.location)
    }
}
