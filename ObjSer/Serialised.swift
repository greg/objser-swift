//
//  Serialised.swift
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

protocol ArrayDecoder {
	
	func decodeArray<R : Serialisable>() throws -> AnySequence<R>
	func unconstrainedDecodeArray<_R>() throws -> AnySequence<_R>
	
}

protocol MapDecoder {
	
	func decodeMap<K : Serialisable, V : Serialisable>() throws -> AnySequence<(K, V)>
	func unconstrainedDecodeMap<_K, _V>() throws -> AnySequence<(_K, _V)>
	
}

protocol ValueDecoder {
	
	func decodeValue<R : Serialisable>() throws -> R
	func unconstrainedDecodeValue<_R>() throws -> _R
	
}

// Public wrapper around `Primitive`
@available(*, deprecated=0)
public struct Serialised: NilLiteralConvertible {
	
	enum Value {
		case Type(Primitive)
		case EncodingArray(AnySequence<Serialisable>)
		case EncodingMap(AnySequence<(Serialisable, Serialisable)>)
		case EncodingValue(Serialisable)
		case DecodingArray(ArrayDecoder)
		case DecodingMap(MapDecoder)
	}
	let value: Value
	private(set) var valueDecoder: ValueDecoder! = nil
	
	init(_ v: Primitive, decoder: ValueDecoder! = nil) {
		value = .Type(v)
		valueDecoder = decoder
	}
	
	init(arrayDecoder: ArrayDecoder, valueDecoder: ValueDecoder) {
		value = .DecodingArray(arrayDecoder)
		self.valueDecoder = valueDecoder
	}
	
	init(mapDecoder: MapDecoder, valueDecoder: ValueDecoder) {
		value = .DecodingMap(mapDecoder)
		self.valueDecoder = valueDecoder
	}
	
	public init<T: AnyInteger>(integer: T) {
		self.init(.Integer(integer))
	}
	
	public init(nilLiteral: ()) {
		self.init(.Nil)
	}
	
	public init(boolean: Bool) {
		self.init(.Boolean(boolean))
	}
	
	public init<T: AnyFloat>(float: T) {
		self.init(.Float(float))
	}
	
	public init(string: String) {
		self.init(.String(string))
	}
	
	public init(data: ByteArray) {
		self.init(.Data(data))
	}
	
	public init<S: SequenceType where S.Generator.Element == Serialisable>(array: S) {
		value = .EncodingArray(AnySequence(array))
	}
	
	public init<S: SequenceType where S.Generator.Element == (Serialisable, Serialisable)>(map: S) {
		value = .EncodingMap(AnySequence(map))
	}
	
	public init(archivingValue: Serialisable) {
		value = .EncodingValue(archivingValue)
	}
	
	func archiveType() throws -> Primitive {
		if case .Type(let t) = value { return t }
		throw DeserialiseError.IncorrectType(self)
	}
	
	public func integerValue<R: AnyInteger>() throws -> R {
		if case .Integer(let v) = try archiveType() {
			if let v: R = v.convert() { return v }
			throw DeserialiseError.ConversionFailed(v)
		}
		throw DeserialiseError.IncorrectType(self)
	}
	
	public func nilValue() throws -> () {
		if case .Nil = try archiveType() { return () }
		throw DeserialiseError.IncorrectType(self)
	}
	
	public func booleanValue() throws -> Bool {
		if case .Boolean(let v) = try archiveType() { return v }
		throw DeserialiseError.IncorrectType(self)
	}
	
	public func floatValue<R: AnyFloat>() throws -> R {
		if case .Float(let v) = try archiveType() { return v.convert() }
		throw DeserialiseError.IncorrectType(self)
	}
	
	public func stringValue() throws -> Swift.String {
		if case .String(let v) = try archiveType() { return v }
		throw DeserialiseError.IncorrectType(self)
	}
	
