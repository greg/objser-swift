//
//  Conformance.swift
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

#if os(OSX)
	import class Foundation.NSData
	import struct Foundation.CGFloat
#elseif os(iOS)
	import Foundation
	import CoreGraphics
#endif

extension AnyInteger where Self: InitableSerialisable {
	
	public init(deserialising value: Deserialising) throws {
		self = try value.integerValue()
	}
	
	public var serialisingValue: Serialising {
		return Serialising(integer: self)
	}
	
}

extension Int8: InitableSerialisable { }
extension UInt8: InitableSerialisable { }
extension Int16: InitableSerialisable { }
extension UInt16: InitableSerialisable { }
extension Int32: InitableSerialisable { }
extension UInt32: InitableSerialisable { }
extension Int64: InitableSerialisable { }
extension UInt64: InitableSerialisable { }
extension Int: InitableSerialisable { }
extension UInt: InitableSerialisable { }


extension Bool: InitableSerialisable {

	public init(deserialising value: Deserialising) throws {
		self = try value.booleanValue()
	}
	
	public var serialisingValue: Serialising {
		return Serialising(boolean: self)
	}
	
}


extension AnyFloat where Self: InitableSerialisable {
	
	public init(deserialising value: Deserialising) throws {
		self = try value.floatValue()
	}
	
	public var serialisingValue: Serialising {
		return Serialising(float: self)
	}
	
}

extension Float32: InitableSerialisable { }
extension Float64: InitableSerialisable { }
extension CGFloat: InitableSerialisable { }


extension String: InitableSerialisable {
	
	public init(deserialising value: Deserialising) throws {
		self = try value.stringValue()
	}
	
	public var serialisingValue: Serialising {
		return Serialising(string: self)
	}
	
}


extension NSData: AcyclicSerialisable {
	
	public static func createByDeserialising(value: Deserialising) throws -> Self {
		let bytes = try value.dataValue()
		return bytes.withUnsafeBufferPointer { buf in
			return self.init(bytes: buf.baseAddress, length: bytes.count)
		}
	}
	
	public var serialisingValue: Serialising {
		var bytes = ByteArray(count: length, repeatedValue: 0)
		bytes.withUnsafeMutableBufferPointer { (inout buf: UnsafeMutableBufferPointer<Byte>) in
			self.getBytes(buf.baseAddress, length: length)
		}
		return Serialising(data: bytes)
	}
	
}

extension Array: InitableSerialisable {
	
	public init(deserialising value: Deserialising) throws {
		precondition(Element.self is Serialisable.Type, "Array element type \(Element.self) does not conform to Serialisable.")
		self = Array(try value.unconstrainedArrayValue())
	}
	
	public var serialisingValue: Serialising {
		precondition(Element.self is Serialisable.Type, "Array element type \(Element.self) does not conform to Serialisable.")
		return Serialising(array: self.lazy.map { $0 as! Serialisable })
	}
	
}

extension Dictionary: InitableSerialisable {
	
	public init(deserialising value: Deserialising) throws {
		precondition(Key.self is Serialisable.Type, "Dictionary key type \(Key.self) does not conform to Serialisable.")
		precondition(Value.self is Serialisable.Type, "Dictionary value type \(Value.self) does not conform to Serialisable.")
		self = Dictionary(sequence: try value.unconstrainedMapValue())
	}
	
	public var serialisingValue: Serialising {
		precondition(Key.self is Serialisable.Type, "Dictionary key type \(Key.self) does not conform to Serialisable.")
		precondition(Value.self is Serialisable.Type, "Dictionary value type \(Value.self) does not conform to Serialisable.")
		return Serialising(map: self.lazy.map { ($0.0 as! Serialisable, $0.1 as! Serialisable) })
	}
	
}

extension Optional: InitableSerialisable {
	
	public init(deserialising value: Deserialising) throws {
		guard let _ = Wrapped.self as? Serialisable.Type else {
			preconditionFailure("Wrapped type \(Wrapped.self) does not conform to Serialisable.")
		}
		do {
			try value.nilValue()
			self = nil
		}
		catch {
			self = try value.unconstrainedObjectValue() as Wrapped
		}
	}
	
	public var serialisingValue: Serialising {
		precondition(Wrapped.self is Serialisable.Type, "Wrapped type \(Wrapped.self) does not conform to Serialisable.")
		if let w = self {
			return Serialising(serialising: w as! Serialisable)
		}
		return nil
	}
	
}

/// Workaround to allow identifying any implicitly unwrapped optional, regardless of generic type.
protocol ImplicitlyUnwrappedOptionalType { }
extension ImplicitlyUnwrappedOptional: ImplicitlyUnwrappedOptionalType { }

extension ImplicitlyUnwrappedOptional: InitableSerialisable {
	
	public init(deserialising value: Deserialising) throws {
		self = try Optional<Wrapped>(deserialising: value)
	}
	
	public var serialisingValue: Serialising {
		return (self as Optional<Wrapped>).serialisingValue
	}
	
}
