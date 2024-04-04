//
//  File.swift
//
//
//  Copyright 2024 Oliver Letterer
//

import Foundation

public protocol CheckedError: Error {
    var failureReason: String { get }
}
