//
//  Encoding.swift
//  AOGF
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

import class Foundation.NSData

public protocol Encoding: Archiving {
	
	/// Initialise an instance of `self` from the given encoded value.
	/// - Remarks: This is a workaround for the impossibility of implementing initialisers as extensions on non-final classes.
	/// - Note: If you are able to implement a required initialiser on your type, conform to `InitableEncoding` instead.
	static func initWithEncodedValue(encodedValue: ArchiveValue) throws -> Self
	
	var encodedValue: ArchiveValue { get }
	
}

public protocol InitableEncoding: Encoding {
	
	/// Initialise from the given encoded value.
	init(encodedValue: ArchiveValue) throws
	
}

extension InitableEncoding {
	
	@transparent public static func initWithEncodedValue(encodedValue: ArchiveValue) throws -> Self {
		return try Self.init(encodedValue: encodedValue)
	}
	
}

//public struct ArchivingTypes {
//	
//	public var integer: Archiving.Type?
//	public var `nil`: Archiving.Type?
//	public var boolean: Archiving.Type?
//	public var float: Archiving.Type?
//	public var string: Archiving.Type?
//	public var data: Archiving.Type?
//	public var pair: Archiving.Type?
//	public var array: Archiving.Type?
//	public var map: Archiving.Type?
//	
//	public init(
//		integer: Archiving.Type? = nil,
//		`nil`: Archiving.Type? = nil,
//		boolean: Archiving.Type? = nil,
//		float: Archiving.Type? = nil,
//		string: Archiving.Type? = nil,
//		data: Archiving.Type? = nil,
//		pair: Archiving.Type? = nil,
//		array: Archiving.Type? = nil,
//		map: Archiving.Type? = nil
//		) {
//			self.integer = integer
//			self.boolean = boolean
//			self.`nil` = `nil`
//			self.float = float
//			self.string = string
//			self.data = data
//			self.pair = pair
//			self.array = array
//			self.map = map
//	}
//	
//}

extension AnyInteger where Self: InitableEncoding {
	
	
	public init(encodedValue: ArchiveValue) throws {
		self = try encodedValue.integerValue()
	}
	
	public var encodedValue: ArchiveValue {
		return ArchiveValue(integer: self)
	}
	
}

extension Int8: InitableEncoding { }
extension UInt8: InitableEncoding { }
extension Int16: InitableEncoding { }
extension UInt16: InitableEncoding { }
extension Int32: InitableEncoding { }
extension UInt32: InitableEncoding { }
extension Int64: InitableEncoding { }
extension UInt64: InitableEncoding { }
extension Int: InitableEncoding { }
extension UInt: InitableEncoding { }


extension Bool: InitableEncoding {

	public init(encodedValue: ArchiveValue) throws {
		self = try encodedValue.booleanValue()
	}
	
	public var encodedValue: ArchiveValue {
		return ArchiveValue(boolean: self)
	}
	
}


extension AnyFloat where Self: InitableEncoding {
	
	public init(encodedValue: ArchiveValue) throws {
		self = try encodedValue.floatValue()
	}
	
	public var encodedValue: ArchiveValue {
		return ArchiveValue(float: self)
	}
	
}

extension Float32: InitableEncoding { }
extension Float64: InitableEncoding { }


extension String: InitableEncoding {
	
	public init(encodedValue: ArchiveValue) throws {
		self = try encodedValue.stringValue()
	}
	
	public var encodedValue: ArchiveValue {
		return ArchiveValue(string: self)
	}
	
}


extension NSData: Encoding {
	
	public static func initWithEncodedValue(encodedValue: ArchiveValue) throws -> Self {
		let bytes = try encodedValue.dataValue()
		return bytes.withUnsafeBufferPointer { buf in
			return self.init(bytes: buf.baseAddress, length: bytes.count)
		}
	}
	
	public var encodedValue: ArchiveValue {
		var bytes = ByteArray(count: length, repeatedValue: 0)
		bytes.withUnsafeMutableBufferPointer { (inout buf: UnsafeMutableBufferPointer<Byte>) in
			self.getBytes(buf.baseAddress, length: length)
		}
		return ArchiveValue(data: bytes)
	}
	
}

extension Array: InitableEncoding {
	
	public init(encodedValue: ArchiveValue) throws {
		fatalError()
	}
	
	public var encodedValue: ArchiveValue {
		return ArchiveValue(array: self.lazy.map { $0 as! Archiving })
	}
	
}

extension Dictionary: InitableEncoding {
	
	public init(encodedValue: ArchiveValue) throws {
		fatalError()
	}
	
	public var encodedValue: ArchiveValue {
		return ArchiveValue(map: self.lazy.map { ($0.0 as! Archiving, $0.1 as! Archiving) })
	}
	
}
