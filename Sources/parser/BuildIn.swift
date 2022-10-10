//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

class BuildIn: ModuleContext, CodeGenerator {
    public private(set) var `Void`: TypeId! = nil
    public private(set) var `Int8`: TypeId! = nil
    public private(set) var `Int16`: TypeId! = nil
    public private(set) var `Int32`: TypeId! = nil
    public private(set) var `Int64`: TypeId! = nil
    public private(set) var `UInt8`: TypeId! = nil
    public private(set) var `UInt16`: TypeId! = nil
    public private(set) var `UInt32`: TypeId! = nil
    public private(set) var `UInt64`: TypeId! = nil
    public private(set) var `Bool`: TypeId! = nil
    public private(set) var `Float`: TypeId! = nil
    public private(set) var `Double`: TypeId! = nil
    public private(set) var `String`: TypeId! = nil
    
    static func buildIn(codeGen: CodeGen) -> BuildIn {
        return try! BuildIn(name: "BuildIn", codeGen: codeGen)
    }
    
    private var prefixOperatorCodeGen: [PrefixOperatorDefinition: (String) -> String] = [:]
    private var operatorCodeGen: [OperatorDefinition: (String, String) -> String] = [:]
    private var functionCodeGen: [FunctionDefinition: ([String]) -> String] = [:]
    private var methodCodeGen: [MethodDefinition: (String, [String]) -> String] = [:]
    
    override init(name: String, codeGen: CodeGen) throws {
        try super.init(name: name, codeGen: codeGen)
        
        self.Void = try! self.register(StructDefinition(name: "Void"), from: nil)
        self.Int8 = try! self.register(StructDefinition(name: "Int8"), from: nil)
        self.Int16 = try! self.register(StructDefinition(name: "Int16"), from: nil)
        self.Int32 = try! self.register(StructDefinition(name: "Int32"), from: nil)
        self.Int64 = try! self.register(StructDefinition(name: "Int64"), from: nil)
        self.UInt8 = try! self.register(StructDefinition(name: "UInt8"), from: nil)
        self.UInt16 = try! self.register(StructDefinition(name: "UInt16"), from: nil)
        self.UInt32 = try! self.register(StructDefinition(name: "UInt32"), from: nil)
        self.UInt64 = try! self.register(StructDefinition(name: "UInt64"), from: nil)
        self.Bool = try! self.register(StructDefinition(name: "Bool"), from: nil)
        self.Float = try! self.register(StructDefinition(name: "Float"), from: nil)
        self.Double = try! self.register(StructDefinition(name: "Double"), from: nil)
        self.String = try! self.register(StructDefinition(name: "String"), from: nil)
        
        for primitive in [self.Int8, self.Int16, self.Int32, self.Int64, self.UInt8, self.UInt16, self.UInt32, self.UInt64, self.Bool, self.Float, self.Double] as [TypeId] {
            try! self.register(OperatorDefinition(op: .equal, lhs: .init(typeReference: primitive), rhs: .init(typeReference: primitive), returns: self.Bool)) { $0 + " == " + $1 }
        }
        
        for integer in [self.Int8, self.Int16, self.Int32, self.Int64, self.UInt8, self.UInt16, self.UInt32, self.UInt64] as [TypeId] {
            try! self.register(OperatorDefinition(op: .binaryAnd, lhs: .init(typeReference: integer), rhs: .init(typeReference: integer), returns: integer)) { $0 + " & " + $1 }
            try! self.register(OperatorDefinition(op: .binaryOr, lhs: .init(typeReference: integer), rhs: .init(typeReference: integer), returns: integer)) { $0 + " | " + $1 }
            try! self.register(OperatorDefinition(op: .binaryXor, lhs: .init(typeReference: integer), rhs: .init(typeReference: integer), returns: integer)) { $0 + " ^ " + $1 }
            try! self.register(OperatorDefinition(op: .modulo, lhs: .init(typeReference: integer), rhs: .init(typeReference: integer), returns: integer)) { $0 + " % " + $1 }
        }
        
        for comparable in [self.Int8, self.Int16, self.Int32, self.Int64, self.UInt8, self.UInt16, self.UInt32, self.UInt64, self.Float, self.Double] as [TypeId] {
            try! self.register(OperatorDefinition(op: .plus, lhs: .init(typeReference: comparable), rhs: .init(typeReference: comparable), returns: comparable)) { $0 + " + " + $1 }
            try! self.register(OperatorDefinition(op: .minus, lhs: .init(typeReference: comparable), rhs: .init(typeReference: comparable), returns: comparable)) { $0 + " - " + $1 }
            try! self.register(OperatorDefinition(op: .times, lhs: .init(typeReference: comparable), rhs: .init(typeReference: comparable), returns: comparable)) { $0 + " * " + $1 }
            try! self.register(OperatorDefinition(op: .division, lhs: .init(typeReference: comparable), rhs: .init(typeReference: comparable), returns: comparable)) { $0 + " / " + $1 }
            try! self.register(OperatorDefinition(op: .greater, lhs: .init(typeReference: comparable), rhs: .init(typeReference: comparable), returns: self.Bool)) { $0 + " > " + $1 }
            try! self.register(OperatorDefinition(op: .greaterEqual, lhs: .init(typeReference: comparable), rhs: .init(typeReference: comparable), returns: self.Bool)) { $0 + " >= " + $1 }
            try! self.register(OperatorDefinition(op: .smaller, lhs: .init(typeReference: comparable), rhs: .init(typeReference: comparable), returns: self.Bool)) { $0 + " < " + $1 }
            try! self.register(OperatorDefinition(op: .smallerEqual, lhs: .init(typeReference: comparable), rhs: .init(typeReference: comparable), returns: self.Bool)) { $0 + " <= " + $1 }
        }
        
        try! self.register(PrefixOperatorDefinition(op: .not, argument: .init(typeReference: self.Bool), returns: self.Bool)) { "!" + $0 }
        
        try! self.register(OperatorDefinition(op: .and, lhs: .init(typeReference: self.Bool), rhs: .init(typeReference: self.Bool), returns: self.Bool)) { $0 + " && " + $1 }
        try! self.register(OperatorDefinition(op: .or, lhs: .init(typeReference: self.Bool), rhs: .init(typeReference: self.Bool), returns: self.Bool)) { $0 + " || " + $1 }
        
        try! self.register(OperatorDefinition(op: .plus, lhs: .init(typeReference: self.String), rhs: .init(typeReference: self.String), returns: self.String)) { "String_add(\($0), \($1))" }
        
        try! self.register(type: self.String, MethodDefinition(name: "replacing", arguments: [ .init(name: "occurrenceOf", typeReference: self.String), .init(name: "with", typeReference: self.String) ], returns: self.String)) { "String_replacingOccurenceOfWith(\($0), \($1.joined(separator: ", ")))" }
    }
    
