//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation
import CheckedScanner

public protocol TypecheckerId {
    var description: String { get }
}

internal extension InferredType where T == TypeId {
    var typeId: TypeId {
        switch self {
        case .unresolved:
            fatalError()
        case let .inferred(type: typeId, context: _, typechecker: _):
            return typeId
        }
    }
}

internal extension InferredType {
    var id: T {
        switch self {
        case .unresolved:
            fatalError()
        case let .inferred(type: typeId, context: _, typechecker: _):
            return typeId
        }
    }
    
    var context: Context {
        switch self {
        case .unresolved:
            fatalError()
        case let .inferred(type: _, context: context, typechecker: _):
            return context
        }
    }
    
    var typechecker: Typechecker {
        switch self {
        case .unresolved:
            fatalError()
        case let .inferred(type: _, context: _, typechecker: typechecker):
            return typechecker
        }
    }
}

private extension Expression {
    func isMutable(in context: Context) -> Bool {
        switch self {
        case let .variableReferenceExpression(variable: variable, returns: _, file: _, location: _):
            return context.lookupVariable(variable.identifier)!.isMutable
        default:
            return false
        }
    }
}

public class Typechecker {
    public let codeGen: CodeGen
    internal let buildIn: BuildIn
    internal var modules: [ModuleContext] = []
    
    public init(configuration: CodeGen.Configuration) {
        self.codeGen = CodeGen(configuration: configuration)
        self.buildIn = BuildIn.buildIn(codeGen: codeGen)
        
        add(module: self.buildIn)
    }
    
    public func add(module: ModuleContext) {
        module.typechecker = self
        self.modules.append(module)
    }
    
    public func typecheck(_ topLevelDeclarations: [TopLevelDeclaration], in module: ModuleContext) throws -> [TopLevelDeclaration] {
        var result = topLevelDeclarations
        
        for (index, declaration) in topLevelDeclarations.enumerated() {
            var typechecked = declaration
            
            typechecked.prefixOperatorDeclarations = try declaration.prefixOperatorDeclarations.map({ try register($0, module: module, context: module) })
            typechecked.operatorDeclarations = try declaration.operatorDeclarations.map({ try register($0, module: module, context: module) })
            typechecked.functionDeclarations = try declaration.functionDeclarations.map({ try register($0, module: module, context: module) })
            result[index] = typechecked
        }
        
        for (index, declaration) in result.enumerated() {
            var typechecked = declaration
            
            typechecked.prefixOperatorDeclarations = try declaration.prefixOperatorDeclarations.map { declaration in
                let context = try PrefixOperatorContext(operatorDefinition: declaration.operatorDefinition, codeGen: codeGen, parent: module)
                
                return PrefixOperatorDeclaration(prefixToken: declaration.prefixToken, operatorToken: declaration.operatorToken, op: declaration.op, isImpure: declaration.isImpure, argument: declaration.argument, returns: declaration.returns, openAngleBracket: declaration.openAngleBracket, statements: try typecheckFunctionBody(declaration.statements, arguments: [ declaration.argument ], returnType: declaration.returns.checked.typeId, reference: declaration, module: module, context: context), closeAngleBracket: declaration.closeAngleBracket, checked: declaration.checked, file: declaration.file, location: declaration.location)
            }
            
            typechecked.operatorDeclarations = try declaration.operatorDeclarations.map { declaration in
                let context = try OperatorContext(operatorDefinition: declaration.operatorDefinition, codeGen: codeGen, parent: module)
                
                return OperatorDeclaration(operatorToken: declaration.operatorToken, op: declaration.op, isImpure: declaration.isImpure, lhs: declaration.lhs, rhs: declaration.rhs, returns: declaration.returns, openAngleBracket: declaration.openAngleBracket, statements: try typecheckFunctionBody(declaration.statements, arguments: [ declaration.lhs, declaration.rhs ], returnType: declaration.returns.checked.typeId, reference: declaration, module: module, context: context), closeAngleBracket: declaration.closeAngleBracket, checked: declaration.checked, file: declaration.file, location: declaration.location)
            }
            
            typechecked.functionDeclarations = try declaration.functionDeclarations.map { declaration in
                let context = try FunctionContext(functionDefinition: declaration.functionDefinition, codeGen: codeGen, parent: module)
                return FunctionDeclaration(name: declaration.name, isImpure: declaration.isImpure, arguments: declaration.arguments, returns: declaration.returns, openAngleBracket: declaration.openAngleBracket, statements: try typecheckFunctionBody(declaration.statements, arguments: declaration.arguments, returnType: declaration.returns?.checked.typeId, reference: declaration.name, module: module, context: context), closeAngleBracket: declaration.closeAngleBracket, checked: declaration.checked, file: declaration.file, location: declaration.location)
            }
            result[index] = typechecked
        }
        
        return result
    }
    
