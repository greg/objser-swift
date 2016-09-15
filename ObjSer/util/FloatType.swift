//
//  FloatType.swift
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

#if os(iOS)
    import CoreGraphics
#endif

public protocol FloatType : NumericType, Comparable, Equatable, Hashable {
    
    init<T: FloatType>(_ v: T)
    init(_ v: Float32)
    init(_ v: Float64)
    init(_ v: CGFloat)

}

extension FloatType {
    
    public init<T : FloatType>(_ v: T) {
        switch v {
        case let v as Float32: self = Self(v)
        case let v as Float64: self = Self(v)
        case let v as CGFloat: self = Self(v)
        default: preconditionFailure("Unrecognised FloatType type \(T.self).")
        }
    }

}

extension Float32: FloatType { }
extension Float64: FloatType { }
extension CGFloat: FloatType { }

/// A type-erased float.
public struct AnyFloat {

    private enum Box {
        case single(Float32)
        case double(Float64)
    }

    fileprivate let box: Box

    public init<T : FloatType>(_ v: T) {
        switch v {
        case let v as AnyFloat: self = v
        case let v as Float32: box = .single(v)
        case let v as Float64: box = .double(v)
        case let v as CGFloat: self = AnyFloat(v.native)
        default: preconditionFailure("Unrecognised FloatType type \(T.self).")
        }
    }

    public var exactFloat32Value: Float32? {
        guard case .single(let v) = box else {
            return nil
        }
        return v
    }

}

extension FloatType {

    public init(_ v: AnyFloat) {
        switch v.box {
        case .single(let v): self.init(v)
        case .double(let v): self.init(v)
        }
    }

}

extension AnyFloat : Hashable {

    public var hashValue: Int {
        switch box {
        case .single(let v): return v.hashValue
        case .double(let v): return v.hashValue
        }
    }

}

public func ==(a: AnyFloat, b: AnyFloat) -> Bool {
    switch (a.box, b.box) {
    case (.single(let a), .single(let b)): return a == b
    case (.double(let a), .double(let b)): return a == b
    case (.single(let a), .double(let b)): return Float64(a) == b
    case (.double(let a), .single(let b)): return a == Float64(b)
    }
}

public func <(a: AnyFloat, b: AnyFloat) -> Bool {
    switch (a.box, b.box) {
    case (.single(let a), .single(let b)): return a < b
    case (.double(let a), .double(let b)): return a < b
    case (.single(let a), .double(let b)): return Float64(a) < b
    case (.double(let a), .single(let b)): return a < Float64(b)
    }
}

extension AnyFloat : Equatable, Comparable { }
