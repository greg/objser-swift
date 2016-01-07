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

/// Throws `error` if `condition` evaluates to false.
private func require(@autoclosure condition: () -> Bool, @autoclosure _ error: () -> ErrorType) throws {
    guard condition() else {
        throw error()
    }
}

public final class Deserialiser {

    private var identifiableTypes = [String : Serialisable.Type]()

    private var primitives = ContiguousArray<Primitive>()
    private var deserialised = ContiguousArray<Serialisable?>()

    private enum State {
        case Unknown, Completed
        case Mapping([String : Primitive])
    }

    private var deserialisingStack = ContiguousArray<(primitive: Primitive, state: State)>()

    init(readFrom stream: InputStream, identifiableTypes: [Serialisable.Type]) throws {
        while stream.hasBytesAvailable {
            primitives.append(try Primitive(readFrom: stream))
        }

        try require(primitives.count > 0, DeserialiseError.EmptyInput)

        deserialised = ContiguousArray(count: primitives.count, repeatedValue: nil)
        
        for t in identifiableTypes {
            guard let id = t.typeUniqueIdentifier else {
                throw DeserialiseError.UnidentifiableType(t)
            }
            precondition(self.identifiableTypes[id] == nil, "Duplicate type unique identifier '\(id)' for \(t) and \(self.identifiableTypes[id]!)")
            self.identifiableTypes[id] = t
        }
    }

    /// Return the current primitive.
    /// - Requires: `currentState == .Unkown`, i.e. the primitive has not been consumed either as a sole value or for mapping.
    private var currentPrimitive: Primitive {
        guard case .Unknown = currentState else {
            preconditionFailure("Cannot deserialise a value that has already been deserialised.")
        }
        return deserialisingStack.last!.primitive
    }

    private var currentState: State {
        get { return deserialisingStack.last!.state }
        set { deserialisingStack[deserialisingStack.count-1].state = newValue }
    }

    // MARK: Conversion

    private var errorToThrow: ErrorType?

    @warn_unused_result
    func deserialiseRoot<R : Serialisable>() throws -> R {
        return try deserialise(index: primitives.count - 1)
    }

    @warn_unused_result
    private func deserialise<R /*: Serialisable*/>(index index: Int? = nil, primitive: Primitive? = nil, overrideType O: Any.Type = R.self) throws -> R {
        assert((index != nil) || (primitive != nil), "Index or primitive must be provided.")

        // if top-level and already deserialised, return value
        if let i = index, v = deserialised[i] { return v as! R }

        // get actual required output type and wrapped primitive, if necessary
        let (primitive, O) = try { () -> (Primitive, Any.Type) in
            var primitive = primitive ?? self.primitives[index!], O = O
            while case .TypeIdentified(let id, let p) = primitive {
                let id = try deserialise(primitive: id) as String
                guard let type = identifiableTypes[id] else { throw DeserialiseError.UnknownTypeID(id) }
                O = type; primitive = p
            }
            return (primitive, O)
        }()

        // resolve references
        if case .Reference(let i) = primitive {
            return try deserialise(index: Int(i), overrideType: O)
        }

        deserialisingStack.append((primitive, .Unknown))
        defer { deserialisingStack.removeLast() }

        if let O = O as? AcyclicSerialisable.Type {
            let v = try O.createByDeserialisingWith(self)
            if let i = index { deserialised[i] = v }
            return v as! R
        }
        else if let O = O as? Serialisable.Type {
            var v = O.createForDeserialising()
            if let i = index { deserialised[i] = v }
            try v.deserialiseWith(self)
            return v as! R
        }
        else {
            preconditionFailure("Could not decode object: \(O) does not conform to Serialisable.")
        }
    }

}

extension Deserialiser {

