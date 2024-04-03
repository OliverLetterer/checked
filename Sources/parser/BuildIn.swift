//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

protocol NativeType {
    init?(_ string: String)
    var description: String { get }
}

protocol NativeEquatable: NativeType, Equatable {
    
}

protocol NativeInteger: NativeEquatable, Comparable {
    static func &(_ lhs: Self, _ rhs: Self) -> Self
    static func |(_ lhs: Self, _ rhs: Self) -> Self
    static func ^(_ lhs: Self, _ rhs: Self) -> Self
    static func %(_ lhs: Self, _ rhs: Self) -> Self
    
    func addingReportingOverflow(_ other: Self) -> (partialValue: Self, overflow: Swift.Bool)
    func subtractingReportingOverflow(_ other: Self) -> (partialValue: Self, overflow: Bool)
    func multipliedReportingOverflow(by other: Self) -> (partialValue: Self, overflow: Bool)
    func dividedReportingOverflow(by other: Self) -> (partialValue: Self, overflow: Bool)
}

protocol NativeArithmetic: NativeEquatable, Comparable {
    static func +(_ lhs: Self, _ rhs: Self) -> Self
    static func -(_ lhs: Self, _ rhs: Self) -> Self
    static func *(_ lhs: Self, _ rhs: Self) -> Self
    static func /(_ lhs: Self, _ rhs: Self) -> Self
}

