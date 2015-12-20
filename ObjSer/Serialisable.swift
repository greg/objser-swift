//
//  Serialisable.swift
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

/// An object that can be serialised.
/// - Remarks: A regular initialiser cannot be used in this protocol due to the impossibility of obtaining a value for an object before `init` completes, making it impossible to recreate cyclic graphs.
/// - Note: Value types may implement `InitableSerialisable` instead.
public protocol Serialisable {
	
	// Inexact return type is a workaround for compiler error: Method 'createForDeserialising()' in non-final class must return `Self` to conform to protocol 'Serialisable'
	/// Initialise an instance of `self` for deserialising.
	static func createForDeserialising() -> Serialisable /* Self */
	
	mutating func deserialiseFrom(value: Deserialising) throws
	
	var serialisingValue: Serialising { get }
	
	/// The identifier stored with instances of the type to aid with resolving ambiguity in deserialisation (e.g. collections of protocol type).
	static var typeUniqueIdentifier: String? { get }
	
}

extension Serialisable {
	
	public static var typeUniqueIdentifier: String? {
		return nil
	}
	
}

/// An object that can be serialised and is **never** part of a cycle. This includes all value types.
/// - Warning: If a cycle containing an object conforming to this protocol is encountered, deserialisation will fail.
public protocol AcyclicSerialisable: Serialisable {
	
	/// Initialise an instance of `self` from the given serialised value.
	/// - Remarks: This is a workaround for the impossibility of implementing initialisers as extensions on non-final classes.
	/// - Note: If you are able to implement a required initialiser on your type, conform to `InitableSerialisable` instead.
	static func createByDeserialising(value: Deserialising) throws -> Self
	
}

/// An object that can be serialised, is **never** part of a cycle, and is able to implement required initialisers. This includes all value types.
/// - Warning: If a cycle containing an object conforming to this protocol is encountered, deserialisation will fail.
public protocol InitableSerialisable: AcyclicSerialisable {
	
	/// Initialise from the given encoded value.
	init(deserialising value: Deserialising) throws
	
}

extension AcyclicSerialisable {
	
	@transparent
	public static func createForDeserialising() -> Serialisable {
		preconditionFailure("createForDeserialising() must never be called on \(Self.self) : AcyclicSerialisable. Please report this bug.")
	}
	
	@transparent
	public func deserialiseFrom(value: Deserialising) throws {
		preconditionFailure("deserialiseFrom(:) must never be called on \(Self.self) : AcyclicSerialisable. Please report this bug.")
	}
	
}

extension InitableSerialisable {
	
	@transparent
	public static func createByDeserialising(value: Deserialising) throws -> Self {
		return try self.init(deserialising: value)
	}
	
}

public struct Serialising: NilLiteralConvertible {
	
	private enum State {
		case Converted(Primitive)
		case Convertible(((Serialisable, typeIdentified: Bool) -> Primitive) -> Primitive)
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
	
	public init<S : SequenceType where S.Generator.Element == Serialisable>(array seq: S, typeIdentified: Bool = false) {
		state = .Convertible({ serialise in
			var a = ContiguousArray<Primitive>()
			a.reserveCapacity(seq.underestimateCount())
			for serialisable in seq {
				a.append(serialise(serialisable, typeIdentified: typeIdentified))
			}
			return .Array(a)
		})
	}
	
	public init<S : SequenceType where S.Generator.Element == (Serialisable, Serialisable)>(map seq: S, typeIdentifiedKeys: Bool = false, typeIdentifiedValues: Bool = false) {
		state = .Convertible({ serialise in
			var a = ContiguousArray<Primitive>()
			a.reserveCapacity(seq.underestimateCount() * 2)
			for (serialisableKey, serialisableVal) in seq {
				a.append(serialise(serialisableKey, typeIdentified: typeIdentifiedKeys))
				a.append(serialise(serialisableVal, typeIdentified: typeIdentifiedValues))
			}
			return .Map(a)
		})
	}
	
	public init(serialising value: Serialisable, typeIdentified: Bool = false) {
		state = .Convertible({ serialise in
			serialise(value, typeIdentified: typeIdentified)
		})
	}
	
	func convertUsing(serialiser: (serialisable: Serialisable, typeIdentified: Bool) -> Primitive) -> Primitive {
		switch state {
		case .Converted(let p): return p
		case .Convertible(let conv): return conv(serialiser)
		}
	}
	
}

protocol PrimitiveDeserialiser {
	