    private func register(_ functionDeclaration: FunctionDeclaration, module: ModuleContext, context: FunctionDefiningContext) throws -> FunctionDeclaration {
        var result: FunctionDeclaration = functionDeclaration
        
        if let returns = functionDeclaration.returns {
            result.returns = try typecheck(returns, module: module, context: context)
        }
        
        result.arguments = try functionDeclaration.arguments.map { argument -> FunctionDeclaration.FunctionArgumentDeclaration in
            return try typecheck(argument, module: module, context: context)
        }
        
        result.checked = .inferred(type: try context.register(result.functionDefinition, from: functionDeclaration), context: context, typechecker: self)
        
        return result
    }
    
    private func register(_ operatorDeclaration: PrefixOperatorDeclaration, module: ModuleContext, context: OperatorDefiningContext) throws -> PrefixOperatorDeclaration {
        var result: PrefixOperatorDeclaration = operatorDeclaration
        
        result.returns = try typecheck(operatorDeclaration.returns, module: module, context: context)
        
        result.argument = try typecheck(operatorDeclaration.argument, module: module, context: context)
        
        result.checked = .inferred(type: try context.register(result.operatorDefinition, from: operatorDeclaration), context: context, typechecker: self)
        
        return result
    }
    
    private func register(_ operatorDeclaration: OperatorDeclaration, module: ModuleContext, context: OperatorDefiningContext) throws -> OperatorDeclaration {
        var result: OperatorDeclaration = operatorDeclaration
        
        result.returns = try typecheck(operatorDeclaration.returns, module: module, context: context)
        
        result.lhs = try typecheck(operatorDeclaration.lhs, module: module, context: context)
        result.rhs = try typecheck(operatorDeclaration.rhs, module: module, context: context)
        
        result.checked = .inferred(type: try context.register(result.operatorDefinition, from: operatorDeclaration), context: context, typechecker: self)
        
        return result
    }
    
    private func typecheckFunctionBody(_ statements: [Statement], arguments: [FunctionDeclaration.FunctionArgumentDeclaration], returnType: TypeId?, reference: SourceElement, module: ModuleContext, context: FunctionBodyContext) throws -> [Statement] {
        try arguments.forEach { argument in
            try context.register(variable: VariableDefinition(isMutable: false, name: argument.name, type: argument.typeReference.checked.typeId), from: argument)
        }
        
        let result = try statements.map { statement in
            try typecheck(statement, module: module, context: context, returnType: returnType)
        }
        
        try typecheckReturned(result, reference: reference, withReturnType: returnType)
        
        return result
    }
    
