//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation
import CheckedScanner

public protocol Context: AnyObject {
    var qualifedName: String { get }
    var codeGen: CodeGen { get }
    var parent: Context? { get }
}

extension Context {
    var moduleContext: ModuleContext {
        if let self = self as? ModuleContext {
            return self
        }
        
        return parent!.moduleContext
    }
    
    func searchStruct(_ typeReference: String) -> TypeId? {
        if let self = self as? StructDefiningContext {
            if let definition = self.structs.lookup.first(where: { $0.value.name == typeReference }) {
                return definition.key
            }
        }
        
        if parent != nil {
            return parent!.searchStruct(typeReference)
        }
        
        if self is ModuleContext, self !== self.moduleContext.typechecker!.buildIn {
            return self.moduleContext.typechecker!.buildIn.searchStruct(typeReference)
        }
        
        return nil
    }
    
    func searchFunctions(_ name: String, predicate: (FunctionDefinition) -> Bool) -> [FunctionId] {
        var result: [FunctionId] = []
        
        if let self = self as? FunctionDefiningContext {
            if let definitions = self.functions.cache[name] {
                result.append(contentsOf: definitions.filter({ predicate($0.1) }).map({ $0.0 }))
            }
        }
        
        if parent != nil {
            result.append(contentsOf: parent!.searchFunctions(name, predicate: predicate))
        }
        
        if self is ModuleContext, self !== self.moduleContext.typechecker!.buildIn {
            result.append(contentsOf: self.moduleContext.typechecker!.buildIn.searchFunctions(name, predicate: predicate))
        }
        
        return result
    }
    
    func searchMethods(_ type: TypeId, name: String, predicate: (MethodDefinition) -> Bool) -> [MethodId] {
        var result: [MethodId] = []
        
        if let self = self as? StructDefiningContext {
            if let context = self.structs.contexts[type], let definitions = context.methods.cache[name] {
                result.append(contentsOf: definitions.filter({ predicate($0.1) }).map({ $0.0 }))
            }
        }
        
        if parent != nil {
            result.append(contentsOf: parent!.searchMethods(type, name: name, predicate: predicate))
        }
        
        if self is ModuleContext, self !== self.moduleContext.typechecker!.buildIn {
            result.append(contentsOf: self.moduleContext.typechecker!.buildIn.searchMethods(type, name: name, predicate: predicate))
        }
        
        return result
    }
    
    func searchPrefixOperators(_ op: OperatorToken.Operator, predicate: (PrefixOperatorDefinition) -> Bool) -> [PrefixOperatorId] {
        var result: [PrefixOperatorId] = []
        
        if let self = self as? OperatorDefiningContext {
            if let definitions = self.prefixOperators.cache[op] {
                result.append(contentsOf: definitions.filter({ predicate($0.1) }).map({ $0.0 }))
            }
        }
        
        if parent != nil {
            result.append(contentsOf: parent!.searchPrefixOperators(op, predicate: predicate))
        }
        
        if self is ModuleContext, self !== self.moduleContext.typechecker!.buildIn {
            result.append(contentsOf: self.moduleContext.typechecker!.buildIn.searchPrefixOperators(op, predicate: predicate))
        }
        
        return result
    }
    
    func searchOperators(_ op: OperatorToken.Operator, predicate: (OperatorDefinition) -> Bool) -> [OperatorId] {
        var result: [OperatorId] = []
        
        if let self = self as? OperatorDefiningContext {
            if let definitions = self.operators.cache[op] {
                result.append(contentsOf: definitions.filter({ predicate($0.1) }).map({ $0.0 }))
            }
        }
        
        if parent != nil {
            result.append(contentsOf: parent!.searchOperators(op, predicate: predicate))
        }
        
        if self is ModuleContext, self !== self.moduleContext.typechecker!.buildIn {
            result.append(contentsOf: self.moduleContext.typechecker!.buildIn.searchOperators(op, predicate: predicate))
        }
        
        return result
    }
    
    func lookupVariable(_ name: String) -> VariableDefinition? {
        if let self = self as? FunctionBodyContext {
            if let definitions = self.variables.lookup[name] {
                return definitions
            }
        }
        
        if parent != nil {
            return parent!.lookupVariable(name)
        }
        
        if let self = self as? ModuleContext, self !== self.typechecker!.modules.first {
            return self.typechecker!.modules.first!.lookupVariable(name)
        }
        
        return nil
    }
}

public protocol FunctionDefiningContext: Context {
    var functions: (lookup: [FunctionId: FunctionDefinition], cache: [String: [(FunctionId, FunctionDefinition)]], locations: [FunctionId: SourceElement]) { get set }
}

extension FunctionDefiningContext {
    @discardableResult
    func register(_ functionDefinition: FunctionDefinition, from sourceElement: SourceElement?) throws -> FunctionId {
        if let definition = self.functions.lookup.first(where: { functionDefinition.equals($0.value) }) {
            throw ParserError.redeclaration(name: "function", existing: self.functions.locations[definition.key], new: sourceElement!)
        }
        
        let functionId = FunctionId(uuid: codeGen.newUUID(), context: self)
        functions.lookup[functionId] = functionDefinition
        functions.cache[functionDefinition.name, default: []].append((functionId, functionDefinition))
        
        if let sourceElement = sourceElement {
            functions.locations[functionId] = sourceElement
        }
        
        return functionId
    }
}

