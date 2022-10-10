//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

public protocol Token: Equatable, Hashable, SourceElement {
    var description: String { get }
}