    private func typecheck(_ statement: Statement, module: ModuleContext, context: FunctionBodyContext, returnType: TypeId?) throws -> Statement {
        switch statement {
        case let .expression(expression):
            let typechecked = try typecheck(expression, module: module, context: context, preferredReturnType: .relaxed(preferredReturnTypes: [ buildIn.Void ]))
            guard case let .inferred(type: type, context: _, typechecker: _) = typechecked.returns else {
                fatalError()
            }

            guard type == buildIn.Void else {
                throw ParserError.expressionResultUnused(expression: typechecked)
            }

            return .expression(typechecked)
        case let .assertion(name: name, condition: condition, reason: reason, module: _, file: file, location: location):
            let typecheckedCondition = try typecheck(condition, module: module, context: context, preferredReturnType: .strict(preferredReturnTypes: [ buildIn.Bool ]))
            let typecheckedReason: Expression?
            
            if let reason = reason {
                typecheckedReason = try typecheck(reason, module: module, context: context, preferredReturnType: .strict(preferredReturnTypes: [ buildIn.String ]))
            } else {
                typecheckedReason = nil
            }
            
            return .assertion(name: name, condition: typecheckedCondition, reason: typecheckedReason, module: module, file: file, location: location)
        case let .returnStatement(expression: expression, file: file, location: location):
            if let returnType = returnType {
                if let expression = expression {
                    let typechecked = try typecheck(expression, module: module, context: context, preferredReturnType: .strict(preferredReturnTypes: [ returnType ]))
                    return .returnStatement(expression: typechecked, file: file, location: location)
                } else {
                    throw ParserError.typeMissmatch(expected: returnType, actual: buildIn.Void, reference: statement)
                }
            } else {
                if let expression = expression {
                    let typechecked = try typecheck(expression, module: module, context: context, preferredReturnType: .relaxed(preferredReturnTypes: [ buildIn.Void ]))

                    guard case let .inferred(type: type, context: _, typechecker: _) = typechecked.returns else {
                        fatalError()
                    }

                    guard type == buildIn.Void else {
                        throw ParserError.typeMissmatch(expected: buildIn.Void, actual: type, reference: expression)
                    }

                    return .returnStatement(expression: typechecked, file: file, location: location)
                } else {
                    return .returnStatement(expression: nil, file: file, location: location)
                }
            }
        case let .variableDeclaration(isMutable: isMutable, name: name, typeReference: typeReference, expression: expression, file: file, location: location):
            if let typeReference = typeReference {
                let typecheckedTypeReference = try typecheck(typeReference, module: module, context: context)
                let typecheckedExpression = try typecheck(expression, module: module, context: context, preferredReturnType: .strict(preferredReturnTypes: [ typecheckedTypeReference.checked.id ]))
                try context.register(variable: VariableDefinition(isMutable: isMutable, name: name.identifier, type: typecheckedTypeReference.checked.id), from: name)
                return .variableDeclaration(isMutable: isMutable, name: name, typeReference: typecheckedTypeReference, expression: typecheckedExpression, file: file, location: location)
            } else {
                let typechecked = try typecheck(expression, module: module, context: context, preferredReturnType: .relaxed(preferredReturnTypes: []))
                try context.register(variable: VariableDefinition(isMutable: isMutable, name: name.identifier, type: typechecked.returns.id), from: name)
                return .variableDeclaration(isMutable: isMutable, name: name, typeReference: nil, expression: typechecked, file: file, location: location)
            }
        case let .ifStatement(conditions: conditions, statements: statements, elseIfs: elseIfs, elseStatements: elseStatements, file: file, location: location):
            let ifContext = try ScopedContext(codeGen: codeGen, parent: context)
            let typecheckedConditions = try conditions.map({ try typecheck($0, module: module, context: context, preferredReturnType: .strict(preferredReturnTypes: [ buildIn.Bool ])) })
            let typecheckedStatements = try statements.map { statement in
                return try typecheck(statement, module: module, context: ifContext, returnType: returnType)
            }
            
            let typecheckedElseIfs: [(conditions: [Expression], statements: [Statement])]?
            if let elseIfs = elseIfs {
                let ifContext = try ScopedContext(codeGen: codeGen, parent: context)
                typecheckedElseIfs = try elseIfs.map({ value in
                    let typecheckedConditions = try value.conditions.map({ try typecheck($0, module: module, context: context, preferredReturnType: .strict(preferredReturnTypes: [ buildIn.Bool ])) })
                    let typecheckedStatements = try value.statements.map({ try typecheck($0, module: module, context: ifContext, returnType: returnType) })
                    return (typecheckedConditions, typecheckedStatements)
                })
                 
            } else {
                typecheckedElseIfs = nil
            }
            
            let typecheckedElseStatements: [Statement]?
            if let elseStatements = elseStatements {
                let ifContext = try ScopedContext(codeGen: codeGen, parent: context)
                typecheckedElseStatements = try elseStatements.map({ try typecheck($0, module: module, context: ifContext, returnType: returnType) })
            } else {
                typecheckedElseStatements = nil
            }
            
            return .ifStatement(conditions: typecheckedConditions, statements: typecheckedStatements, elseIfs: typecheckedElseIfs, elseStatements: typecheckedElseStatements, file: file, location: location)
        case let .variableIfDeclaration(isMutable: isMutable, name: name, typeReference: typeReference, checked: _, conditions: conditions, statements: statements, elseIfs: elseIfs, elseStatements: elseStatements, file: file, location: location):
            let typecheckedTypeReference: TypeReference?
            if let typeReference = typeReference {
                typecheckedTypeReference = try typecheck(typeReference, module: module, context: context)
            } else {
                typecheckedTypeReference = nil
            }
            
            let ifContext = try ScopedContext(codeGen: codeGen, parent: context)
            let typecheckedConditions = try conditions.map({ try typecheck($0, module: module, context: context, preferredReturnType: .strict(preferredReturnTypes: [ buildIn.Bool ])) })
            let typecheckedStatements = try statements.dropLast().map({ try typecheck($0, module: module, context: ifContext, returnType: returnType) })
            let (typecheckedLastStatement, type) = try typecheck(statement: statements.last!, module: module, context: ifContext, returnType: returnType, withInferredType: typecheckedTypeReference?.checked.id)
            
            let typecheckedElseIfs: [(conditions: [Expression], statements: [Statement])]?
            if let elseIfs = elseIfs {
                typecheckedElseIfs = try elseIfs.map { value in
                    let (conditions, statements) = value
                    
                    let ifContext = try ScopedContext(codeGen: codeGen, parent: context)
                    let typecheckedConditions = try conditions.map({ try typecheck($0, module: module, context: context, preferredReturnType: .strict(preferredReturnTypes: [ buildIn.Bool ])) })
                    let typecheckedStatements = try statements.dropLast().map({ try typecheck($0, module: module, context: ifContext, returnType: returnType) })
                    let (typecheckedLastStatement, _) = try typecheck(statement: statements.last!, module: module, context: ifContext, returnType: returnType, withInferredType: type)
                    
                    return (typecheckedConditions, typecheckedStatements + [typecheckedLastStatement])
                }
            } else {
                typecheckedElseIfs = nil
            }
            
            let elseContext = try ScopedContext(codeGen: codeGen, parent: context)
            let typecheckedElseStatements = try elseStatements.dropLast().map({ try typecheck($0, module: module, context: elseContext, returnType: returnType) })
            let (typecheckedLastElseStatement, _) = try typecheck(statement: elseStatements.last!, module: module, context: elseContext, returnType: returnType, withInferredType: type)
            
            try context.register(variable: VariableDefinition(isMutable: isMutable, name: name.identifier, type: type), from: name)
            
            return .variableIfDeclaration(isMutable: isMutable, name: name, typeReference: typecheckedTypeReference, checked: .inferred(type: type, context: context, typechecker: self), conditions: typecheckedConditions, statements: typecheckedStatements + [typecheckedLastStatement], elseIfs: typecheckedElseIfs, elseStatements: typecheckedElseStatements + [typecheckedLastElseStatement], file: file, location: location)
        case let .assignmentStatement(lhs: lhs, rhs: rhs, file: file, location: location):
            let lhsTypechecked = try typecheck(lhs, module: module, context: context, preferredReturnType: .relaxed(preferredReturnTypes: []))
            let rhsTypechecked = try typecheck(rhs, module: module, context: context, preferredReturnType: .strict(preferredReturnTypes: [ lhsTypechecked.returns.id ]))
            
            guard lhsTypechecked.isMutable(in: context) else {
                throw ParserError.immutableExpressionAssignment(expression: lhs)
            }
            
            return .assignmentStatement(lhs: lhsTypechecked, rhs: rhsTypechecked, file: file, location: location)
        case let .returnIfStatement(checked: _, conditions: conditions, statements: statements, elseIfs: elseIfs, elseStatements: elseStatements, file: file, location: location):
            let ifContext = try ScopedContext(codeGen: codeGen, parent: context)
            let typecheckedConditions = try conditions.map({ try typecheck($0, module: module, context: context, preferredReturnType: .strict(preferredReturnTypes: [ buildIn.Bool ])) })
            let typecheckedStatements = try statements.dropLast().map({ try typecheck($0, module: module, context: ifContext, returnType: returnType) })
            let (typecheckedLastStatement, type) = try typecheck(statement: statements.last!, module: module, context: ifContext, returnType: returnType, withInferredType: returnType)
            
            let typecheckedElseIfs: [(conditions: [Expression], statements: [Statement])]?
            if let elseIfs = elseIfs {
                typecheckedElseIfs = try elseIfs.map { value in
                    let (conditions, statements) = value
                    
                    let ifContext = try ScopedContext(codeGen: codeGen, parent: context)
                    let typecheckedConditions = try conditions.map({ try typecheck($0, module: module, context: context, preferredReturnType: .strict(preferredReturnTypes: [ buildIn.Bool ])) })
                    let typecheckedStatements = try statements.dropLast().map({ try typecheck($0, module: module, context: ifContext, returnType: returnType) })
                    let (typecheckedLastStatement, _) = try typecheck(statement: statements.last!, module: module, context: ifContext, returnType: returnType, withInferredType: type)
                    
                    return (typecheckedConditions, typecheckedStatements + [typecheckedLastStatement])
                }
            } else {
                typecheckedElseIfs = nil
            }
            
            let elseContext = try ScopedContext(codeGen: codeGen, parent: context)
            let typecheckedElseStatements = try elseStatements.dropLast().map({ try typecheck($0, module: module, context: elseContext, returnType: returnType) })
            let (typecheckedLastElseStatement, _) = try typecheck(statement: elseStatements.last!, module: module, context: elseContext, returnType: returnType, withInferredType: type)
            
            return .returnIfStatement(checked: .inferred(type: type, context: context, typechecker: self), conditions: typecheckedConditions, statements: typecheckedStatements + [typecheckedLastStatement], elseIfs: typecheckedElseIfs, elseStatements: typecheckedElseStatements + [typecheckedLastElseStatement], file: file, location: location)
        }
    }
    
