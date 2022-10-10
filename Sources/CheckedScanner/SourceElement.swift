//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

public struct SourceFileLocation {
    public var line: Int
    public var column: Int
}

public protocol SourceElement {
    var file: URL { get }
    var location: Range<Int> { get }
}

public extension SourceElement {
    var sourceFileLocation: SourceFileLocation {
        guard let data = FileManager.default.contents(atPath: file.path), let source = String(data: data, encoding: .utf8) else {
            fatalError("file \(file) does not exist")
        }
        
        var line: Int = 1
        var column: Int = 1
        
        var index: Int = 0
        var stringIndex: String.Index = source.startIndex
        while index < location.lowerBound {
            column += 1
            
            if source[stringIndex] == "\n" {
                line += 1
                column = 1
            }
            
            index += 1
            stringIndex = source.index(after: stringIndex)
        }
        
        return SourceFileLocation(line: line, column: column)
    }
    
    var content: String {
        guard let data = FileManager.default.contents(atPath: file.path), let source = String(data: data, encoding: .utf8) else {
            fatalError("file \(file) does not exist")
        }
        
        let start = source.index(source.startIndex, offsetBy: location.lowerBound)
        let end = source.index(source.startIndex, offsetBy: location.upperBound)
        
        return String(source[start..<end])
    }
}