	func deserialise<R : Serialisable>(primitive: Primitive) throws -> R
	func unconstrainedDeserialise<_R>(primitive: Primitive) throws -> _R
	
}

public struct Deserialising {
	
	private let primitive: Primitive
	let deserialiser: PrimitiveDeserialiser
	
	init(primitive: Primitive, deserialiser: PrimitiveDeserialiser) {
		self.primitive = primitive
		self.deserialiser = deserialiser
	}
	
	public func integerValue<R : AnyInteger>() throws -> R {
		if case .Integer(let v) = primitive {
			if let v: R = v.convert() {
				return v
			}
			throw DeserialiseError.ConversionFailed(v)
		}
		throw DeserialiseError.IncorrectType(self)
	}
	
	public func nilValue() throws -> () {
		if case .Nil = primitive {
			return ()
		}
		throw DeserialiseError.IncorrectType(self)
	}
	
	public func booleanValue() throws -> Bool {
		if case .Boolean(let v) = primitive {
			return v
		}
		throw DeserialiseError.IncorrectType(self)
	}
	
	public func floatValue<R: AnyFloat>() throws -> R {
		if case .Float(let v) = primitive {
			return v.convert()
		}
		throw DeserialiseError.IncorrectType(self)
	}
	
	public func stringValue() throws -> Swift.String {
		if case .String(let v) = primitive {
			return v
		}
		throw DeserialiseError.IncorrectType(self)
	}
	
	public func dataValue() throws -> ByteArray {
		if case .Data(let v) = primitive {
			return v
		}
		throw DeserialiseError.IncorrectType(self)
	}
	
	public func arrayValue<R : Serialisable>() throws -> AnySequence<R> {
		guard case .Array(let a) = primitive else {
			throw DeserialiseError.IncorrectType(self)
		}
		return AnySequence(try a.map {
			try deserialiser.deserialise($0)
		})
	}
	
	/// Unconstrained equivalent of `arrayValue`, provided for convenience when implementing encoding on collection types, as protocol conformance cannot be constrained.
	/// - Requires: `_R : Serialisable`. A runtime error will be thrown otherwise.
	public func unconstrainedArrayValue<_R>() throws -> AnySequence<_R> {
		guard case .Array(let a) = primitive else {
			throw DeserialiseError.IncorrectType(self)
		}
		return AnySequence(try a.map {
			try deserialiser.unconstrainedDeserialise($0)
		})
	}
	
	public func mapValue<K : Serialisable, V : Serialisable>() throws -> AnySequence<(K, V)> {
		guard case .Map(let a) = primitive else {
			throw DeserialiseError.IncorrectType(self)
		}
		return AnySequence(try PairSequence(a).map {
			try (deserialiser.deserialise($0.0), deserialiser.deserialise($0.1))
		})
	}
	
	/// Unconstrained equivalent of `mapValue`, provided for convenience when implementing encoding on collection types, as protocol conformance cannot be constrained.
	/// - Requires: `_K : Serialisable`, `_V : Serialisable`. A runtime error will be thrown otherwise.
	public func unconstrainedMapValue<_K, _V>() throws -> AnySequence<(_K, _V)> {
		guard case .Map(let a) = primitive else {
			throw DeserialiseError.IncorrectType(self)
		}
		return AnySequence(try PairSequence(a).map {
			try (deserialiser.unconstrainedDeserialise($0.0), deserialiser.unconstrainedDeserialise($0.1))
		})
	}
	
	public func objectValue<R : Serialisable>() throws -> R {
		return try deserialiser.deserialise(primitive)
	}
	
	public func unconstrainedObjectValue<_R>() throws -> _R {
		return try deserialiser.unconstrainedDeserialise(primitive)
	}
	
}

extension Deserialising {

	/// Helper function for implementing the Mapping protocol.
	func stringKeyedPrimitiveMapValue() throws -> AnySequence<(String, Primitive)> {
		guard case .Map(let a) = primitive else {
			throw DeserialiseError.IncorrectType(self)
		}
		return AnySequence(try PairSequence(a).map {
			(try deserialiser.unconstrainedDeserialise($0.0) as String, $0.1)
		})
	}
	
}
