//
//  Primitive.swift
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

/// Defines the ObjSer primitive types.
enum Primitive {
    
    /// A promised value with an attached function that will be called to resolve the primitive for use.
    case promised(() -> Primitive)
    
    case reference(UInt32)
    case integer(AnyInteger)
    case `nil`
    case boolean(Bool)
    case float(AnyFloat)
    case string(Swift.String)
    case data(ByteArray)
    indirect case typeIdentified(name: Primitive, value: Primitive)
    indirect case array(ContiguousArray<Primitive>)
    /// A map, represented by an array of alternating keys and values.
    indirect case map(ContiguousArray<Primitive>)
    
}

// MARK: Encoding

extension OutputStream {
    
    /// Convenience method for writing `Primitive` data
    func write(byte: Byte, array: ByteArray) {
		write(bytes: byte)
		write(bytes: array)
    }
	
	/// Convenience method for writing `Primitive` data
	func write(byte: Byte) {
		write(bytes: byte)
	}
	
}

extension Primitive {
    
    func writeTo(_ stream: OutputStream) {
        switch self {
            
        case .promised(let resolve):
            resolve().writeTo(stream)
            
        case .reference(let v):
            switch v {
            case 0...0b0011_1111:
				stream.write(byte: Format.ref6.byte | Byte(v))
            case 0...0xff:
				stream.write(byte: Format.ref8.byte, array: [Byte(v)])
            case 0...0xffff:
				stream.write(byte: Format.ref16.byte, array: UInt16(v).bytes)
            case 0...0xffff_ffff:
				stream.write(byte: Format.ref32.byte, array: UInt32(v).bytes)
            default:
                preconditionFailure("Could not format reference value \(v) greater than 2³² - 1.")
            }
            
        case .integer(let v):
            if let v = Int8(convert: v) {
                switch v {
                case 0...0b0011_1111:
					stream.write(byte: Format.posInt6.byte | Byte(v))
                case -32..<0:
					stream.write(byte: Format.negInt5.byte | Byte(bitPattern: v))
                default:
					stream.write(byte: Format.int8.byte, array: [Byte(bitPattern: v)])
                }
            }
			else if let v = UInt8(convert: v) { stream.write(byte: Format.uInt8.byte, array: v.bytes) }
            else if let v = Int16(convert: v) { stream.write(byte: Format.int16.byte, array: v.bytes) }
            else if let v = UInt16(convert: v) { stream.write(byte: Format.uInt16.byte, array: v.bytes) }
            else if let v = Int32(convert: v) { stream.write(byte: Format.int32.byte, array: v.bytes) }
            else if let v = UInt32(convert: v) { stream.write(byte: Format.uInt32.byte, array: v.bytes) }
            else if let v = Int64(convert: v) { stream.write(byte: Format.int64.byte, array: v.bytes) }
            else if let v = UInt64(convert: v) { stream.write(byte: Format.uInt64.byte, array: v.bytes) }
            
        case .nil:
			stream.write(byte: Format.nil.byte)
            
        case .boolean(let v):
			stream.write(byte: v ? Format.true.byte : Format.false.byte)
            
        case .float(let v):
			if let v = v.exactFloat32Value { stream.write(byte: Format.float32.byte, array: v.bytes) }
			else { stream.write(byte: Format.float64.byte, array: Float64(v).bytes) }

        case .string(let v):
            switch v.utf8.count {
            case 0:
				stream.write(byte: Format.eString.byte)
            case 1...0b0000_1111:
                var b = v.nulTerminatedUTF8
                b.removeLast()
				stream.write(byte: Format.fString.byte | Byte(b.count), array: b)
            default:
                stream.write(byte: Format.vString.byte, array: v.nulTerminatedUTF8)
            }
            
        case .data(let v):
            let c = v.count
            switch c {
            case 0:
                stream.write(byte: Format.eData.byte)
            case 1...0b0000_1111:
                stream.write(byte: Format.fData.byte | Byte(c), array: v)
            case 0...0xff:
                stream.write(byte: Format.vData8.byte, array: [Byte(c)])
                stream.write(bytes: v)
            case 0...0xffff:
                stream.write(byte: Format.vData16.byte, array: UInt16(c).bytes)
                stream.write(bytes: v)
            default:
                stream.write(byte: Format.vData32.byte, array: UInt32(c).bytes)
                stream.write(bytes: v)
            }
            
        case .array(let v):
            switch v.count {
            case 0:
                stream.write(byte: Format.eArray.byte)
            case 1...0b001_1111:
                stream.write(byte: Format.fArray.byte | Byte(v.count))
                v.forEach { $0.writeTo(stream) }
            default:
                stream.write(byte: Format.vArray.byte)
                v.forEach { $0.writeTo(stream) }
                stream.write(byte: Format.sentinel.byte)
            }
            
        case .map(let a):
            if a.count == 0 {
                stream.write(byte: Format.eMap.byte)
            }
            else {
                stream.write(byte: Format.map.byte)
                Primitive.array(a).writeTo(stream)
            }
            
        case .typeIdentified(let name, let v):
            stream.write(byte: Format.typeID.byte)
            name.writeTo(stream)
            v.writeTo(stream)
        }
    }
    
}

// MARK: Decoding

extension InputStream {
    
