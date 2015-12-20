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
	
	@warn_unused_result
	public class func deserialiseFrom<R : Serialisable>(stream: InputStream, identifiableTypes: [Serialisable.Type] = []) throws -> R {
		let des = try self.init(readFrom: stream, identifiableTypes: identifiableTypes)
		return try des.deserialiseRoot()
	}
	
	private var primitives = ContiguousArray<Primitive>()
	private var deserialised = ContiguousArray<Serialisable?>()
	private var identifiableTypes = [String : Serialisable.Type]()
	
	private init(readFrom stream: InputStream, identifiableTypes: [Serialisable.Type]) throws {
		forwarder = PrimitiveDeserialiserForwarder(deserialiser: self)
		while stream.hasBytesAvailable {
			primitives.append(try Primitive(readFrom: stream))
		}
		deserialised = ContiguousArray(count: primitives.count, repeatedValue: nil)
		
		for t in identifiableTypes {
			guard let id = t.typeUniqueIdentifier else {
				throw DeserialiseError.UnidentifiableType(t)
			}
			self.identifiableTypes[id] = t
		}
	}
	
	// MARK: Conversion
	
	@warn_unused_result
	private func deserialiseRoot<R : Serialisable>() throws -> R {
		guard primitives.count > 0 else { throw DeserialiseError.EmptyInput }
		return try deserialiseIndex(primitives.count - 1)
	}
	
	@warn_unused_result
	private func unconstrainedDeserialiseIndex<_R>(i: Int, var type R: Any.Type = _R.self) throws -> _R {
		if let v = deserialised[i] {
			return v as! _R
		}
		let primitive: Primitive
		if case .TypeIdentified(let id, let p) = primitives[i] {
			let id = try deserialise(id) as String
			guard let type = identifiableTypes[id] else {
				throw DeserialiseError.UnknownTypeID(id)
			}
			R = type
			primitive = p
		}
		else {
			primitive = primitives[i]
		}
		guard let R = R.self as? Serialisable.Type else {
			preconditionFailure("Could not decode object: \(_R.self) does not conform to Serialisable.")
		}
		if R is AcyclicSerialisable.Type {
			let r = try unconstrainedDeserialise(primitive, type: R) as _R
			deserialised[i] = (r as! Serialisable)
			return r
		}
		else {
			let r = R.createForDeserialising() as! _R
			deserialised[i] = (r as! Serialisable)
			return try unconstrainedDeserialise(primitive, forObject: r, type: R)
		}
	}
	
	@warn_unused_result
	private func deserialiseIndex<R : Serialisable>(i: Int) throws -> R {
		return try unconstrainedDeserialiseIndex(i)
	}
	
	/// Unconstrained `deserialise` implementation.
	/// Used for decoding arrays and dictionaries whose conformance to `Serialisable` can't be specialised.
	/// - Requires: `_R : Serialisable`. A runtime error will be raised otherwise.
	@warn_unused_result
	private func unconstrainedDeserialise<_R>(primitive: Primitive, forObject object: _R? = nil, type R: Any.Type = _R.self) throws -> _R {
		if case .TypeIdentified(let id, let p) = primitive {
			let id = try deserialise(id) as String
			guard let type = identifiableTypes[id] else {
				throw DeserialiseError.UnknownTypeID(id)
			}
			return try unconstrainedDeserialise(p, type: type) as _R
		}
		
		// Resolve references
		if case .Reference(let i) = primitive {
			return try unconstrainedDeserialiseIndex(Int(i), type: R)
		}
		
		guard let _T = R.self as? Serialisable.Type else {
			preconditionFailure("Could not decode object: \(R.self) does not conform to Serialisable.")
		}
		let R = _T
		
		let des = Deserialising(primitive: primitive, deserialiser: forwarder)
		
		if let R = R as? AcyclicSerialisable.Type {
			assert(object == nil, "Cannot use two-step deserialisation on type \(R) : AcyclicSerialisable.")
			return try R.createByDeserialising(des) as! _R
		}
		
		var obj: Serialisable
		if let object = object {
			obj = object as! Serialisable
		}
		else {
			obj = R.createForDeserialising()
		}
		try obj.deserialiseFrom(des)
		return obj as! _R
	}
	
	@warn_unused_result
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
