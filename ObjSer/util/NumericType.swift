//
//  NumericType.swift
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

import CoreFoundation
#if os(iOS)
	import CoreGraphics
#endif

public typealias Byte = UInt8
public typealias ByteArray = ContiguousArray<Byte>

public protocol AnyNumber {
	
	/// The bytes of the number, in little-endian order
	var bytes: ByteArray { get }
	
	/// Initialises the number from bytes given in little-endian order
	init(bytes: ByteArray)
	
}

var isLittleEndian: Bool {
	return __CFByteOrder(UInt32(CFByteOrderGetCurrent())) == CFByteOrderLittleEndian
}

extension AnyNumber {
	
	public var bytes: ByteArray {
		var v = self
		let b = withUnsafePointer(&v) {
			ByteArray(UnsafeBufferPointer<Byte>(start: UnsafePointer<Byte>($0), count: sizeofValue(v)))
		}
		return isLittleEndian ? b : ByteArray(b.reverse())
	}
	
	public init(bytes: ByteArray) {
		func bcast<T>(v: ByteArray) -> T {
			return bytes.withUnsafeBufferPointer {
				UnsafePointer<T>($0.baseAddress).memory
			}
		}
		self = bcast(isLittleEndian ? bytes : ByteArray(bytes.reverse()))
	}
	
}

public protocol AnyInteger: AnyNumber, Comparable, Equatable {
	
	init<T: AnyInteger>(_ v: T)
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
	
	init?<T: AnyInteger>(value v: T)
	
	var int8Value: Int8? { get }
	var uint8Value: UInt8? { get }
	var int16Value: Int16? { get }
	var uint16Value: UInt16? { get }
	var int32Value: Int32? { get }
	var uint32Value: UInt32? { get }
	var int64Value: Int64? { get }
	var uint64Value: UInt64? { get }
	var intValue: Int? { get }
	var uintValue: UInt? { get }
	
	static var min: Self { get }
	static var max: Self { get }
	
	func convert<R: AnyInteger>(unsigned unsigned: Bool) -> R?
	
}

extension AnyInteger {
	
	public init<T: AnyInteger>(_ v: T) {
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
		default: preconditionFailure("Unrecognised AnyInteger type \(T.self).")
		}
	}
	
	public init?<T: AnyInteger>(value v: T) {
		guard let v: Self = v.convert() else { return nil }
		self = v
	}
	
	public func convert<R: AnyInteger>(unsigned unsigned: Bool = R.min == 0) -> R? {
		if unsigned {
			if self < Self(0) { return nil }
			if sizeof(R) >= sizeof(Self) { return R(self) }
			else {
				return self <= Self(R.max) ? R(self) : nil
			}
		}
		else {
			if sizeof(R) > sizeof(Self) { return R(self) }
			else if self <= Self(R.max) {
				if Self.min == Self(0) { return R(self) }
				return self >= Self(R.min) ? R(self) : nil
			}
			return nil
		}
	}
	
	public var int8Value: Int8? { return convert() }
	public var uint8Value: UInt8? { return convert() }
	public var int16Value: Int16? { return convert() }
	public var uint16Value: UInt16? { return convert() }
	public var int32Value: Int32? { return convert() }
	public var uint32Value: UInt32? { return convert() }
	public var int64Value: Int64? { return convert() }
	public var uint64Value: UInt64? { return convert() }
	public var intValue: Int? { return convert() }
	public var uintValue: UInt? { return convert() }
	
}

func ==<T: AnyInteger, U: AnyInteger>(a: T, b: U) -> Bool {
	return false
}

extension Int8: AnyInteger { }
extension UInt8: AnyInteger { }
extension Int16: AnyInteger { }
extension UInt16: AnyInteger { }
extension Int32: AnyInteger { }
extension UInt32: AnyInteger { }
extension Int64: AnyInteger { }
extension UInt64: AnyInteger { }
extension Int: AnyInteger { }
extension UInt: AnyInteger { }


public protocol AnyFloat: AnyNumber, Comparable, Equatable {
	
	init<T: AnyFloat>(_ v: T)
	init(_ v: Float32)
	init(_ v: Float64)
	init(_ v: CGFloat)
	
	func convert<R: AnyFloat>() -> R
	
}

extension AnyFloat {
	
	public init<T: AnyFloat>(_ v: T) {
		switch v {
		case let v as Float32: self = Self(v)
		case let v as Float64: self = Self(v)
		case let v as CGFloat: self = Self(v)
		default: preconditionFailure("Unrecognised AnyFloat type \(T.self).")
		}
	}
	
	public func convert<R: AnyFloat>() -> R {
		switch self {
		case let v as Float32: return R(v)
		case let v as Float64: return R(v)
		case let v as CGFloat: return R(v)
		default: preconditionFailure("Unrecognised AnyFloat type \(R.self).")
		}
	}
	
}

extension Float32: AnyFloat { }
extension Float64: AnyFloat { }
extension CGFloat: AnyFloat { }
