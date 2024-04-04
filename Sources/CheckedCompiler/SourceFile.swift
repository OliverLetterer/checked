//
//  File.swift
//
//
//  Copyright 2024 Oliver Letterer
//

import Foundation

public enum CheckedSourceFileError: Error, CheckedError {
    case fileDoesNotExist(file: URL)
    case invalidUTF8Encoding(file: URL)
    case noNewLineAtEndOfFile(file: URL)
    
    public var failureReason: String {
        switch self {
        case let .fileDoesNotExist(file):
            return "File does not exist: \(file)"
        case let .invalidUTF8Encoding(file):
            return "File \(file) has invalid encoding"
        case let .noNewLineAtEndOfFile(file):
            return "No new line at end of file: \(file)"
        }
    }
}

public struct SourceFile {
    public struct Line {
        public var string: String
        public var startOffset: UInt64
        public var endOffset: UInt64
    }
    
    public var file: URL
    public var source: String
    public var lines:  [Line]
    
    public init(file: URL) throws {
        guard let data = try? Data(contentsOf: file) else {
            throw CheckedSourceFileError.fileDoesNotExist(file: file)
        }
        
        guard let source = String(data: data, encoding: .utf8) else {
            throw CheckedSourceFileError.invalidUTF8Encoding(file: file)
        }
        
        var lines: [Line] = []
        
        var lastLineOffset = 0
        for offset in 0..<(data.count) {
            if data[offset] == "\n".data(using: .utf8)![0] {
                lines.append(Line(string: String(data: data[lastLineOffset..<offset], encoding: .utf8)!, startOffset: UInt64(lastLineOffset), endOffset: UInt64(offset + 1)))
                lastLineOffset = offset + 1
            }
        }
        
        guard lastLineOffset == data.count else {
            throw CheckedSourceFileError.noNewLineAtEndOfFile(file: file)
        }
        
        self.file = file
        self.source = source
        self.lines = lines
    }
}