public protocol MethodDefiningContext: Context {
    var type: TypeId { get }
    var methods: (lookup: [MethodId: MethodDefinition], cache: [String: [(MethodId, MethodDefinition)]], locations: [MethodId: SourceElement]) { get set }
}

extension MethodDefiningContext {
    @discardableResult
    func register(_ methodDefinition: MethodDefinition, from sourceElement: SourceElement?) throws -> MethodId {
        if let definition = self.methods.lookup.first(where: { methodDefinition.equals($0.value) }) {
            throw ParserError.redeclaration(name: "method", existing: self.methods.locations[definition.key], new: sourceElement!)
        }
        
        let methodId = MethodId(uuid: codeGen.newUUID(), context: self)
        methods.lookup[methodId] = methodDefinition
        methods.cache[methodDefinition.name, default: []].append((methodId, methodDefinition))
        
        if let sourceElement = sourceElement {
            methods.locations[methodId] = sourceElement
        }
        
        return methodId
    }
}

public protocol StructDefiningContext: Context {
    var structs: (lookup: [TypeId: StructDefinition], locations: [TypeId: SourceElement], contexts: [TypeId: MethodDefiningContext]) { get set }
}

extension StructDefiningContext {
    @discardableResult
    func register(_ structDefinition: StructDefinition, from sourceElement: SourceElement?) throws -> TypeId {
        if let definition = self.structs.lookup.first(where: { $0.value.name == structDefinition.name }) {
            throw ParserError.redeclaration(name: "struct", existing: self.structs.locations[definition.key], new: sourceElement!)
        }
        
        let typeId = TypeId(uuid: codeGen.newUUID(), context: self)
        structs.lookup[typeId] = structDefinition
        structs.contexts[typeId] = try! MethodContext(type: typeId, codeGen: codeGen, parent: self)
        
        if let sourceElement = sourceElement {
            structs.locations[typeId] = sourceElement
        }
        
        return typeId
    }
}

public protocol OperatorDefiningContext: Context {
    var prefixOperators: (lookup: [PrefixOperatorId: PrefixOperatorDefinition], cache: [OperatorToken.Operator: [(PrefixOperatorId, PrefixOperatorDefinition)]], locations: [PrefixOperatorId: SourceElement]) { get set }
    var operators: (lookup: [OperatorId: OperatorDefinition], cache: [OperatorToken.Operator: [(OperatorId, OperatorDefinition)]], locations: [OperatorId: SourceElement]) { get set }
}

extension OperatorDefiningContext {
    @discardableResult
    func register(_ operatorDefinition: PrefixOperatorDefinition, from sourceElement: SourceElement?) throws -> PrefixOperatorId {
        if let definition = self.prefixOperators.lookup.first(where: { operatorDefinition.equals($0.value) }) {
            throw ParserError.redeclaration(name: "operator", existing: self.prefixOperators.locations[definition.key], new: sourceElement!)
        }
        
        let prefixOperatorId = PrefixOperatorId(uuid: codeGen.newUUID(), context: self)
        prefixOperators.lookup[prefixOperatorId] = operatorDefinition
        prefixOperators.cache[operatorDefinition.op, default: []].append((prefixOperatorId, operatorDefinition))
        
        if let sourceElement = sourceElement {
            prefixOperators.locations[prefixOperatorId] = sourceElement
        }
        
        return prefixOperatorId
    }
    
    @discardableResult
    func register(_ operatorDefinition: OperatorDefinition, from sourceElement: SourceElement?) throws -> OperatorId {
        if let definition = self.operators.lookup.first(where: { operatorDefinition.equals($0.value) }) {
            throw ParserError.redeclaration(name: "operator", existing: self.operators.locations[definition.key], new: sourceElement!)
        }
        
        let operatorId = OperatorId(uuid: codeGen.newUUID(), context: self)
        operators.lookup[operatorId] = operatorDefinition
        operators.cache[operatorDefinition.op, default: []].append((operatorId, operatorDefinition))
        
        if let sourceElement = sourceElement {
            operators.locations[operatorId] = sourceElement
        }
        
        return operatorId
    }
}

public protocol FunctionBodyContext: Context {
    var isImpure: Bool { get }
    var variables: (lookup: [String: VariableDefinition], locations: [String: SourceElement]) { get set }
}

extension FunctionBodyContext {
    func register(variable: VariableDefinition, from sourceElement: SourceElement?) throws {
        if self.variables.lookup[variable.name] != nil {
            throw ParserError.redeclaration(name: "variable", existing: self.variables.locations[variable.name], new: sourceElement!)
        }
        
        variables.lookup[variable.name] = variable
        
        if let sourceElement = sourceElement {
            variables.locations[variable.name] = sourceElement
        }
    }
}