	public func dataValue() throws -> ByteArray {
		if case .Data(let v) = try archiveType() { return v }
		throw DeserialiseError.IncorrectType(self)
	}
	
	/// Decode and return a sequence of values of type `R`.
	public func arrayValue<R : Serialisable>() throws -> AnySequence<R> {
		if case .DecodingArray(let decoder) = value {
			return try decoder.decodeArray()
		}
		throw DeserialiseError.IncorrectType(self)
	}
	
	/// Unconstrained equivalent of `arrayValue`, provided for convenience when implementing encoding on collection types, as protocol conformance cannot be constrained.
	/// - Requires: `_R : Serialisable`. A runtime error will be thrown otherwise.
	public func unconstrainedArrayValue<_R>() throws -> AnySequence<_R> {
		if case .DecodingArray(let decoder) = value {
			return try decoder.unconstrainedDecodeArray()
		}
		throw DeserialiseError.IncorrectType(self)
	}
	
	public func mapValue<K : Serialisable, V : Serialisable>() throws -> AnySequence<(K, V)> {
		if case .DecodingMap(let decoder) = value {
			return try decoder.decodeMap()
		}
		throw DeserialiseError.IncorrectType(self)
	}
	
	/// Unconstrained equivalent of `mapValue`, provided for convenience when implementing encoding on collection types, as protocol conformance cannot be constrained.
	/// - Requires: `_K : Serialisable`, `_V : Serialisable`. A runtime error will be thrown otherwise.
	public func unconstrainedMapValue<_K, _V>() throws -> AnySequence<(_K, _V)> {
		if case .DecodingMap(let decoder) = value {
			return try decoder.unconstrainedDecodeMap()
		}
		throw DeserialiseError.IncorrectType(self)
	}
	
	public func archivingValue<R : Serialisable>() throws -> R {
		return try valueDecoder.decodeValue()
	}
	
	/// Unconstrained equivalent of `archivingValue`, provided for convenience when implementing encoding on wrapping types, as protocol conformance cannot be constrained.
	/// - Requires: `_R : Serialisable`. A runtime error will be thrown otherwise.
	public func unconstrainedArchivingValue<_R>() throws -> _R {
		return try valueDecoder.unconstrainedDecodeValue()
	}
	
}

protocol PrimitiveConverter {
	
	func primitiveValue(v: Serialisable) -> Primitive
	
}

public struct Serialising: NilLiteralConvertible {
	
	private enum State {
		case Converted(Primitive)
		case Convertible((Serialisable -> Primitive) -> Primitive)
	}
	private let state: State
	
	public init<T : AnyInteger>(integer: T) {
		state = .Converted(.Integer(integer))
	}
	
	public init(nilLiteral: ()) {
		state = .Converted(.Nil)
	}
	
	public init(boolean: Bool) {
		state = .Converted(.Boolean(boolean))
	}
	
	public init<T : AnyFloat>(float: T) {
		state = .Converted(.Float(float))
	}
	
	public init(string: String) {
		state = .Converted(.String(string))
	}
	
	public init<S : SequenceType where S.Generator.Element == Byte>(data bytes: S) {
		state = .Converted(.Data(ByteArray(bytes)))
	}
	
	public init<S : SequenceType where S.Generator.Element == Serialisable>(array seq: S) {
		state = .Convertible({ serialise in
			var a = ContiguousArray<Primitive>()
			a.reserveCapacity(seq.underestimateCount())
			for serialisable in seq {
				a.append(serialise(serialisable))
			}
			return .Array(a)
		})
	}
	
	public init<S : SequenceType where S.Generator.Element == (Serialisable, Serialisable)>(map seq: S) {
		state = .Convertible({ serialise in
			var a = ContiguousArray<Primitive>()
			a.reserveCapacity(seq.underestimateCount() * 2)
			for (serialisableKey, serialisableVal) in seq {
				a.append(serialise(serialisableKey))
				a.append(serialise(serialisableVal))
			}
			return .Map(a)
		})
	}
	
