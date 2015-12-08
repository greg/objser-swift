//
//  FormatCoding.swift
//  AOGF
//
//  Created by Greg Omelaenko on 8/12/2015.
//  Copyright © 2015 Greg Omelaenko. All rights reserved.
//

import Foundation

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
	
	/// Convenience method for writing `Format` data
	func write(byte: Byte, _ array: ByteArray) {
		write(byte)
		write(array)
	}
	
}

extension Format {
	
	func writeTo(stream: NSOutputStream) {
		switch self {
			
		case .Reference(let v):
			switch v {
			case 0...0b0011_1111:
				stream.write(Codes.Ref6 | Byte(v))
			case 0...0xff:
				stream.write(Codes.Ref8, Byte(v))
			case 0...0xffff:
				stream.write(Codes.Ref16, UInt16(v).bytes)
			case 0...0xffff_ffff:
				stream.write(Codes.Ref32, UInt32(v).bytes)
			default:
				fatalError()
			}
			
		case .Integer(let v):
			if let v = v.int8Value {
				switch v {
				case 0...0b0011_1111:
					stream.write(Codes.PosInt6 | Byte(v))
				case -0b0001_1111..<0:
					stream.write(Byte(bitPattern: v))
				default:
					stream.write(Codes.Int8, Byte(bitPattern: v))
				}
			}
			else if let v = v.uint8Value { stream.write(Codes.UInt8, v) }
			else if let v = v.int16Value { stream.write(Codes.Int16, v.bytes) }
			else if let v = v.uint16Value { stream.write(Codes.UInt16, v.bytes) }
			else if let v = v.int32Value { stream.write(Codes.Int32, v.bytes) }
			else if let v = v.uint32Value { stream.write(Codes.UInt32, v.bytes) }
			else if let v = v.int64Value { stream.write(Codes.Int64, v.bytes) }
			else if let v = v.uint64Value { stream.write(Codes.UInt64, v.bytes) }
			
		case .Nil:
			stream.write(Codes.Nil)
			
		case .Boolean(let v):
			stream.write(v ? Codes.True : Codes.False)
			
		case .Float(let v):
			if let v = v as? Float32 { stream.write(Codes.Float32, v.bytes) }
			else if let v = v as? Float64 { stream.write(Codes.Float64, v.bytes) }
			else { fatalError() }
			
		case .String(let v):
			switch v.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) {
			case 0:
				stream.write(Codes.EString)
			case 1...0b0000_1111:
				var b = v.nulTerminatedUTF8
				b.removeLast()
				stream.write(Codes.FString | Byte(b.count), b)
			default:
				stream.write(Codes.VString, v.nulTerminatedUTF8)
			}
			
		case .Data(let v):
			let c = v.count
			switch c {
			case 0:
				stream.write(Codes.EData)
			case 1...0b0000_1111:
				stream.write(Codes.FData | Byte(c), v)
			case 0...0xff:
				stream.write(Codes.VData8, Byte(c))
				stream.write(v)
			case 0...0xffff:
				stream.write(Codes.VData16, UInt16(c).bytes)
				stream.write(v)
			case 0...0xffff_ffff:
				stream.write(Codes.VData32, UInt32(c).bytes)
				stream.write(v)
			default:
				stream.write(Codes.VData64, UInt64(c).bytes)
				stream.write(v)
			}

		case .Pair(let a, let b):
			stream.write(Codes.Pair)
			a.writeTo(stream)
			b.writeTo(stream)
			
		case .Array(let v):
			let c = v.count
			switch c {
			case 0:
				stream.write(Codes.EArray)
			case 1...0b001_1111:
				stream.write(Codes.FArray | Byte(c))
				v.forEach { $0.writeTo(stream) }
			default:
				stream.write(Codes.VArray)
				v.forEach { $0.writeTo(stream) }
				stream.write(Codes.Sentinel)
			}
			
		case .Map(let a):
			if a.count == 0 {
				stream.write(Codes.EMap)
			}
			else {
				stream.write(Codes.Map)
				Format.Array(a).writeTo(stream)
			}
		}
	}
	
}

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

extension Format {
	
	enum DecodeError: ErrorType {
		
		case SentinelReached
		case ReservedCode(Byte)
		case InvalidMapArray(Format)
		case InvalidString(ByteArray)
	
	}
	