    func readByteArray(length: Int) -> ByteArray {
        return ByteArray(readBytes(length: length))
    }
    
}

extension String {
    
    init?(UTF8Bytes bytes: ByteArray) {
        guard let str = bytes.withUnsafeBufferPointer({
            String(validatingUTF8: UnsafePointer<CChar>($0.baseAddress!))
        }) else {
            return nil
        }
        self = str
    }
    
}

extension Primitive {
    
    enum FormatError: ErrorProtocol {
        
        case sentinelReached
        case reservedCode(Byte)
        case invalidMapArray(Primitive)
        case invalidString(ByteArray)
        
    }
    
    init(readFrom stream: InputStream) throws {
        let v = stream.readByte()
        switch v {
        case Format.ref6.range:
            self = .reference(UInt32(v))
        case Format.ref8.byte:
            self = .reference(UInt32(stream.readByte()))
        case Format.ref16.byte:
            self = .reference(UInt32(UInt16(bytes: stream.readByteArray(length: 2))))
        case Format.ref32.byte:
            self = .reference(UInt32(bytes: stream.readByteArray(length: 4)))
            
        case Format.posInt6.range:
            self = .integer(AnyInteger(v & 0b0011_1111))
        case Format.negInt5.range:
            self = .integer(AnyInteger(Int8(bitPattern: v)))
            
        case Format.false.byte:
            self = .boolean(false)
        case Format.true.byte:
            self = .boolean(true)
            
        case Format.nil.byte:
            self = .nil
            
        case Format.int8.byte:
            self = .integer(AnyInteger(Int8(bitPattern: stream.readByte())))
        case Format.int16.byte:
            self = .integer(AnyInteger(Int16(bytes: stream.readByteArray(length: 2))))
        case Format.int32.byte:
            self = .integer(AnyInteger(Int32(bytes: stream.readByteArray(length: 4))))
        case Format.int64.byte:
            self = .integer(AnyInteger(Int64(bytes: stream.readByteArray(length: 8))))
        case Format.uInt8.byte:
            self = .integer(AnyInteger(UInt8(stream.readByte())))
        case Format.uInt16.byte:
            self = .integer(AnyInteger(UInt16(bytes: stream.readByteArray(length: 2))))
        case Format.uInt32.byte:
            self = .integer(AnyInteger(UInt32(bytes: stream.readByteArray(length: 4))))
        case Format.uInt64.byte:
            self = .integer(AnyInteger(UInt64(bytes: stream.readByteArray(length: 8))))
            
        case Format.float32.byte:
            self = .float(AnyFloat(Float32(bytes: stream.readByteArray(length: 4))))
        case Format.float64.byte:
            self = .float(AnyFloat(Float64(bytes: stream.readByteArray(length: 8))))
            
        case Format.fString.range:
            var b = stream.readByteArray(length: Int(v) & 0b1111)
            b.append(0)
            guard let str = Swift.String(UTF8Bytes: b) else {
                throw FormatError.invalidString(b)
            }
            self = .string(str)
        case Format.vString.byte:
            var b = ByteArray()
            while b.last != 0 {
                b.append(stream.readByte())
            }
            guard let str = Swift.String(UTF8Bytes: b) else {
                throw FormatError.invalidString(b)
            }
            self = .string(str)
        case Format.eString.byte:
            self = .string("")
            
        case Format.fData.range:
            self = .data(stream.readByteArray(length: Int(v) & 0b1111))
        case Format.vData8.byte:
            self = .data(stream.readByteArray(length: Int(stream.readByte())))
        case Format.vData16.byte:
            let len = Swift.UInt16(bytes: stream.readByteArray(length: 2))
            self = .data(stream.readByteArray(length: Int(len)))
        case Format.vData32.byte:
            let len = Swift.UInt32(bytes: stream.readByteArray(length: 4))
            self = .data(stream.readByteArray(length: Int(len)))
        case Format.eData.byte:
            self = .data([])
            
        case Format.fArray.range:
            let len = Int(v & 0b1_1111)
            var array = ContiguousArray<Primitive>()
            array.reserveCapacity(len)
            for _ in 0..<len {
                array.append(try Primitive(readFrom: stream))
            }
            self = .array(array)
        case Format.vArray.byte:
            var array = ContiguousArray<Primitive>()
            while true {
                do { array.append(try Primitive(readFrom: stream)) }
                catch FormatError.sentinelReached { break }
            }
            self = .array(array)
        case Format.eArray.byte:
            self = .array([])
            
        case Format.map.byte:
            let a = try Primitive(readFrom: stream)
            guard case .array(let v) = a else {
                throw FormatError.invalidMapArray(a)
            }
            self = .map(v)
        case Format.eMap.byte:
            self = .map([])
            
        case Format.typeID.byte:
            self = .typeIdentified(name: try Primitive(readFrom: stream), value: try Primitive(readFrom: stream))
            
        case Format.sentinel.byte:
            throw FormatError.sentinelReached
            
        case Format.reserved.range:
            throw FormatError.reservedCode(v)
            
        default:
            preconditionFailure("Unrecognised format value \(v). THIS SHOULD NEVER HAPPEN — the format reader should cover all possible byte values. Please report this issue, including the library version, and the unrecognised value \(v).")
        }
    }
    
}
