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
    
    // Inexact return type is a workaround for compiler error: Method in non-final class must return `Self` to conform to protocol 'Serialisable'
    /// Initialise an instance of `self` for deserialising.
    static func createForDeserialising() -> Serialisable /* Self */
    
    mutating func deserialiseWith(des: Deserialiser) throws

    func serialiseWith(ser: Serialiser)
    
    /// The identifier stored with instances of the type to aid with resolving ambiguity in deserialisation (e.g. collections of protocol type).
    /// - Note: This identifier must be _unique_ amongst all types being (de)serialised. If your type is generic, this identifier should be different for each specialisation (e.g. by including the type parameter's name in the identifier).
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
    
    // Inexact return type is a workaround for compiler error when adding conformance in a protocol extension: Method 'createForDeserialising()' in non-final class must return `Self` to conform to protocol 'AcyclicSerialisable'
    /// Initialise an instance of `self` from the given serialised value.
    /// - Remarks: This is a workaround for the impossibility of implementing initialisers as extensions on non-final classes.
    /// - Note: If you are able to implement a required initialiser on your type, conform to `InitableSerialisable` instead.
    static func createByDeserialisingWith(des: Deserialiser) throws -> AcyclicSerialisable /* Self */
    
}

/// An object that can be serialised, is **never** part of a cycle, and is able to implement required initialisers. This includes all value types.
/// - Warning: If a cycle containing an object conforming to this protocol is encountered, deserialisation will fail.
public protocol InitableSerialisable: AcyclicSerialisable {
    
    /// Initialise from the given encoded value.
    init(deserialiser des: Deserialiser) throws
    
}

extension AcyclicSerialisable {
    
    @transparent
    public static func createForDeserialising() -> Serialisable {
        preconditionFailure("createForDeserialising() must never be called on \(Self.self) : AcyclicSerialisable. Please report this bug.")
    }
    
    @transparent
    public func deserialiseWith(des: Deserialiser) throws {
        preconditionFailure("deserialiseWith(:) must never be called on \(Self.self) : AcyclicSerialisable. Please report this bug.")
    }
    
}

extension InitableSerialisable {
    
    @transparent
    public static func createByDeserialisingWith(des: Deserialiser) throws -> AcyclicSerialisable {
        return try self.init(deserialiser: des)
    }
    
}