extension Int8: NativeEquatable, NativeInteger, NativeArithmetic { }
extension Int16: NativeEquatable, NativeInteger, NativeArithmetic { }
extension Int32: NativeEquatable, NativeInteger, NativeArithmetic { }
extension Int64: NativeEquatable, NativeInteger, NativeArithmetic { }
extension UInt8: NativeEquatable, NativeInteger, NativeArithmetic { }
extension UInt16: NativeEquatable, NativeInteger, NativeArithmetic { }
extension UInt32: NativeEquatable, NativeInteger, NativeArithmetic { }
extension UInt64: NativeEquatable, NativeInteger, NativeArithmetic { }
extension Bool: NativeEquatable { }
extension Float: NativeEquatable, NativeArithmetic { }
extension Double: NativeEquatable, NativeArithmetic { }

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
    
    private var prefixOperatorCode: [PrefixOperatorId: (CompileTimeExpression) throws -> CompileTimeExpression] = [:]
    private var operatorCode: [OperatorId: (CompileTimeExpression, CompileTimeExpression) throws -> CompileTimeExpression] = [:]
    private var functionCode: [FunctionId: ([CompileTimeExpression]) throws -> CompileTimeExpression] = [:]
    private var methodCode: [MethodId: (CompileTimeExpression, [CompileTimeExpression]) throws -> CompileTimeExpression] = [:]
    
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
        
        func registerInteger<T: NativeInteger>(integer: TypeId, native: T.Type) {
            try! self.register(OperatorDefinition(op: .binaryAnd, isImpure: false, lhs: .init(typeReference: integer), rhs: .init(typeReference: integer), returns: integer)) { $0 + " & " + $1 } code: { lhs, rhs in
                return .integerLiteral(literal: (T(lhs.integerLiteral)! & T(rhs.integerLiteral)!).description, returns: integer)
            }
            
            try! self.register(OperatorDefinition(op: .binaryOr, isImpure: false, lhs: .init(typeReference: integer), rhs: .init(typeReference: integer), returns: integer)) { $0 + " | " + $1 } code: { lhs, rhs in
                return .integerLiteral(literal: (T(lhs.integerLiteral)! | T(rhs.integerLiteral)!).description, returns: integer)
            }
            
            try! self.register(OperatorDefinition(op: .binaryXor, isImpure: false, lhs: .init(typeReference: integer), rhs: .init(typeReference: integer), returns: integer)) { $0 + " ^ " + $1 } code: { lhs, rhs in
                return .integerLiteral(literal: (T(lhs.integerLiteral)! ^ T(rhs.integerLiteral)!).description, returns: integer)
            }
            
            try! self.register(OperatorDefinition(op: .modulo, isImpure: false, lhs: .init(typeReference: integer), rhs: .init(typeReference: integer), returns: integer)) { $0 + " % " + $1 } code: { lhs, rhs in
                return .integerLiteral(literal: (T(lhs.integerLiteral)! % T(rhs.integerLiteral)!).description, returns: integer)
            }
            
            try! self.register(OperatorDefinition(op: .plus, isImpure: false, lhs: .init(typeReference: integer), rhs: .init(typeReference: integer), returns: integer)) { $0 + " + " + $1 } code: { lhs, rhs in
                let (result, overflow) = T(lhs.integerLiteral)!.addingReportingOverflow(T(rhs.integerLiteral)!)
                
                if overflow {
                    throw CodeGenError.notRepresentable(value: "\(lhs.integerLiteral) + \(rhs.integerLiteral)", type: "\(T.self)")
                } else {
                    return .integerLiteral(literal: result.description, returns: integer)
                }
            }
            
            try! self.register(OperatorDefinition(op: .minus, isImpure: false, lhs: .init(typeReference: integer), rhs: .init(typeReference: integer), returns: integer)) { $0 + " - " + $1 } code: { lhs, rhs in
                let (result, overflow) = T(lhs.integerLiteral)!.subtractingReportingOverflow(T(rhs.integerLiteral)!)
                
                if overflow {
                    throw CodeGenError.notRepresentable(value: "\(lhs.integerLiteral) - \(rhs.integerLiteral)", type: "\(T.self)")
                } else {
                    return .integerLiteral(literal: result.description, returns: integer)
                }
            }
            
            try! self.register(OperatorDefinition(op: .times, isImpure: false, lhs: .init(typeReference: integer), rhs: .init(typeReference: integer), returns: integer)) { $0 + " * " + $1 } code: { lhs, rhs in
                let (result, overflow) = T(lhs.integerLiteral)!.multipliedReportingOverflow(by: T(rhs.integerLiteral)!)
                
                if overflow {
                    throw CodeGenError.notRepresentable(value: "\(lhs.integerLiteral) * \(rhs.integerLiteral)", type: "\(T.self)")
                } else {
                    return .integerLiteral(literal: result.description, returns: integer)
                }
            }
            
            try! self.register(OperatorDefinition(op: .division, isImpure: false, lhs: .init(typeReference: integer), rhs: .init(typeReference: integer), returns: integer)) { $0 + " / " + $1 } code: { lhs, rhs in
                let (result, overflow) = T(lhs.integerLiteral)!.dividedReportingOverflow(by: T(rhs.integerLiteral)!)
                
                if overflow {
                    throw CodeGenError.notRepresentable(value: "\(lhs.integerLiteral) / \(rhs.integerLiteral)", type: "\(T.self)")
                } else {
                    return .integerLiteral(literal: result.description, returns: integer)
                }
            }
            
            try! self.register(OperatorDefinition(op: .equal, isImpure: false, lhs: .init(typeReference: integer), rhs: .init(typeReference: integer), returns: self.Bool)) { $0 + " == " + $1 } code: { lhs, rhs in
                return .booleanLiteral(literal: T(lhs.integerLiteral)! == T(rhs.integerLiteral)!, returns: self.Bool)
            }
            
            try! self.register(OperatorDefinition(op: .greater, isImpure: false, lhs: .init(typeReference: integer), rhs: .init(typeReference: integer), returns: self.Bool)) { $0 + " > " + $1 } code: { lhs, rhs in
                return .booleanLiteral(literal: T(lhs.integerLiteral)! > T(rhs.integerLiteral)!, returns: self.Bool)
            }
            
            try! self.register(OperatorDefinition(op: .greaterEqual, isImpure: false, lhs: .init(typeReference: integer), rhs: .init(typeReference: integer), returns: self.Bool)) { $0 + " >= " + $1 } code: { lhs, rhs in
                return .booleanLiteral(literal: T(lhs.integerLiteral)! >= T(rhs.integerLiteral)!, returns: self.Bool)
            }
            
            try! self.register(OperatorDefinition(op: .smaller, isImpure: false, lhs: .init(typeReference: integer), rhs: .init(typeReference: integer), returns: self.Bool)) { $0 + " < " + $1 } code: { lhs, rhs in
                return .booleanLiteral(literal: T(lhs.integerLiteral)! < T(rhs.integerLiteral)!, returns: self.Bool)
            }
            
            try! self.register(OperatorDefinition(op: .smallerEqual, isImpure: false, lhs: .init(typeReference: integer), rhs: .init(typeReference: integer), returns: self.Bool)) { $0 + " <= " + $1 } code: { lhs, rhs in
                return .booleanLiteral(literal: T(lhs.integerLiteral)! <= T(rhs.integerLiteral)!, returns: self.Bool)
            }
        }
        
        registerInteger(integer: self.Int8, native: Swift.Int8.self)
        registerInteger(integer: self.Int16, native: Swift.Int16.self)
        registerInteger(integer: self.Int32, native: Swift.Int32.self)
        registerInteger(integer: self.Int64, native: Swift.Int64.self)
        registerInteger(integer: self.UInt8, native: Swift.UInt8.self)
        registerInteger(integer: self.UInt16, native: Swift.UInt16.self)
        registerInteger(integer: self.UInt32, native: Swift.UInt32.self)
        registerInteger(integer: self.UInt64, native: Swift.UInt64.self)
        
        func registerArithmetic<T: NativeArithmetic>(arithmetic: TypeId, native: T.Type) {
            try! self.register(OperatorDefinition(op: .plus, isImpure: false, lhs: .init(typeReference: arithmetic), rhs: .init(typeReference: arithmetic), returns: arithmetic)) { $0 + " + " + $1 } code: { lhs, rhs in
                return .floatingPointLiteral(literal: (T(lhs.floatingPointLiteral)! + T(rhs.floatingPointLiteral)!).description, returns: arithmetic)
            }
            
            try! self.register(OperatorDefinition(op: .minus, isImpure: false, lhs: .init(typeReference: arithmetic), rhs: .init(typeReference: arithmetic), returns: arithmetic)) { $0 + " - " + $1 } code: { lhs, rhs in
                return .floatingPointLiteral(literal: (T(lhs.floatingPointLiteral)! - T(rhs.floatingPointLiteral)!).description, returns: arithmetic)
            }
            
            try! self.register(OperatorDefinition(op: .times, isImpure: false, lhs: .init(typeReference: arithmetic), rhs: .init(typeReference: arithmetic), returns: arithmetic)) { $0 + " * " + $1 } code: { lhs, rhs in
                return .floatingPointLiteral(literal: (T(lhs.floatingPointLiteral)! * T(rhs.floatingPointLiteral)!).description, returns: arithmetic)
            }
            
            try! self.register(OperatorDefinition(op: .division, isImpure: false, lhs: .init(typeReference: arithmetic), rhs: .init(typeReference: arithmetic), returns: arithmetic)) { $0 + " / " + $1 } code: { lhs, rhs in
                return .floatingPointLiteral(literal: (T(lhs.floatingPointLiteral)! / T(rhs.floatingPointLiteral)!).description, returns: arithmetic)
            }
            
            try! self.register(OperatorDefinition(op: .equal, isImpure: false, lhs: .init(typeReference: arithmetic), rhs: .init(typeReference: arithmetic), returns: self.Bool)) { $0 + " == " + $1 } code: { lhs, rhs in
                return .booleanLiteral(literal: T(lhs.floatingPointLiteral)! == T(rhs.floatingPointLiteral)!, returns: self.Bool)
            }
            
            try! self.register(OperatorDefinition(op: .greater, isImpure: false, lhs: .init(typeReference: arithmetic), rhs: .init(typeReference: arithmetic), returns: self.Bool)) { $0 + " > " + $1 } code: { lhs, rhs in
                return .booleanLiteral(literal: T(lhs.floatingPointLiteral)! > T(rhs.floatingPointLiteral)!, returns: self.Bool)
            }
            
            try! self.register(OperatorDefinition(op: .greaterEqual, isImpure: false, lhs: .init(typeReference: arithmetic), rhs: .init(typeReference: arithmetic), returns: self.Bool)) { $0 + " >= " + $1 } code: { lhs, rhs in
                return .booleanLiteral(literal: T(lhs.floatingPointLiteral)! >= T(rhs.floatingPointLiteral)!, returns: self.Bool)
            }
            
            try! self.register(OperatorDefinition(op: .smaller, isImpure: false, lhs: .init(typeReference: arithmetic), rhs: .init(typeReference: arithmetic), returns: self.Bool)) { $0 + " < " + $1 } code: { lhs, rhs in
                return .booleanLiteral(literal: T(lhs.floatingPointLiteral)! < T(rhs.floatingPointLiteral)!, returns: self.Bool)
            }
            
            try! self.register(OperatorDefinition(op: .smallerEqual, isImpure: false, lhs: .init(typeReference: arithmetic), rhs: .init(typeReference: arithmetic), returns: self.Bool)) { $0 + " <= " + $1 } code: { lhs, rhs in
                return .booleanLiteral(literal: T(lhs.floatingPointLiteral)! <= T(rhs.floatingPointLiteral)!, returns: self.Bool)
            }
        }
        
        registerArithmetic(arithmetic: self.Float, native: Swift.Float.self)
        registerArithmetic(arithmetic: self.Double, native: Swift.Double.self)
        
        try! self.register(OperatorDefinition(op: .equal, isImpure: false, lhs: .init(typeReference: self.Bool), rhs: .init(typeReference: self.Bool), returns: self.Bool)) { $0 + " == " + $1 } code: { lhs, rhs in
            return .booleanLiteral(literal: lhs.bool == rhs.bool, returns: self.Bool)
        }
        
        try! self.register(PrefixOperatorDefinition(op: .not, isImpure: false, argument: .init(typeReference: self.Bool), returns: self.Bool)) { "!" + $0 } code: { argument in
            return .booleanLiteral(literal: !argument.bool, returns: self.Bool)
        }
        
        try! self.register(OperatorDefinition(op: .and, isImpure: false, lhs: .init(typeReference: self.Bool), rhs: .init(typeReference: self.Bool), returns: self.Bool)) { $0 + " && " + $1 } code: { lhs, rhs in
            return .booleanLiteral(literal: lhs.bool && rhs.bool, returns: self.Bool)
        }
        
        try! self.register(OperatorDefinition(op: .or, isImpure: false, lhs: .init(typeReference: self.Bool), rhs: .init(typeReference: self.Bool), returns: self.Bool)) { $0 + " || " + $1 } code: { lhs, rhs in
            return .booleanLiteral(literal: lhs.bool || rhs.bool, returns: self.Bool)
        }
        
        try! self.register(OperatorDefinition(op: .plus, isImpure: false, lhs: .init(typeReference: self.String), rhs: .init(typeReference: self.String), returns: self.String)) { "String_add(\($0), \($1))" } code: { lhs, rhs in
            return .stringLiteral(literal: lhs.string + rhs.string, returns: self.String)
        }
        
        try! self.register(type: self.String, MethodDefinition(name: "replacing", isImpure: false, arguments: [ .init(name: "occurrenceOf", typeReference: self.String), .init(name: "with", typeReference: self.String) ], returns: self.String)) { "String_replacingOccurenceOfWith(\($0), \($1.joined(separator: ", ")))" } code: { lhs, arguments in
            return .stringLiteral(literal: lhs.string.replacingOccurrences(of: arguments[0].string, with: arguments[1].string), returns: self.String)
        }
        
        try! self.register(FunctionDefinition(name: "print", isImpure: true, arguments: [ .init(typeReference: self.String) ], returns: nil)) { arguments in
            return "print(\(arguments.first!))"
        }
    }
    
    private func register(_ operatorDefinition: PrefixOperatorDefinition, codeGen: @escaping (String) -> String, code: ((CompileTimeExpression) throws -> CompileTimeExpression)? = nil) throws {
        let operatorId = try register(operatorDefinition, from: nil)
        self.prefixOperatorCodeGen[operatorDefinition] = codeGen
        
        if !operatorDefinition.isImpure {
            assert(code != nil)
            self.prefixOperatorCode[operatorId] = code!
        }
    }
    
    private func register(_ operatorDefinition: OperatorDefinition, codeGen: @escaping (String, String) -> String, code: ((CompileTimeExpression, CompileTimeExpression) throws -> CompileTimeExpression)? = nil) throws {
        let operatorId = try register(operatorDefinition, from: nil)
        self.operatorCodeGen[operatorDefinition] = codeGen
        
        if !operatorDefinition.isImpure {
            assert(code != nil)
            self.operatorCode[operatorId] = code!
        }
    }
    
    private func register(_ functionDefinition: FunctionDefinition, codeGen: @escaping ([String]) -> String, code: (([CompileTimeExpression]) throws -> CompileTimeExpression)? = nil) throws {
        let functionId = try register(functionDefinition, from: nil)
        self.functionCodeGen[functionDefinition] = codeGen
        
        if !functionDefinition.isImpure {
            assert(code != nil)
            self.functionCode[functionId] = code!
        }
    }
    
    private func register(type: TypeId, _ methodDefinition: MethodDefinition, codeGen: @escaping (String, [String]) -> String, code: ((CompileTimeExpression, [CompileTimeExpression]) throws -> CompileTimeExpression)? = nil) throws {
        let methodId = try structs.contexts[type]!.register(methodDefinition, from: nil)
        self.methodCodeGen[methodDefinition] = codeGen
        
        if !methodDefinition.isImpure {
            assert(code != nil)
            self.methodCode[methodId] = code!
        }
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
        
        void std_assert(bool condition, const char *conditionExpression, const char *file, int line, int column) {
            if (!condition) {
                exit(EXIT_FAILURE);
            }
        }

        void std_assert_reason(bool condition, const String *reason, const char *conditionExpression, const char *file, int line, int column) {
            if (!condition) {
                exit(EXIT_FAILURE);
            }
        }
        
        static void print(const String *string) {
            #ifdef RELEASE
                write(2, string->bytes, (size_t)string->count);
            #else
                write(1, string->bytes, (size_t)string->count);
            #endif
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
    
    func evaluateCompileTimeOperator(_ op: PrefixOperatorId, argument: CompileTimeExpression) throws -> CompileTimeExpression {
        return try prefixOperatorCode[op]!(argument)
    }
    
    func evaluateCompileTimeOperator(_ op: OperatorId, lhs: CompileTimeExpression, rhs: CompileTimeExpression) throws -> CompileTimeExpression {
        return try operatorCode[op]!(lhs, rhs)
    }
    
    func evaluateCompileTimeFunction(_ function: FunctionId, arguments: [CompileTimeExpression]) throws -> CompileTimeExpression {
        return try functionCode[function]!(arguments)
    }
    
    func evaluateCompileTimeMethod(_ method: MethodId, instance: CompileTimeExpression, arguments: [CompileTimeExpression]) throws -> CompileTimeExpression {
        return try methodCode[method]!(instance, arguments)
    }
}
