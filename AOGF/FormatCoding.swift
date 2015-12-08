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
		case .Ref6(let v):
			assert(v <= 0b0011_1111)
			stream.write(Codes.Ref6 | v)
		case .Ref8(let v):
			stream.write(Codes.Ref8, v)
		case .Ref16(let v):
			stream.write(Codes.Ref16, v)
		case .Ref32(let v):
			stream.write(Codes.Ref32, v)
			
		case .PosInt6(let v):
			assert(v <= 0b0011_1111)
			stream.write(Codes.PosInt6 | v)
		case .NegInt5(let v):
			assert((0b1110_0000...0b1111_1111 as ClosedInterval) ~= v)
			stream.write(v)
			
		case .False:
			stream.write(Codes.False)
		case .True:
			stream.write(Codes.True)
		case .Nil:
			stream.write(Codes.Nil)
			
		case .Int8(let v):
			stream.write(Codes.Int8, v)
		case .Int16(let v):
			assert(v.count == 2)
			stream.write(Codes.Int16, v)
		case .Int32(let v):
			assert(v.count == 4)
			stream.write(Codes.Int32, v)
		case .Int64(let v):
			assert(v.count == 8)
			stream.write(Codes.Int64, v)
		case .UInt8(let v):
			stream.write(Codes.UInt8, v)
		case .UInt16(let v):
			assert(v.count == 2)
			stream.write(Codes.UInt16, v)
		case .UInt32(let v):
			assert(v.count == 4)
			stream.write(Codes.UInt32, v)
		case .UInt64(let v):
			assert(v.count == 8)
			stream.write(Codes.UInt64, v)
			
		case .Float32(let v):
			assert(v.count == 4)
			stream.write(Codes.Float32, v)
		case .Float64(let v):
			assert(v.count == 8)
			stream.write(Codes.Float64, v)
			
		case .Pair(let a, let b):
			stream.write(Codes.Pair)
			a.writeTo(stream)
			b.writeTo(stream)
			
		case .FString(let v):
			assert(1...0b0000_1111 ~= v.count)
			stream.write(Codes.FString | Byte(v.count), v)
		case .VString(let v):
			stream.write(Codes.VString, v)
		case .EString:
			stream.write(Codes.EString)
			
		case .FData(let v):
			assert(1...0b0000_1111 ~= v.count)
			stream.write(Codes.FData | Byte(v.count), v)
		case .VData8(let v):
			assert(0...0xff ~= v.count)
			stream.write(Codes.VData8, Byte(v.count))
			stream.write(v)
		case .VData16(let v):
			assert(0...0xffff ~= v.count)
			stream.write(Codes.VData16, Swift.UInt16(v.count).bytes)
			stream.write(v)
		case .VData32(let v):
			assert(0...0xffff_ffff ~= v.count)
			stream.write(Codes.VData32, Swift.UInt32(v.count).bytes)
			stream.write(v)
		case .VData64(let v):
			stream.write(Codes.VData64, Swift.UInt64(v.count).bytes)
			stream.write(v)
		case .EData:
			stream.write(Codes.EData)

		case .FArray(let v):
			assert(1...0b0001_1111 ~= v.count)
			stream.write(Codes.FArray | Byte(v.count))
			v.forEach { $0.writeTo(stream) }
		case .VArray(let v):
			stream.write(Codes.VArray)
			v.forEach { $0.writeTo(stream) }
			stream.write(Codes.Sentinel)
		case .EArray:
			stream.write(Codes.EArray)
			
		case .Map(let a):
			assert({
				switch a {
				case .FArray, .VArray: return true
				default: return false
				}
			}())
			stream.write(Codes.Map)
			a.writeTo(stream)
		case .EMap:
			stream.write(Codes.EMap)
		}
	}
	
}

extension NSInputStream {
	
	func readByte() -> (v: Byte, status: Int) {
		var v: Byte = 0
		let s = read(&v, maxLength: 1)
		return (v, s)
	}
	
