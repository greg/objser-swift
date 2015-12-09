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
		default: fatalError()
		}
	}
	
	func signedValue<R: AnyInteger where R: SignedIntegerType>() -> R? {
		if sizeof(R) > sizeof(Self) { return R(self) }
		else if self <= Self(R.max) {
			if Self.min == Self(0) { return R(self) }
			return self >= Self(R.min) ? R(self) : nil
		}
		return nil
	}
	
	func unsignedValue<R: AnyInteger where R: UnsignedIntegerType>() -> R? {
		if self < Self(0) { return nil }
		if sizeof(R) >= sizeof(Self) { return R(self) }
		else {
			return self <= Self(R.max) ? R(self) : nil
		}
	}
	
	public var int8Value: Int8? { return signedValue() }
	public var uint8Value: UInt8? { return unsignedValue() }
	public var int16Value: Int16? { return signedValue() }
	public var uint16Value: UInt16? { return unsignedValue() }
	public var int32Value: Int32? { return signedValue() }
	public var uint32Value: UInt32? { return unsignedValue() }
	public var int64Value: Int64? { return signedValue() }
	public var uint64Value: UInt64? { return unsignedValue() }
	public var intValue: Int? { return signedValue() }
	public var uintValue: UInt? { return unsignedValue() }
	
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
	
}

extension AnyFloat {
	
	public init<T: AnyFloat>(_ v: T) {
		switch v {
		case let v as Float32: self = Self(v)
		case let v as Float64: self = Self(v)
		default: fatalError()
		}
	}
	
}

extension Float32: AnyFloat { }
extension Float64: AnyFloat { }