    private func register(_ operatorDefinition: PrefixOperatorDefinition, codeGen: @escaping (String) -> String) throws {
        try register(operatorDefinition, from: nil)
        self.prefixOperatorCodeGen[operatorDefinition] = codeGen
    }
    
    private func register(_ operatorDefinition: OperatorDefinition, codeGen: @escaping (String, String) -> String) throws {
        try register(operatorDefinition, from: nil)
        self.operatorCodeGen[operatorDefinition] = codeGen
    }
    
    private func register(_ functionDefinition: FunctionDefinition, codeGen: @escaping ([String]) -> String) throws {
        try register(functionDefinition, from: nil)
        self.functionCodeGen[functionDefinition] = codeGen
    }
    
    private func register(type: TypeId, _ methodDefinition: MethodDefinition, codeGen: @escaping (String, [String]) -> String) throws {
        try structs.contexts[type]!.register(methodDefinition, from: nil)
        self.methodCodeGen[methodDefinition] = codeGen
    }
    
    func implement(codeGen: CodeGen) {
        codeGen.header.append("""
        typedef struct Object {
            atomic_bool lock;
            u_int64_t ref_count;
        } Object;
        
        typedef struct String {
            atomic_bool lock;
            u_int64_t ref_count;
            u_int64_t count;
            u_int8_t bytes[];
        } String;
        """)
        
        codeGen.header.append("""
        static inline bool object_lock(Object *object) {
            bool expected = false;
            return atomic_compare_exchange_strong(&object->lock, &expected, true);
        }

        static inline void object_unlock(Object *object) {
            atomic_store(&object->lock, false);
        }

        static inline void object_release(void *object) {
            while (!object_lock((Object *)object)) {
            }

            ((Object *)object)->ref_count -= 1;
            const bool shouldFree = ((Object *)object)->ref_count == 0;
                
            object_unlock((Object *)object);

            if (shouldFree) {
                free(object);
            }
        }

        static inline void object_retain(void *object) {
            while (!object_lock((Object *)object)) {
            }

            ((Object *)object)->ref_count += 1;
                
            object_unlock((Object *)object);
        }
        
        static inline String *String_add(const String *lhs, const String *rhs) {
            String *result = malloc(sizeof(Object) + sizeof(u_int64_t) + (size_t)lhs->count + (size_t)rhs->count);
            result->lock = false;
            result->ref_count = 1;
            result->count = lhs->count + rhs->count;
            memcpy(result->bytes, lhs->bytes, (size_t)lhs->count);
            memcpy(result->bytes + lhs->count, rhs->bytes, (size_t)rhs->count);
            return result;
        }
        
        static String* String_replacingOccurenceOfWith(const String *self, const String *occurence, const String *with) {
            if (occurence->count > self->count) {
                String *result = malloc(sizeof(Object) + sizeof(u_int64_t) + (size_t)self->count);
                result->lock = false;
                result->ref_count = 1;
                result->count = self->count;
                memcpy(result->bytes, self->bytes, (size_t)self->count);
                return result;
            }
            
            u_int64_t matches = 0;
            u_int64_t index = 0;
            while (index < self->count - occurence->count) {
                bool matched = true;
                
                u_int64_t occurenceIndex = 0;
                while (matched && occurenceIndex < occurence->count) {
                    if (self->bytes[index + occurenceIndex] != occurence->bytes[occurenceIndex]) {
                        matched = false;
                    }
                    
                    occurenceIndex += 1;
                }
                
                if (matched) {
                    matches += 1;
                    index += occurence->count;
                } else {
                    index += 1;
                }
            }
            
            int64_t difference = ((int64_t)matches) * (((int64_t)with->count) - ((int64_t)occurence->count));
            String *result = malloc(sizeof(Object) + sizeof(u_int64_t) + (size_t)self->count + difference);
            result->lock = false;
            result->ref_count = 1;
            result->count = (u_int64_t)(self->count + difference);
            
            u_int64_t selfIndex = 0;
            u_int64_t copyIndex = 0;
            while (copyIndex < result->count) {
                bool matched = true;
                
                u_int64_t occurenceIndex = 0;
                while (matched && occurenceIndex < occurence->count) {
                    if (self->bytes[selfIndex + occurenceIndex] != occurence->bytes[occurenceIndex]) {
                        matched = false;
                    }
                    
                    occurenceIndex += 1;
                }
                
                if (matched) {
                    for (u_int64_t withIndex = 0; withIndex < with->count; withIndex++) {
                        result->bytes[copyIndex + withIndex] = with->bytes[withIndex];
                    }
                    
                    selfIndex += occurence->count;
                    copyIndex += with->count;
                } else {
                    result->bytes[copyIndex] = self->bytes[selfIndex];
                    
                    selfIndex += 1;
                    copyIndex += 1;
                }
            }
            
            return result;
        }
        """)
    }
}

