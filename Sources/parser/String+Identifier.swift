//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

public extension String {
    func toIdentifier() -> String {
        return replacingOccurrences(of: "ae", with: "aeae")
            .replacingOccurrences(of: "oe", with: "oeoe")
            .replacingOccurrences(of: "ue", with: "ueue")
            .replacingOccurrences(of: "AE", with: "AEAE")
            .replacingOccurrences(of: "OE", with: "OEOE")
            .replacingOccurrences(of: "UE", with: "UEUE")
            .replacingOccurrences(of: "ä", with: "ae")
            .replacingOccurrences(of: "ö", with: "oe")
            .replacingOccurrences(of: "ü", with: "ue")
            .replacingOccurrences(of: "Ä", with: "AE")
            .replacingOccurrences(of: "Ö", with: "OE")
            .replacingOccurrences(of: "Ü", with: "UE")
            .map({ $0.isWhitespace ? "_" : $0 })
            .map({ $0.isPunctuation ? "_" : $0 })
            .map(\.description)
            .joined(separator: "")
            .utf8
            .map({ $0 > 0b01111111 ? $0.description : UnicodeScalar.init(UInt32($0))!.description })
            .joined(separator: "")
    }
}
