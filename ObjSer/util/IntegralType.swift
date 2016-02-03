//
//  IntegralType.swift
//  ObjSer
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Greg Omelaenko
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

public protocol IntegralType : NumericType, IntegerType {
    
    init<T : IntegralType>(_ v: T)
    init(_ v: Int8)
    init(_ v: UInt8)
    init(_ v: Int16)
    init(_ v: UInt16)
    init(_ v: Int32)
    init(_ v: UInt32)
    init(_ v: Int64)
    init(_ v: UInt64)
    init(_ v: Int)
    init(_ v: UInt)

    static var min: Self { get }
    static var max: Self { get }

}

extension IntegralType {
    
    public init<T : IntegralType>(_ v: T) {
        switch v {
        case let v as Int8: self = Self(v)
        case let v as UInt8: self = Self(v)
        case let v as Int16: self = Self(v)
        case let v as UInt16: self = Self(v)
        case let v as Int32: self = Self(v)
        case let v as UInt32: self = Self(v)
        case let v as Int64: self = Self(v)
        case let v as UInt64: self = Self(v)
        case let v as Int: self = Self(v)
        case let v as UInt: self = Self(v)
        default: preconditionFailure("Unrecognised IntegralType type \(T.self).")
        }
    }

}

extension Int8 : IntegralType { }
extension UInt8 : IntegralType { }
extension Int16 : IntegralType { }
extension UInt16 : IntegralType { }
extension Int32 : IntegralType { }
extension UInt32 : IntegralType { }
extension Int64 : IntegralType { }
extension UInt64 : IntegralType { }
extension Int : IntegralType { }
extension UInt : IntegralType { }

/// A type-erased integer.
public struct AnyInteger {

    private let negative: Bool
    private let value: UInt64

    public init<T : IntegralType>(_ v: T) {
        if v < 0 {
            negative = true
            value = UInt64(-Int64(v))
        }
        else {
            negative = false
            value = UInt64(v)
        }
    }

}

extension IntegralType {

    /// Initialise from `v`, trapping on overflow.
    public init(_ v: AnyInteger) {
        self = v.negative ? Self(-Int64(v.value)) : Self(v.value)
    }

}

extension IntegralType {

    /// Attempt to convert initialise from `v`, performing bounds checking and failing if this is not possible.
    public init?(convert v: AnyInteger) {
        if v.negative {
            if Int64(Self.min) <= -Int64(v.value) { self.init(-Int64(v.value)) }
            else { return nil }
        }
        else {
            if UInt64(Self.max) >= v.value { self.init(v.value) }
            else { return nil }
        }
    }

}

extension AnyInteger : IntegerLiteralConvertible {

    public init(integerLiteral value: Int64) {
        self.init(value)
    }

}

extension AnyInteger : Hashable {

    public var hashValue: Int {
        return value.hashValue
    }

}

public func ==(a: AnyInteger, b: AnyInteger) -> Bool {
    return (a.negative == b.negative && a.value == b.value) || (a.value == 0 && b.value == 0)
}

public func <(a: AnyInteger, b: AnyInteger) -> Bool {
    return (a.negative == b.negative && (a.value < b.value) != a.negative) || (a.negative && !b.negative)
}

extension AnyInteger : Equatable, Comparable { }
