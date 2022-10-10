//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

public protocol CodeGeneratable: AST {
    func gen(codeGen: CodeGen) throws
}

public class CodeGen {
    internal var header: [String] = []
    internal var implementation: [String] = []
    
    private var uuids: Set<UUID> = []
    private var lock: os_unfair_lock = .init()
    
    private var variableCount: UInt64 = 0
    private var variableLock: os_unfair_lock = .init()
    
    public func newUUID() -> UUID {
        os_unfair_lock_lock(&lock)
        defer {
            os_unfair_lock_unlock(&lock)
        }
        
        var uuid = UUID()
        while uuids.contains(uuid) {
            uuid = UUID()
        }
        
        uuids.insert(uuid)
        return uuid
    }
    
    public func newVariable() -> String {
        os_unfair_lock_lock(&variableLock)
        defer {
            os_unfair_lock_unlock(&variableLock)
        }
        
        let name = "_variable_" + variableCount.description
        variableCount += 1
        return name
    }
    
    public func gen(_ topLevelDeclarations: [TopLevelDeclaration]) throws {
        header.append("""
        #include <stdbool.h>
        #include <stdio.h>
        #include <stdlib.h>
        #include <memory.h>
        #include <stdatomic.h>
        """)

        guard let main: FunctionDeclaration = topLevelDeclarations.flatMap({ $0.functionDeclarations }).first(where: { $0.name.name == "main" && $0.arguments.count == 0 }) else {
            fatalError()
        }

        let buildIn: BuildIn = main.returns!.checked.typechecker.buildIn
        buildIn.implement(codeGen: self)
        
        try topLevelDeclarations.forEach({ try $0.gen(codeGen: self) })
        
        let intTypes: [TypeId] = [ buildIn.Int8, buildIn.Int16, buildIn.Int32, buildIn.Int64, buildIn.UInt8, buildIn.UInt16, buildIn.UInt32, buildIn.UInt64 ]
        if main.returns!.checked.id == main.returns!.checked.typechecker.buildIn.Void {
            implementation.append("""
            int main() {
                \(main.functionDefinition.call(in: main.returns!.checked.context, arguments: []));
                return 0;
            }
            """)
        } else if intTypes.contains(main.returns!.checked.id) {
            implementation.append("""
            int main() {
                return (int)\(main.functionDefinition.call(in: main.returns!.checked.context, arguments: []));
            }
            """)
        } else {
            throw ParserError.invalidMainDeclaration(main: main)
        }

        let source = header.joined(separator: "\n\n") + "\n\n" + implementation.joined(separator: "\n\n")
        print(source)
    }
}