    private func typecheck(statement: Statement, module: ModuleContext, context: FunctionBodyContext, returnType: TypeId?, withInferredType: TypeId?) throws -> (Statement, TypeId) {
        switch statement {
        case let .expression(expression):
            let typechecked: Expression
            if let withInferredType = withInferredType {
                typechecked = try typecheck(expression, module: module, context: context, preferredReturnType: .strict(preferredReturnTypes: [ withInferredType ]))
            } else {
                typechecked = try typecheck(expression, module: module, context: context, preferredReturnType: .relaxed(preferredReturnTypes: []))
                
                guard typechecked.returns.id != buildIn.Void else {
                    throw ParserError.blockDoesntReturnAnyValue(reference: typechecked)
                }
            }
            
            return (.expression(typechecked), typechecked.returns.id)
        case let .ifStatement(conditions: conditions, statements: statements, elseIfs: elseIfs, elseStatements: elseStatements, file: file, location: location):
            let ifContext = try ScopedContext(codeGen: codeGen, parent: context)
            let typecheckedConditions = try conditions.map({ try typecheck($0, module: module, context: context, preferredReturnType: .strict(preferredReturnTypes: [ buildIn.Bool ])) })
            let typecheckedStatements = try statements.dropLast().map({ try typecheck($0, module: module, context: ifContext, returnType: returnType) })
            let (typecheckedLastStatement, type) = try typecheck(statement: statements.last!, module: module, context: ifContext, returnType: returnType, withInferredType: withInferredType)
            
            let typecheckedElseIfs: [(conditions: [Expression], statements: [Statement])]?
            if let elseIfs = elseIfs {
                typecheckedElseIfs = try elseIfs.map { value in
                    let (conditions, statements) = value
                    
                    let ifContext = try ScopedContext(codeGen: codeGen, parent: context)
                    let typecheckedConditions = try conditions.map({ try typecheck($0, module: module, context: context, preferredReturnType: .strict(preferredReturnTypes: [ buildIn.Bool ])) })
                    let typecheckedStatements = try statements.dropLast().map({ try typecheck($0, module: module, context: ifContext, returnType: returnType) })
                    let (typecheckedLastStatement, _) = try typecheck(statement: statements.last!, module: module, context: ifContext, returnType: returnType, withInferredType: type)
                    
                    return (typecheckedConditions, typecheckedStatements + [typecheckedLastStatement])
                }
            } else {
                typecheckedElseIfs = nil
            }
            
            guard let elseStatements = elseStatements else {
                throw ParserError.blockDoesntReturnAnyValue(reference: statement)
            }
            
            let elseContext = try ScopedContext(codeGen: codeGen, parent: context)
            let typecheckedElseStatements = try elseStatements.dropLast().map({ try typecheck($0, module: module, context: elseContext, returnType: returnType) })
            let (typecheckedLastElseStatement, _) = try typecheck(statement: elseStatements.last!, module: module, context: elseContext, returnType: returnType, withInferredType: type)
            
            return (Statement.ifStatement(conditions: typecheckedConditions, statements: typecheckedStatements + [typecheckedLastStatement], elseIfs: typecheckedElseIfs, elseStatements: typecheckedElseStatements + [typecheckedLastElseStatement], file: file, location: location), type)
        default:
            throw ParserError.blockDoesntReturnAnyValue(reference: statement)
        }
    }
    
