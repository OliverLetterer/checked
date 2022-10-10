//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

public protocol SourceFileError: Error, SourceElement {
    var failureReason: String { get }
}

extension SourceFileError {
    private var sourceSnippet: String {
        guard let data = FileManager.default.contents(atPath: file.path), let source = String(data: data, encoding: .utf8) else {
            fatalError("file \(file) does not exist")
        }
        
        var currentIndex: Int = 0
        var snippetStart: String.Index = source.startIndex
        var stringIndex: String.Index = source.startIndex
        
        while currentIndex < location.lowerBound {
            let character = source[stringIndex]
            
            currentIndex += 1
            stringIndex = source.index(after: stringIndex)
            
            if character == "\n" {
                snippetStart = stringIndex
            }
        }
        
        let rangeStart: String.Index = stringIndex
        
        while currentIndex < location.upperBound {
            currentIndex += 1
            stringIndex = source.index(after: stringIndex)
        }
        
        let rangeEnd: String.Index = stringIndex
        var snippetEnd: String.Index = rangeEnd
        
        while snippetEnd < source.endIndex {
            if source[snippetEnd] == "\n" {
                break
            }
            
            snippetEnd = source.index(after: snippetEnd)
        }
        
        return String(source[snippetStart..<rangeStart]) + String(source[rangeStart..<rangeEnd]).red + String(source[rangeEnd..<snippetEnd])
    }
    
    public var description: String {
        let sourceSnippet: String = self.sourceSnippet
        let description: String = String(repeating: " ", count: sourceFileLocation.column - 1) + "^ \(type(of: self)): " + failureReason
        return sourceSnippet + "\n" + description
    }
}
