//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

extension FileManager {
    func directoryContents(at directory: URL) -> [URL] {
        guard let contents = try? contentsOfDirectory(atPath: directory.path) else {
            return []
        }
        
        return contents.flatMap { name -> [URL] in
            let url = directory.appendingPathComponent(name)
            var isDirectory: ObjCBool = false
            guard fileExists(atPath: url.path, isDirectory: &isDirectory) else {
                return []
            }
            
            if isDirectory.boolValue {
                return directoryContents(at: url)
            } else {
                return [ url ]
            }
        }
    }
}