	init(stream: NSInputStream) throws {
		let v = stream.readByte()
		switch v {
		case Ranges.Ref6:
			self = .Reference(UInt32(v))
		case Codes.Ref8:
			self = .Reference(UInt32(stream.readByte()))
		case Codes.Ref16:
			self = .Reference(UInt32(UInt16(bytes: stream.readByteArray(length: 2))))
		case Codes.Ref32:
			self = .Reference(UInt32(bytes: stream.readByteArray(length: 4)))
			
		case Ranges.PosInt6:
			self = .Integer(v & 0b0011_1111)
		case Ranges.NegInt5:
			self = .Integer(Int8(bitPattern: v))
			
		case Codes.False:
			self = .Boolean(false)
		case Codes.True:
			self = .Boolean(true)
			
		case Codes.Nil:
			self = .Nil
			
		case Codes.Int8:
			self = .Integer(Int8(bitPattern: stream.readByte()))
		case Codes.Int16:
			self = .Integer(Int16(bytes: stream.readByteArray(length: 2)))
		case Codes.Int32:
			self = .Integer(Int32(bytes: stream.readByteArray(length: 4)))
		case Codes.Int64:
			self = .Integer(Int64(bytes: stream.readByteArray(length: 8)))
		case Codes.UInt8:
			self = .Integer(UInt8(stream.readByte()))
		case Codes.UInt16:
			self = .Integer(UInt16(bytes: stream.readByteArray(length: 2)))
		case Codes.UInt32:
			self = .Integer(UInt32(bytes: stream.readByteArray(length: 4)))
		case Codes.UInt64:
			self = .Integer(UInt64(bytes: stream.readByteArray(length: 8)))
			
		case Codes.Float32:
			self = .Float(Float32(bytes: stream.readByteArray(length: 4)))
		case Codes.Float64:
			self = .Float(Float64(bytes: stream.readByteArray(length: 8)))
			
		case Codes.Pair:
			self = try Pair(Format(stream: stream), Format(stream: stream))
			
		case Ranges.FString:
			var b = stream.readByteArray(length: Int(v) & 0b1111)
			b.append(0)
			guard let str = Swift.String(UTF8Bytes: b) else {
				throw DecodeError.InvalidString(b)
			}
			self = .String(str)
		case Codes.VString:
			var b = ByteArray()
			while b.last != 0 {
				b.append(stream.readByte())
			}
			guard let str = Swift.String(UTF8Bytes: b) else {
				throw DecodeError.InvalidString(b)
			}
			self = .String(str)
		case Codes.EString:
			self = .String("")
			
		case Ranges.FData:
			self = .Data(stream.readByteArray(length: Int(v) & 0b1111))
		case Codes.VData8:
			self = .Data(stream.readByteArray(length: Int(stream.readByte())))
		case Codes.VData16:
			let len = Swift.UInt16(bytes: stream.readByteArray(length: 2))
			self = .Data(stream.readByteArray(length: Int(len)))
		case Codes.VData32:
			let len = Swift.UInt32(bytes: stream.readByteArray(length: 4))
			self = .Data(stream.readByteArray(length: Int(len)))
		case Codes.VData64:
			let len = Swift.UInt64(bytes: stream.readByteArray(length: 8))
			self = .Data(stream.readByteArray(length: Int(len)))
		case Codes.EData:
			self = .Data([])
			
		case Ranges.FArray:
			let len = Int(v & 0b1_1111)
			var array = FormatArray()
			array.reserveCapacity(len)
			for _ in 0..<len {
				array.append(try Format(stream: stream))
			}
			self = .Array(array)
		case Codes.VArray:
			var array = FormatArray()
			while true {
				do { array.append(try Format(stream: stream)) }
				catch DecodeError.SentinelReached { break }
			}
			self = .Array(array)
		case Codes.EArray:
			self = .Array([])
			
		case Codes.Map:
			let a = try Format(stream: stream)
			guard case .Array(let v) = a else {
				throw DecodeError.InvalidMapArray(a)
			}
			self = .Map(v)
		case Codes.EMap:
			self = .Map([])
			
		case Codes.Sentinel:
			throw DecodeError.SentinelReached
			
		case Ranges.Reserved:
			throw DecodeError.ReservedCode(v)
			
		default:
			// this should never happen – this switch statement covers all byte values.
			fatalError()
		}
	}
	
}
