//
//  FormatConversion.swift
//  AOGF
//
//  Created by Greg Omelaenko on 8/12/2015.
//  Copyright © 2015 Greg Omelaenko. All rights reserved.
//

// MARK: Native to format

import Foundation.NSData

extension Format: NilLiteralConvertible {
	
	public init(nilLiteral: ()) {
		self = .Nil
	}
	
}

extension Format {
	
	public init<T: IntegerType>(integer v: T) {
		switch v {
		case 0...0b0011_1111:
			self = PosInt6(Byte(v))
		case -0b0001_1111..<0:
			self = NegInt5(Byte(bitPattern: Swift.Int8(v)))
		case -0x8f...0x7f:
			self = Int8(Byte(bitPattern: Swift.Int8(v)))
		case 0...0xff:
			self = UInt8(Byte(v))
		case -0x8000...0x7fff:
			self = Int16(v.bytes)
		case 0...0xffff:
			self = UInt16(v.bytes)
		case -0x8000_0000...0x7fff_ffff:
			self = Int32(v.bytes)
		case 0...0xffff_ffff:
			self = UInt32(v.bytes)
		case -0x8000_0000_0000_0000...0x7fff_ffff_ffff_fffe:
			self = Int64(v.bytes)
		default:
			self = UInt64(v.bytes)
		}
	}
	
	public init(boolean v: Bool) {
		self = v ? True : False
	}
	
	public init(float v: Swift.Float32) {
		self = Float32(v.bytes)
	}
	
	public init(float v: Swift.Float64) {
		self = Float64(v.bytes)
	}
	
	public init(string str: String) {
		var v = str.nulTerminatedUTF8
		// exclude nul-terminator from count
		switch v.count - 1 {
		case 0:
			self = EString
		case 1...15:
			// remove the nul-terminator since a count is stored
			v.popLast()
			self = FString(v)
		default:
			self = VString(v)
		}
	}
	
	public init(data v: ByteArray) {
		let c = v.count
		switch c {
		case 0:
			self = EData
		case 1...0xf:
			self = FData(v)
		case 0...0xff:
			self = VData8(v)
		case 0...0xffff:
			self = VData16(v)
		case 0...0xffff_ffff:
			self = VData32(v)
		default:
			self = VData64(v)
		}
	}
	
	public init(data: NSData) {
		var v = ByteArray()
		v.reserveCapacity(data.length)
		v.withUnsafeMutableBufferPointer { (inout buf: UnsafeMutableBufferPointer<Swift.UInt8>) in
			data.getBytes(buf.baseAddress, length: data.length)
		}
		self = Format(data: v)
	}
	
	public init(pair v: (Format, Format)) {
		self = Pair(v.0, v.1)
	}
	
	public init(array v: FormatArray) {
		switch v.count {
		case 0:
			self = EArray
		case 1...31:
			self = FArray(v)
		default:
			self = VArray(v)
		}
	}
	
	/// Initialises a map from an array of alternating keys and values.
	public init(map v: FormatArray) {
		switch v.count {
		case 0:
			self = EMap
		default:
			self = Map(Format(array: v))
		}
	}
	
}

// MARK: Format to native

extension Format {
	
}
