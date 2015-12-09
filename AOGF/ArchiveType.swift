//
//  ArchiveType.swift
//  AOGF
//
//  Created by Greg Omelaenko on 7/12/2015.
//  Copyright © 2015 Greg Omelaenko. All rights reserved.
//

import class Foundation.NSOutputStream
import class Foundation.NSInputStream
import Foundation.NSString

public typealias ArchiveTypeArray = ContiguousArray<ArchiveType>

// MARK: Types

/// Defines the AOGF types.
public enum ArchiveType {
	
	case Reference(UInt32)
	case Integer(AnyInteger)
	case Nil
	case Boolean(Bool)
	case Float(AnyFloat)
	case String(Swift.String)
	case Data(ByteArray)
	indirect case Pair(ArchiveType, ArchiveType)
	indirect case Array(ArchiveTypeArray)
	/// Provide an array of alternating keys and values.
	indirect case Map(ArchiveTypeArray)
	
}

extension ArchiveType: NilLiteralConvertible {
	
	public init(nilLiteral: ()) {
		self = .Nil
	}
	
}

// MARK: Encoding

extension NSOutputStream {
	
	func write(bytes: ByteArray) -> Int {
		return bytes.withUnsafeBufferPointer { buf in
			return write(buf.baseAddress, maxLength: buf.count)
		}
	}
	
	func write(bytes: Byte...) -> Int {
		return bytes.withUnsafeBufferPointer { buf in
			return write(buf.baseAddress, maxLength: buf.count)
		}
	}
	
	/// Convenience method for writing `ArchiveType` data
	func write(byte: Byte, _ array: ByteArray) {
		write(byte)
		write(array)
	}
	
}

extension ArchiveType {
	
	func writeTo(stream: NSOutputStream) {
		switch self {
			
		case .Reference(let v):
			switch v {
			case 0...0b0011_1111:
				stream.write(Format.Ref6.byte | Byte(v))
			case 0...0xff:
				stream.write(Format.Ref8.byte, Byte(v))
			case 0...0xffff:
				stream.write(Format.Ref16.byte, UInt16(v).bytes)
			case 0...0xffff_ffff:
				stream.write(Format.Ref32.byte, UInt32(v).bytes)
			default:
				fatalError()
			}
			
		case .Integer(let v):
			if let v = v.int8Value {
				switch v {
				case 0...0b0011_1111:
					stream.write(Format.PosInt6.byte | Byte(v))
				case -0b0001_1111..<0:
					stream.write(Byte(bitPattern: v))
				default:
					stream.write(Format.Int8.byte, Byte(bitPattern: v))
				}
			}
			else if let v = v.uint8Value { stream.write(Format.UInt8.byte, v) }
			else if let v = v.int16Value { stream.write(Format.Int16.byte, v.bytes) }
			else if let v = v.uint16Value { stream.write(Format.UInt16.byte, v.bytes) }
			else if let v = v.int32Value { stream.write(Format.Int32.byte, v.bytes) }
			else if let v = v.uint32Value { stream.write(Format.UInt32.byte, v.bytes) }
			else if let v = v.int64Value { stream.write(Format.Int64.byte, v.bytes) }
			else if let v = v.uint64Value { stream.write(Format.UInt64.byte, v.bytes) }
			
		case .Nil:
			stream.write(Format.Nil.byte)
			
		case .Boolean(let v):
			stream.write(v ? Format.True.byte : Format.False.byte)
			
		case .Float(let v):
			if let v = v as? Float32 { stream.write(Format.Float32.byte, v.bytes) }
			else if let v = v as? Float64 { stream.write(Format.Float64.byte, v.bytes) }
			else { fatalError() }
			
		case .String(let v):
			switch v.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) {
			case 0:
				stream.write(Format.EString.byte)
			case 1...0b0000_1111:
				var b = v.nulTerminatedUTF8
				b.removeLast()
				stream.write(Format.FString.byte | Byte(b.count), b)
			default:
				stream.write(Format.VString.byte, v.nulTerminatedUTF8)
			}
			
		case .Data(let v):
			let c = v.count
			switch c {
			case 0:
				stream.write(Format.EData.byte)
			case 1...0b0000_1111:
				stream.write(Format.FData.byte | Byte(c), v)
			case 0...0xff:
				stream.write(Format.VData8.byte, Byte(c))
				stream.write(v)
			case 0...0xffff:
				stream.write(Format.VData16.byte, UInt16(c).bytes)
				stream.write(v)
			case 0...0xffff_ffff:
				stream.write(Format.VData32.byte, UInt32(c).bytes)
				stream.write(v)
			default:
				stream.write(Format.VData64.byte, UInt64(c).bytes)
				stream.write(v)
			}

		case .Pair(let a, let b):
			stream.write(Format.Pair.byte)
			a.writeTo(stream)
			b.writeTo(stream)
			
		case .Array(let v):
			let c = v.count
			switch c {
			case 0:
				stream.write(Format.EArray.byte)
			case 1...0b001_1111:
				stream.write(Format.FArray.byte | Byte(c))
				v.forEach { $0.writeTo(stream) }
			default:
				stream.write(Format.VArray.byte)
				v.forEach { $0.writeTo(stream) }
				stream.write(Format.Sentinel.byte)
			}
			
		case .Map(let a):
			if a.count == 0 {
				stream.write(Format.EMap.byte)
			}
			else {
				stream.write(Format.Map.byte)
				ArchiveType.Array(a).writeTo(stream)
			}
		}
	}
	
}

// MARK: Decoding

extension NSInputStream {
	