	public init(serialising value: Serialisable) {
		state = .Convertible({ serialise in
			serialise(value)
		})
	}
	
	func convertUsing(serialiser: Serialisable -> Primitive) -> Primitive {
		switch state {
		case .Converted(let p): return p
		case .Convertible(let conv): return conv(serialiser)
		}
	}
	
}

/// Defines the ObjSer primitive types.
enum Primitive {
	
	/// A promised value with an attached function that will be called to resolve the primitive for writing.
	case Promised(() -> Primitive)
	
	case Reference(UInt32)
	case Integer(AnyInteger)
	case Nil
	case Boolean(Bool)
	case Float(AnyFloat)
	case String(Swift.String)
	case Data(ByteArray)
	indirect case Array(ContiguousArray<Primitive>)
	/// Provide an array of alternating keys and values.
	indirect case Map(ContiguousArray<Primitive>)
	
}

// MARK: Encoding

extension OutputStream {
	
	/// Convenience method for writing `Primitive` data
	func write(byte: Byte, _ array: ByteArray) {
		write(byte)
		write(array)
	}
	
}

extension Primitive {
	
	func writeTo(stream: OutputStream) {
		switch self {
			
		case .Promised(let resolve):
			resolve().writeTo(stream)
			
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
				preconditionFailure("Could not format reference value \(v) greater than 2³² - 1.")
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
			else { preconditionFailure("Could not format unsupported float type \(v.dynamicType).") }
			
		case .String(let v):
			switch v.utf8.count {
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
			default:
				stream.write(Format.VData32.byte, UInt32(c).bytes)
				stream.write(v)
			}

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
				Primitive.Array(a).writeTo(stream)
			}
		}
	}
	
}

// MARK: Decoding

extension InputStream {
	
	func readByteArray(length length: Int) -> ByteArray {
		return ByteArray(readBytes(length: length))
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

extension Primitive {
	
	enum FormatError: ErrorType {
		
		case SentinelReached
		case ReservedCode(Byte)
		case InvalidMapArray(Primitive)
		case InvalidString(ByteArray)
	
	}
	
	init(readFrom stream: InputStream) throws {
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
			
		case Format.FString.range:
			var b = stream.readByteArray(length: Int(v) & 0b1111)
			b.append(0)
			guard let str = Swift.String(UTF8Bytes: b) else {
				throw FormatError.InvalidString(b)
			}
			self = .String(str)
		case Format.VString.byte:
			var b = ByteArray()
			while b.last != 0 {
				b.append(stream.readByte())
			}
			guard let str = Swift.String(UTF8Bytes: b) else {
				throw FormatError.InvalidString(b)
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
		case Format.EData.byte:
			self = .Data([])
			
		case Format.FArray.range:
			let len = Int(v & 0b1_1111)
			var array = ContiguousArray<Primitive>()
			array.reserveCapacity(len)
			for _ in 0..<len {
				array.append(try Primitive(readFrom: stream))
			}
			self = .Array(array)
		case Format.VArray.byte:
			var array = ContiguousArray<Primitive>()
			while true {
				do { array.append(try Primitive(readFrom: stream)) }
				catch FormatError.SentinelReached { break }
			}
			self = .Array(array)
		case Format.EArray.byte:
			self = .Array([])
			
		case Format.Map.byte:
			let a = try Primitive(readFrom: stream)
			guard case .Array(let v) = a else {
				throw FormatError.InvalidMapArray(a)
			}
			self = .Map(v)
		case Format.EMap.byte:
			self = .Map([])
			
		case Format.Sentinel.byte:
			throw FormatError.SentinelReached
			
		case Format.Reserved.range:
			throw FormatError.ReservedCode(v)
			
		default:
			preconditionFailure("Unrecognised format value \(v). THIS SHOULD NEVER HAPPEN — the format reader should cover all possible byte values. Please report this issue, including the library version, and the unrecognised value \(v).")
		}
	}
	
}
