import Foundation
import CheckedScanner
import parser

@main
public struct checked {
    public static func main() throws {
        guard let command = ProcessInfo.processInfo.arguments.dropFirst().first else {
            fatalError("No command given")
        }
        
        switch command {
        case "tokens":
            guard let name = ProcessInfo.processInfo.arguments.dropFirst(2).first else {
                fatalError("No file given")
            }
            
            let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(name)
            guard FileManager.default.fileExists(atPath: url.path) else {
                fatalError("File \(url) does not exist")
            }
            
            do {
                print(try CheckedScanner.parse(file: url).tokens.map(\.description).joined(separator: " "))
            } catch {
                if let sourceError = error as? SourceFileError {
                    let location = sourceError.sourceFileLocation
                    print("error in file \(name):\(location.line):\(location.column):")
                    print("")
                    print("")
                    print(sourceError.description)
                    
                    exit(EXIT_FAILURE)
                } else {
                    throw error
                }
            }
        case "ast":
            guard let name = ProcessInfo.processInfo.arguments.dropFirst(2).first else {
                fatalError("No file given")
            }
            
            let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(name)
            guard FileManager.default.fileExists(atPath: url.path) else {
                fatalError("File \(url) does not exist")
            }
            
            let module = url.deletingLastPathComponent().lastPathComponent
            let files = FileManager.default.directoryContents(at: url.deletingLastPathComponent()).filter({ $0.pathExtension == "checked" })
            
            do {
                let topLevelDeclarations = try files.map { url -> TopLevelDeclaration in
                    return try Parser.parse(file: url)
                }
                
                let typechecker = Typechecker()
                let module = try ModuleContext(name: module, codeGen: typechecker.codeGen)
                typechecker.add(module: module)
                
                print(try typechecker.typecheck(topLevelDeclarations, in: module).first(where: { $0.file == url })!.description)
            } catch {
                if let sourceError = error as? SourceFileError {
                    let location = sourceError.sourceFileLocation
                    print("error in file \(name):\(location.line):\(location.column):")
                    print("")
                    print("")
                    print(sourceError.description)
                    
                    exit(EXIT_FAILURE)
                } else {
                    throw error
                }
            }
        case "build":
            guard let name = ProcessInfo.processInfo.arguments.dropFirst(2).first else {
                fatalError("No file given")
            }
            
            let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(name)
            guard FileManager.default.fileExists(atPath: url.path) else {
                fatalError("File \(url) does not exist")
            }
            
            let module = url.deletingLastPathComponent().lastPathComponent
            let files = FileManager.default.directoryContents(at: url.deletingLastPathComponent()).filter({ $0.pathExtension == "checked" })
            
            do {
                let topLevelDeclarations = try files.map { url -> TopLevelDeclaration in
                    return try Parser.parse(file: url)
                }
                
                let typechecker = Typechecker()
                let module = try ModuleContext(name: module, codeGen: typechecker.codeGen)
                typechecker.add(module: module)
                
                let typechecked = try typechecker.typecheck(topLevelDeclarations, in: module)
                try typechecker.codeGen.gen(typechecked)
            } catch {
                if let sourceError = error as? SourceFileError {
                    let location = sourceError.sourceFileLocation
                    print("error in file \(name):\(location.line):\(location.column):")
                    print("")
                    print("")
                    print(sourceError.description)
                    
                    exit(EXIT_FAILURE)
                } else {
                    throw error
                }
            }
        default:
            fatalError("Invalid command \(command)")
        }
    }
}