	func readByte() -> Byte {
		var v: Byte = 0
		let _ = read(&v, maxLength: 1)
		return v
	}
	
	func readByteArray(length length: Int) -> ByteArray {
		var bytes = ByteArray(count: length, repeatedValue: 0)
		let _ = bytes.withUnsafeMutableBufferPointer { (inout buf: UnsafeMutableBufferPointer<Byte>) in
			return read(buf.baseAddress, maxLength: length)
		}
		return bytes
	}
	
}

extension String {
	
	init?(UTF8Bytes bytes: ByteArray) {
		guard let str = bytes.withUnsafeBufferPointer({
			String(UTF8String: UnsafePointer<CChar>($0.baseAddress))
		}) else {
			return nil
		}
		self = str
	}
	
}

extension ArchiveType {
	
	enum DecodeError: ErrorType {
		
		case SentinelReached
		case ReservedCode(Byte)
		case InvalidMapArray(ArchiveType)
		case InvalidString(ByteArray)
	
	}
	
	init(stream: NSInputStream) throws {
		let v = stream.readByte()
		switch v {
		case Format.Ref6.range:
			self = .Reference(UInt32(v))
		case Format.Ref8.byte:
			self = .Reference(UInt32(stream.readByte()))
		case Format.Ref16.byte:
			self = .Reference(UInt32(UInt16(bytes: stream.readByteArray(length: 2))))
		case Format.Ref32.byte:
			self = .Reference(UInt32(bytes: stream.readByteArray(length: 4)))
			
		case Format.PosInt6.range:
			self = .Integer(v & 0b0011_1111)
		case Format.NegInt5.range:
			self = .Integer(Int8(bitPattern: v))
			
		case Format.False.byte:
			self = .Boolean(false)
		case Format.True.byte:
			self = .Boolean(true)
			
		case Format.Nil.byte:
			self = .Nil
			
		case Format.Int8.byte:
			self = .Integer(Int8(bitPattern: stream.readByte()))
		case Format.Int16.byte:
			self = .Integer(Int16(bytes: stream.readByteArray(length: 2)))
		case Format.Int32.byte:
			self = .Integer(Int32(bytes: stream.readByteArray(length: 4)))
		case Format.Int64.byte:
			self = .Integer(Int64(bytes: stream.readByteArray(length: 8)))
		case Format.UInt8.byte:
			self = .Integer(UInt8(stream.readByte()))
		case Format.UInt16.byte:
			self = .Integer(UInt16(bytes: stream.readByteArray(length: 2)))
		case Format.UInt32.byte:
			self = .Integer(UInt32(bytes: stream.readByteArray(length: 4)))
		case Format.UInt64.byte:
			self = .Integer(UInt64(bytes: stream.readByteArray(length: 8)))
			
		case Format.Float32.byte:
			self = .Float(Float32(bytes: stream.readByteArray(length: 4)))
		case Format.Float64.byte:
			self = .Float(Float64(bytes: stream.readByteArray(length: 8)))
			
		case Format.Pair.byte:
			self = try Pair(ArchiveType(stream: stream), ArchiveType(stream: stream))
			
		case Format.FString.range:
			var b = stream.readByteArray(length: Int(v) & 0b1111)
			b.append(0)
			guard let str = Swift.String(UTF8Bytes: b) else {
				throw DecodeError.InvalidString(b)
			}
			self = .String(str)
		case Format.VString.byte:
			var b = ByteArray()
			while b.last != 0 {
				b.append(stream.readByte())
			}
			guard let str = Swift.String(UTF8Bytes: b) else {
				throw DecodeError.InvalidString(b)
			}
			self = .String(str)
		case Format.EString.byte:
			self = .String("")
			
		case Format.FData.range:
			self = .Data(stream.readByteArray(length: Int(v) & 0b1111))
		case Format.VData8.byte:
			self = .Data(stream.readByteArray(length: Int(stream.readByte())))
		case Format.VData16.byte:
			let len = Swift.UInt16(bytes: stream.readByteArray(length: 2))
			self = .Data(stream.readByteArray(length: Int(len)))
		case Format.VData32.byte:
			let len = Swift.UInt32(bytes: stream.readByteArray(length: 4))
			self = .Data(stream.readByteArray(length: Int(len)))
		case Format.VData64.byte:
			let len = Swift.UInt64(bytes: stream.readByteArray(length: 8))
			self = .Data(stream.readByteArray(length: Int(len)))
		case Format.EData.byte:
			self = .Data([])
			
		case Format.FArray.range:
			let len = Int(v & 0b1_1111)
			var array = ArchiveTypeArray()
			array.reserveCapacity(len)
			for _ in 0..<len {
				array.append(try ArchiveType(stream: stream))
			}
			self = .Array(array)
		case Format.VArray.byte:
			var array = ArchiveTypeArray()
			while true {
				do { array.append(try ArchiveType(stream: stream)) }
				catch DecodeError.SentinelReached { break }
			}
			self = .Array(array)
		case Format.EArray.byte:
			self = .Array([])
			
		case Format.Map.byte:
			let a = try ArchiveType(stream: stream)
			guard case .Array(let v) = a else {
				throw DecodeError.InvalidMapArray(a)
			}
			self = .Map(v)
		case Format.EMap.byte:
			self = .Map([])
			
		case Format.Sentinel.byte:
			throw DecodeError.SentinelReached
			
		case Format.Reserved.range:
			throw DecodeError.ReservedCode(v)
			
		default:
			// this should never happen – this switch statement covers all byte values.
			fatalError()
		}
	}
	
}
