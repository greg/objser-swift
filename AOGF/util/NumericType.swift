//
//  NumericType.swift
//  AOGF
//
//  Created by Greg Omelaenko on 7/12/2015.
//  Copyright © 2015 Greg Omelaenko. All rights reserved.
//

import Foundation

public typealias Byte = UInt8
public typealias ByteArray = ContiguousArray<Byte>

public protocol NumericType {
	
	/// The bytes of the number, in little-endian order
	var bytes: ByteArray { get }
	
	/// Initialises the number from bytes given in little-endian order
	init(bytes: ByteArray)
	
}

var isLittleEndian: Bool {
	return __CFByteOrder(UInt32(CFByteOrderGetCurrent())) == CFByteOrderLittleEndian
}

extension NumericType {
	
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

public protocol IntegerType: NumericType, Swift.IntegerType {
	
	init<T: IntegerType>(_ v: T)
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
	
}

extension IntegerType {
	
	public init<T : IntegerType>(_ v: T) {
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
		default: fatalError()
		}
	}
	
	public var bytes: ByteArray {
		func bytes<T>(a: T) -> ByteArray {
			var v = ByteArray(count: sizeofValue(a), repeatedValue: 0)
			v.withUnsafeMutableBufferPointer { (inout buf: UnsafeMutableBufferPointer<Byte>) in
				UnsafeMutablePointer<T>(buf.baseAddress)[0] = a
			}
			return v
		}
		return bytes(self)
	}
	
	public init(bytes: ByteArray) {
		func bcast<T>(bytes: ByteArray) -> T {
			return bytes.withUnsafeBufferPointer { buf in
				return UnsafePointer<T>(buf.baseAddress)[0]
			}
		}
		self = bcast(bytes)
	}
	
}

extension Int8: IntegerType { }

extension UInt8: IntegerType { }

extension Int16: IntegerType { }

extension UInt16: IntegerType { }

extension Int32: IntegerType { }

extension UInt32: IntegerType { }

extension Int64: IntegerType { }

extension UInt64: IntegerType { }

extension Int: IntegerType { }

extension UInt: IntegerType { }


public protocol FloatType: NumericType {
	
}

extension Float32: FloatType { }

extension Float64: FloatType { }