extension BuildIn {
    func declare(reference: TypeId) -> String {
        switch reference {
        case self.Void: return "void"
        case self.Int8: return "int8_t"
        case self.Int16: return "int16_t"
        case self.Int32: return "int32_t"
        case self.Int64: return "int64_t"
        case self.UInt8: return "u_int8_t"
        case self.UInt16: return "u_int16_t"
        case self.UInt32: return "u_int32_t"
        case self.UInt64: return "u_int64_t"
        case self.Bool: return "bool"
        case self.Float: return "float"
        case self.Double: return "double"
        case self.String: return "String *"
        default: fatalError()
        }
    }
    
    func implement(floatingPointLiteral: String, for typeId: TypeId) -> String {
        switch typeId {
        case self.Float: return "(float)" + floatingPointLiteral + "f"
        case self.Double: return "(double)" + floatingPointLiteral
        default: fatalError()
        }
    }
    
    func implement(integerLiteral: String, for typeId: TypeId) -> String {
        switch typeId {
        case self.Int8: return "(int8_t)" + integerLiteral
        case self.Int16: return "(int16_t)" + integerLiteral
        case self.Int32: return "(int32_t)" + integerLiteral
        case self.Int64: return "(int64_t)" + integerLiteral
        case self.UInt8: return "(u_int8_t)" + integerLiteral
        case self.UInt16: return "(u_int16_t)" + integerLiteral
        case self.UInt32: return "(u_int32_t)" + integerLiteral
        case self.UInt64: return "(u_int64_t)" + integerLiteral
        default: fatalError()
        }
    }
    
    func implement(stringLiteral: String, codeGen: CodeGen) -> String {
        let name = codeGen.newVariable()
        let data = stringLiteral.data(using: .utf8)!
        codeGen.implementation.append("""
        static String \(name) = { false, 1, \(data.count), { \(data.map(\.description).joined(separator: ", ")) } };
        """)
        
        return "&" + name
    }
    
    func isRefCounted(_ typeId: TypeId) -> Bool {
        switch typeId {
        case self.String: return true
        default: return false
        }
    }
    
    func call(_ operatorDefinition: PrefixOperatorDefinition, argument: String) -> String {
        return prefixOperatorCodeGen[operatorDefinition]!(argument)
    }
    
    func call(_ operatorDefinition: OperatorDefinition, lhs: String, rhs: String) -> String {
        return operatorCodeGen[operatorDefinition]!(lhs, rhs)
    }
    
    func call(_ functionDefinition: FunctionDefinition, arguments: [String]) -> String {
        return functionCodeGen[functionDefinition]!(arguments)
    }
    
    func call(_ methodDefinition: MethodDefinition, instance: String, arguments: [String]) -> String {
        return methodCodeGen[methodDefinition]!(instance, arguments)
    }
}