    private func typecheckReturned(_ statements: [Statement], reference: SourceElement, withReturnType returnType: TypeId?) throws {
        guard try _returned(statements, reference: reference, withReturnType: returnType) else {
            throw ParserError.missingReturnStatement(reference: reference)
        }
    }
    
    private func _returned(_ statements: [Statement], reference: SourceElement, withReturnType returnType: TypeId?) throws -> Bool {
        guard let returnType = returnType else {
            return true
        }
        
        guard returnType != buildIn.Void else {
            return true
        }
        
        for statement in statements.reversed() {
            switch statement {
            case let .returnStatement(expression: .some(expression), file: _, location: _):
                if expression.returns.typeId == returnType {
                    return true
                }
            case let .ifStatement(conditions: _, statements: statements, elseIfs: elseIfs, elseStatements: elseStatements, file: _, location: _):
                guard try _returned(statements, reference: reference, withReturnType: returnType) else {
                    return false
                }
                
                if let elseIfs = elseIfs {
                    for elseIf in elseIfs {
                        guard try _returned(elseIf.statements, reference: reference, withReturnType: returnType) else {
                            return false
                        }
                    }
                }
                
                guard let elseStatements = elseStatements else {
                    return false
                }
                
                guard try _returned(elseStatements, reference: reference, withReturnType: returnType) else {
                    return false
                }
                
                return true
            case .returnIfStatement:
                return true
            default:
                continue
            }
        }
        
        return false
    }
    
