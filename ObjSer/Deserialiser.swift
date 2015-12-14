//
//  Deserialiser.swift
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

public final class Deserialiser {
	
	public class func deserialiseFrom<R : Serialisable>(stream: InputStream) throws -> R {
		let des = try self.init(readFrom: stream)
		return try des.deserialiseRoot()
	}
	
	private var objects = ContiguousArray<Primitive>()
	
	private init(readFrom stream: InputStream) throws {
		forwarder = PrimitiveDeserialiserForwarder(deserialiser: self)
		while stream.hasBytesAvailable {
			objects.append(try Primitive(readFrom: stream))
		}
	}
	
	// MARK: Conversion
	
	private func deserialiseRoot<R : Serialisable>() throws -> R {
		guard let root = objects.last else { throw DeserialiseError.EmptyInput }
		return try deserialise(root)
	}
	
	/// Unconstrained `deserialise` implementation.
	/// Used for decoding arrays and dictionaries whose conformance to `Serialisable` can't be specialised.
	/// - Requires: `_R : Serialisable`. A runtime error will be raised otherwise.
	private func unconstrainedDeserialise<_R>(primitive: Primitive) throws -> _R {
		guard let R = _R.self as? Serialisable.Type else {
			preconditionFailure("Could not decode object: \(_R.self) does not conform to Serialisable.")
		}
		// Resolve references
		if case .Reference(let i) = primitive {
			return try unconstrainedDeserialise(objects[Int(i)])
		}
		
		return try R.createByDeserialising(Deserialising(primitive: primitive, deserialiser: forwarder)) as! _R
	}
	
	private func deserialise<R : Serialisable>(primitive: Primitive) throws -> R {
		return try unconstrainedDeserialise(primitive)
	}
	
	private var forwarder: PrimitiveDeserialiserForwarder!
	
	/// Private proxy struct to hide conformance to internal protocol
	private struct PrimitiveDeserialiserForwarder: PrimitiveDeserialiser {
		
		weak var deserialiser: Deserialiser!
		
		func deserialise<R : Serialisable>(primitive: Primitive) throws -> R {
			return try deserialiser.deserialise(primitive)
		}
		
		func unconstrainedDeserialise<_R>(primitive: Primitive) throws -> _R {
			return try deserialiser.unconstrainedDeserialise(primitive)
		}
		
	}
	
}