    /// Return a value of type `R` for `key`, or `nil` if the value does not exist.
    /// - Requires: `R : Serialisable`
    @warn_unused_result
    public func deserialiseKeyUnconstrained<R>(key: String) throws -> R? {
        let map: [String : Primitive]
        switch currentState {
        case .Unknown:
            // get a map out of the primitive
            guard case .Map(let a) = currentPrimitive else {
                throw DeserialiseError.IncorrectType(currentPrimitive)
            }
            map = try [String : Primitive](sequence: PairSequence(a).map {
                (try deserialise(primitive: $0.0), $0.1)
                })
            // save the map to the current state
            currentState = .Mapping(map)
        case .Mapping(let m):
            // there's already a map
            map = m
        case .Completed:
            // object has already been deserialised as a whole value
            preconditionFailure("Cannot perform keyed deserialisation for a value that has already been deserialised.")
        }
        
        guard let v = map[key] else { return nil }
        return try deserialise(primitive: v) as R
    }

    /// Return a value of type `R` for `key`, or `nil` if the value does not exist.
    @warn_unused_result
    public func deserialiseKey<R : Serialisable>(key: String) throws -> R? {
        return try deserialiseKeyUnconstrained(key)
    }

    @warn_unused_result
    public func deserialiseUnconstrained<R>() throws -> R {
        return try deserialise(primitive: currentPrimitive)
    }

    @warn_unused_result
    public func deserialise<R : Serialisable>() throws -> R {
        return try deserialiseUnconstrained()
    }

    @warn_unused_result
    public func deserialiseInteger<R : IntegralType>() throws -> R {
        guard case .Integer(let i) = currentPrimitive else { throw DeserialiseError.IncorrectType(currentPrimitive) }
        guard let v = R(convert: i) else { throw DeserialiseError.ConversionFailed(i) }
        currentState = .Completed
        return v
    }

    public func deserialiseNil() throws -> () {
        guard case .Nil = currentPrimitive else { throw DeserialiseError.IncorrectType(currentPrimitive) }
        currentState = .Completed
        return ()
    }

    @warn_unused_result
    public func deserialiseBool() throws -> Bool {
        guard case .Boolean(let b) = currentPrimitive else { throw DeserialiseError.IncorrectType(currentPrimitive) }
        currentState = .Completed
        return b
    }

    @warn_unused_result
    public func deserialiseFloat<R : FloatType>() throws -> R {
        guard case .Float(let f) = currentPrimitive else { throw DeserialiseError.IncorrectType(currentPrimitive) }
        currentState = .Completed
        return R(f)
    }

    @warn_unused_result
    public func deserialiseString() throws -> String {
        guard case .String(let s) = currentPrimitive else { throw DeserialiseError.IncorrectType(currentPrimitive) }
        currentState = .Completed
        return s
    }

    @warn_unused_result
    public func deserialiseData() throws -> ByteArray {
        guard case .Data(let bytes) = currentPrimitive else { throw DeserialiseError.IncorrectType(currentPrimitive) }
        currentState = .Completed
        return bytes
    }

    @warn_unused_result
    public func deserialiseArrayUnconstrained<R>() throws -> AnySequence<R> {
        guard case .Array(let a) = currentPrimitive else { throw DeserialiseError.IncorrectType(currentPrimitive) }
        return try AnySequence(a.map {
            try deserialise(primitive: $0)
        })
    }

    @warn_unused_result
    public func deserialiseArray<R : Serialisable>() throws -> AnySequence<R> {
        return try deserialiseArrayUnconstrained()
    }

    @warn_unused_result
    public func deserialiseMapUnconstrained<K, V>() throws -> AnySequence<(K, V)> {
        guard case .Map(let a) = currentPrimitive else { throw DeserialiseError.IncorrectType(currentPrimitive) }
        return try AnySequence(PairSequence(a).map {
            try (deserialise(primitive: $0.0), deserialise(primitive: $0.1))
        })
    }

    @warn_unused_result
    public func deserialiseMap<K : Serialisable, V : Serialisable>() throws -> AnySequence<(K, V)> {
        return try deserialiseMapUnconstrained()
    }

}
