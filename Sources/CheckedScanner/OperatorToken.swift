//
//  File.swift
//  
//
//  Copyright 2022 Oliver Letterer
//

import Foundation

public struct OperatorToken: Token {
    public enum Operator: Equatable, Hashable, CaseIterable {
        case plus
        case minus
        case times
        case division
        case not
        case and
        case or
        case binaryAnd
        case binaryOr
        case binaryXor
        case equal
        case assignment
        case modulo
        case smaller
        case smallerEqual
        case greater
        case greaterEqual
        
        public var description: String {
            switch self {
            case .plus: return "+"
            case .minus: return "-"
            case .times: return "*"
            case .division: return "/"
            case .not: return "!"
            case .and: return "&&"
            case .or: return "||"
            case .binaryAnd: return "&"
            case .binaryOr: return "|"
            case .binaryXor: return "^"
            case .equal: return "=="
            case .assignment: return "="
            case .modulo: return "%"
            case .smaller: return "<"
            case .smallerEqual: return "<="
            case .greater: return ">"
            case .greaterEqual: return ">="
            }
        }
        
        public var isInfixOperator: Bool {
            switch self {
            case .plus, .minus, .times, .division, .and, .or, .binaryAnd, .binaryOr, .binaryXor, .equal, .modulo, .smaller, .smallerEqual, .greater, .greaterEqual: return true
            default: return false
            }
        }
        
        public var isPrefixOperator: Bool {
            switch self {
            case .not: return true
            default: return false
            }
        }
        
        public var precedence: Int {
            switch self {
            case .times: return 10
            case .division: return 10
            case .modulo: return 10
            case .plus: return 20
            case .minus: return 20
            case .smaller: return 30
            case .smallerEqual: return 31
            case .greater: return 32
            case .greaterEqual: return 33
            case .equal: return 40
            case .binaryAnd: return 50
            case .binaryXor: return 60
            case .binaryOr: return 70
            case .and: return 80
            case .or: return 90
            case .assignment: return .min
            case .not: return .min
            }
        }
    }
    
    public var op: Operator
    public var file: URL
    public var location: Range<Int>
    
    init(op: Operator, file: URL, location: Range<Int>) {
        self.op = op
        self.file = file
        self.location = location
    }
    
    public var description: String {
        return "`\(op.description)`"
    }
}