	func readByteArray(length length: Int) -> (v: ByteArray, status: Int) {
		var bytes = ByteArray(count: length, repeatedValue: 0)
		let s = bytes.withUnsafeMutableBufferPointer { (inout buf: UnsafeMutableBufferPointer<Byte>) in
			return read(buf.baseAddress, maxLength: length)
		}
		return (bytes, s)
	}
	
}

extension Format {
	
	enum DecodeError: ErrorType {
		
		case SentinelReached
		case ReservedCode(Byte)
		case InvalidMapArray(Format)
	
	}
	
	init(stream: NSInputStream) throws {
		let (v, _) = stream.readByte()
		switch v {
		case Ranges.Ref6:
			self = Ref6(v)
		case Codes.Ref8:
			self = Ref8(stream.readByte().v)
		case Codes.Ref16:
			self = Ref16(stream.readByteArray(length: 2).v)
		case Codes.Ref32:
			self = Ref32(stream.readByteArray(length: 4).v)
			
		case Ranges.PosInt6:
			self = PosInt6(v & 0b0011_1111)
		case Ranges.NegInt5:
			self = NegInt5(v)
			
		case Codes.False:
			self = False
		case Codes.True:
			self = True
			
		case Codes.Nil:
			self = Nil
			
		case Codes.Int8:
			self = Int8(stream.readByte().v)
		case Codes.Int16:
			self = Int16(stream.readByteArray(length: 2).v)
		case Codes.Int32:
			self = Int32(stream.readByteArray(length: 4).v)
		case Codes.Int64:
			self = Int64(stream.readByteArray(length: 8).v)
		case Codes.UInt8:
			self = UInt8(stream.readByte().v)
		case Codes.UInt16:
			self = UInt16(stream.readByteArray(length: 2).v)
		case Codes.UInt32:
			self = UInt32(stream.readByteArray(length: 4).v)
		case Codes.UInt64:
			self = UInt64(stream.readByteArray(length: 8).v)
			
		case Codes.Float32:
			self = Float32(stream.readByteArray(length: 4).v)
		case Codes.Float64:
			self = Float64(stream.readByteArray(length: 8).v)
			
		case Codes.Pair:
			self = try Pair(Format(stream: stream), Format(stream: stream))
			
		case Ranges.FString:
			self = FString(stream.readByteArray(length: Int(v) & 0b1111).v)
		case Codes.VString:
			var str = ByteArray()
			while str.last != 0 {
				str.append(stream.readByte().v)
			}
			self = VString(str)
		case Codes.EString:
			self = EString
			
		case Ranges.FData:
			self = FData(stream.readByteArray(length: Int(v) & 0b1111).v)
		case Codes.VData8:
			self = VData8(stream.readByteArray(length: Int(stream.readByte().v)).v)
		case Codes.VData16:
			let len = Swift.UInt16(bytes: stream.readByteArray(length: 2).v)
			self = VData16(stream.readByteArray(length: Int(len)).v)
		case Codes.VData32:
			let len = Swift.UInt32(bytes: stream.readByteArray(length: 4).v)
			self = VData32(stream.readByteArray(length: Int(len)).v)
		case Codes.VData64:
			let len = Swift.UInt64(bytes: stream.readByteArray(length: 8).v)
			self = VData64(stream.readByteArray(length: Int(len)).v)
		case Codes.EData:
			self = EData
			
		case Ranges.FArray:
			let len = Int(v & 0b1_1111)
			var array = FormatArray()
			array.reserveCapacity(len)
			for _ in 0..<len {
				array.append(try Format(stream: stream))
			}
			self = FArray(array)
		case Codes.VArray:
			var array = FormatArray()
			while true {
				do { array.append(try Format(stream: stream)) }
				catch DecodeError.SentinelReached { break }
			}
			self = VArray(array)
		case Codes.EArray:
			self = EArray
		case Codes.Map:
			let a = try Format(stream: stream)
			switch a {
			case .FArray, .VArray: break
			default: throw DecodeError.InvalidMapArray(a)
			}
			self = Map(a)
		case Codes.EMap:
			self = EMap
			
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