    private enum ReturnTypePolicy {
        case relaxed(preferredReturnTypes: [TypeId])
        case strict(preferredReturnTypes: [TypeId])
    }
    
    private func typecheck(_ expression: Expression, module: ModuleContext, context: FunctionBodyContext, preferredReturnType: ReturnTypePolicy) throws -> Expression {
        func apply(possibleReturnTypes: [TypeId], name: String) throws -> InferredType<TypeId> {
            guard possibleReturnTypes.count > 0 else {
                throw ParserError.unkownReference(name: name, reference: expression)
            }

            switch preferredReturnType {
            case let .relaxed(preferredReturnTypes: preferredReturnTypes):
                if let first = possibleReturnTypes.first(where: { preferredReturnTypes.contains($0) }) {
                    return .inferred(type: first, context: context, typechecker: self)
                } else {
                    return .inferred(type: possibleReturnTypes.first!, context: context, typechecker: self)
                }
            case let .strict(preferredReturnTypes: preferredReturnTypes):
                guard let first = possibleReturnTypes.first(where: { preferredReturnTypes.contains($0) }) else {
                    throw ParserError.unkownReference(name: name, reference: expression)
                }

                return .inferred(type: first, context: context, typechecker: self)
            }
        }

        switch expression {
        case let .functionCallExpression(name: name, function: _, arguments: arguments, returns: _, file: file, location: location):
            switch preferredReturnType {
            case let .strict(preferredReturnTypes: preferredReturnTypes):
                let typechecked = try typecheck(expression, module: module, context: context, preferredReturnType: .relaxed(preferredReturnTypes: preferredReturnTypes))

                guard case let .inferred(type, _, _) = typechecked.returns else {
                    fatalError()
                }

                guard preferredReturnTypes.contains(type) else {
                    throw ParserError.unkownReference(name: name.identifier, reference: expression)
                }

                return typechecked
            case let .relaxed(preferredReturnTypes: preferredReturnTypes):
                var functions = context.searchFunctions(name.identifier, predicate: { $0.arguments.count == arguments.count })
                for (index, argument) in arguments.enumerated() {
                    functions = functions.filter({ $0.definition.arguments[index].name == argument.name })

                    let possibleReturnTypes = argument.expression.possibleReturnTypes(in: context)
                    functions = functions.filter({ possibleReturnTypes.contains($0.definition.arguments[index].typeReference) })
                }

                guard let function = functions.first(where: { preferredReturnTypes.contains($0.definition.inferredReturnType(in: context)) }) ?? functions.first else {
                    throw ParserError.unkownReference(name: name.identifier, reference: expression)
                }
                
                if function.definition.isImpure {
                    guard context.isImpure else {
                        throw ParserError.invalidImpureCall(name: "function", statement: name)
                    }
                }

                let typechecked = try arguments.enumerated().map { pair -> Expression.FunctionCallArgument in
                    let (index, argument) = pair
                    let typechecked = try typecheck(argument.expression, module: module, context: context, preferredReturnType: .strict(preferredReturnTypes: [ function.definition.arguments[index].typeReference ]))

                    return Expression.FunctionCallArgument(name: argument.name, expression: typechecked, file: argument.file, location: argument.location)
                }

                return .functionCallExpression(name: name, function: .inferred(type: function, context: context, typechecker: self), arguments: typechecked, returns: .inferred(type: function.definition.inferredReturnType(in: context), context: context, typechecker: self), file: file, location: location)
            }
        case let .groupedExpression(expression: expression, returns: _, file: file, location: location):
            let typechecked = try typecheck(expression, module: module, context: context, preferredReturnType: preferredReturnType)
            return .groupedExpression(expression: typechecked, returns: typechecked.returns, file: file, location: location)
        case let .integerLiteralExpression(literal: literal, returns: _, file: file, location: location):
            return try .integerLiteralExpression(literal: literal, returns: apply(possibleReturnTypes: expression.possibleReturnTypes(in: context), name: "integer literal"), file: file, location: location)
        case let .floatingPointLiteralExpression(literal: literal, returns: _, file: file, location: location):
            return try .floatingPointLiteralExpression(literal: literal, returns: apply(possibleReturnTypes: expression.possibleReturnTypes(in: context), name: "floating point literal"), file: file, location: location)
        case let .booleanLiteralExpression(literal: literal, returns: _, file: file, location: location):
            return try .booleanLiteralExpression(literal: literal, returns: apply(possibleReturnTypes: expression.possibleReturnTypes(in: context), name: "boolean literal"), file: file, location: location)
        case let .stringLiteralExpression(literal: literal, returns: _, file: file, location: location):
            return try .stringLiteralExpression(literal: literal, returns: apply(possibleReturnTypes: expression.possibleReturnTypes(in: context), name: "string literal"), file: file, location: location)
        case let .prefixOperatorExpression(operator: op, checked: _, expression: _expression, returns: _, file: file, location: location):
            switch preferredReturnType {
            case let .strict(preferredReturnTypes: preferredReturnTypes):
                let typechecked = try typecheck(expression, module: module, context: context, preferredReturnType: .relaxed(preferredReturnTypes: preferredReturnTypes))

                guard case let .inferred(type, _, _) = typechecked.returns else {
                    fatalError()
                }

                guard preferredReturnTypes.contains(type) else {
                    throw ParserError.unkownReference(name: op.description, reference: expression)
                }

                return typechecked
            case let .relaxed(preferredReturnTypes: preferredReturnTypes):
                let possibleReturnTypes = _expression.possibleReturnTypes(in: context)
                let operators = context.searchPrefixOperators(op.op, predicate: { possibleReturnTypes.contains($0.argument.typeReference) })
                let typechecked = try typecheck(_expression, module: module, context: context, preferredReturnType: .strict(preferredReturnTypes: operators.map(\.definition.argument.typeReference)))

                guard let prefixOperator = operators.first(where: { preferredReturnTypes.contains($0.definition.returns) }) ?? operators.first else {
                    throw ParserError.unkownReference(name: op.description, reference: expression)
                }
                
                if prefixOperator.definition.isImpure {
                    guard context.isImpure else {
                        throw ParserError.invalidImpureCall(name: "prefix operator", statement: op)
                    }
                }

                return .prefixOperatorExpression(operator: op, checked: .inferred(type: prefixOperator, context: context, typechecker: self), expression: typechecked, returns: .inferred(type: prefixOperator.definition.returns, context: context, typechecker: self), file: file, location: location)
            }
        case let .variableReferenceExpression(variable: variable, returns: _, file: file, location: location):
            guard let returnType = context.lookupVariable(variable.identifier) else {
                throw ParserError.unkownReference(name: variable.identifier, reference: variable)
            }

            return .variableReferenceExpression(variable: variable, returns: try apply(possibleReturnTypes: [ returnType.type ], name: "variable"), file: file, location: location)
        case let .binaryOperatorExpression(operator: op, checked: _, lhs: lhs, rhs: rhs, returns: _, file: file, location: location):
            switch preferredReturnType {
            case let .strict(preferredReturnTypes: preferredReturnTypes):
                let typechecked = try typecheck(expression, module: module, context: context, preferredReturnType: .relaxed(preferredReturnTypes: preferredReturnTypes))

                guard case let .inferred(type, _, _) = typechecked.returns else {
                    fatalError()
                }

                guard preferredReturnTypes.contains(type) else {
                    throw ParserError.unkownReference(name: op.description, reference: expression)
                }

                return typechecked
            case let .relaxed(preferredReturnTypes: preferredReturnTypes):
                var operators = context.searchOperators(op.op, predicate: { _ in true })

                let lhsPossibleReturnTypes = lhs.possibleReturnTypes(in: context)
                operators = operators.filter({ lhsPossibleReturnTypes.contains($0.definition.lhs.typeReference) })

                let rhsPossibleReturnTypes = rhs.possibleReturnTypes(in: context)
                operators = operators.filter({ rhsPossibleReturnTypes.contains($0.definition.rhs.typeReference) })

                guard let function = operators.first(where: { preferredReturnTypes.contains($0.definition.returns) }) ?? operators.first else {
                    throw ParserError.unkownReference(name: op.description, reference: expression)
                }
                
                if function.definition.isImpure {
                    guard context.isImpure else {
                        throw ParserError.invalidImpureCall(name: "operator", statement: op)
                    }
                }

                let lhsTypechecked = try typecheck(lhs, module: module, context: context, preferredReturnType: .strict(preferredReturnTypes: [ function.definition.lhs.typeReference ]))
                let rhsTypechecked = try typecheck(rhs, module: module, context: context, preferredReturnType: .strict(preferredReturnTypes: [ function.definition.rhs.typeReference ]))

                return .binaryOperatorExpression(operator: op, checked: .inferred(type: function, context: context, typechecker: self), lhs: lhsTypechecked, rhs: rhsTypechecked, returns: .inferred(type: function.definition.returns, context: context, typechecker: self), file: file, location: location)
            }
        case let .methodCallExpression(instance: instance, name: name, method: _, arguments: arguments, returns: _, file: file, location: location):
            switch preferredReturnType {
            case let .strict(preferredReturnTypes: preferredReturnTypes):
                let typechecked = try typecheck(expression, module: module, context: context, preferredReturnType: .relaxed(preferredReturnTypes: preferredReturnTypes))

                guard case let .inferred(type, _, _) = typechecked.returns else {
                    fatalError()
                }

                guard preferredReturnTypes.contains(type) else {
                    throw ParserError.unkownReference(name: name.identifier, reference: expression)
                }

                return typechecked
            case let .relaxed(preferredReturnTypes: preferredReturnTypes):
                var methods = instance.possibleReturnTypes(in: context).flatMap { type -> [MethodId] in
                    return context.searchMethods(type, name: name.identifier, predicate: { $0.arguments.count == arguments.count })
                }
                for (index, argument) in arguments.enumerated() {
                    methods = methods.filter({ $0.definition.arguments[index].name == argument.name })

                    let possibleReturnTypes = argument.expression.possibleReturnTypes(in: context)
                    methods = methods.filter({ possibleReturnTypes.contains($0.definition.arguments[index].typeReference) })
                }

                guard let method = methods.first(where: { preferredReturnTypes.contains($0.definition.inferredReturnType(in: context)) }) ?? methods.first else {
                    throw ParserError.unkownReference(name: name.identifier, reference: expression)
                }
                
                if method.definition.isImpure {
                    guard context.isImpure else {
                        throw ParserError.invalidImpureCall(name: "method", statement: name)
                    }
                }

                let typecheckedInstance = try typecheck(instance, module: module, context: context, preferredReturnType: .strict(preferredReturnTypes: [ method.context.type ]))
                let typecheckedArguments = try arguments.enumerated().map { pair -> Expression.FunctionCallArgument in
                    let (index, argument) = pair
                    let typechecked = try typecheck(argument.expression, module: module, context: context, preferredReturnType: .strict(preferredReturnTypes: [ method.definition.arguments[index].typeReference ]))

                    return Expression.FunctionCallArgument(name: argument.name, expression: typechecked, file: argument.file, location: argument.location)
                }

                return .methodCallExpression(instance: typecheckedInstance, name: name, method: .inferred(type: method, context: context, typechecker: self), arguments: typecheckedArguments, returns: .inferred(type: method.definition.inferredReturnType(in: context), context: context, typechecker: self), file: file, location: location)
            }
        }
    }
    
    private func typecheck(_ functionArgumentDeclaration: FunctionDeclaration.FunctionArgumentDeclaration, module: ModuleContext, context: Context) throws -> FunctionDeclaration.FunctionArgumentDeclaration {
        var result = functionArgumentDeclaration
        result.typeReference = try typecheck(functionArgumentDeclaration.typeReference, module: module, context: context)
        return result
    }
    
    private func typecheck(_ typeReference: TypeReference, module: ModuleContext, context: Context) throws -> TypeReference {
        var result = typeReference
        guard let typeId = context.searchStruct(typeReference.name) else {
            throw ParserError.unkownReference(name: "type", reference: typeReference)
        }
        
        result.checked = .inferred(type: typeId, context: context, typechecker: self)
        return result
    }
}
