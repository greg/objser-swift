//
//  Mappable.swift
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

/// An object that can be serialised by mapping its properties for string keys.
public protocol Mappable: Serialisable {
    
    /// Initialise an instance of `self`, ready for property mapping.
    /// - Remarks: This is a workaround for the impossibility of implementing required initialisers as extensions on non-final classes.
    static func createForMapping() -> Self
    
    /// Uses the provided mapper's `map` function to map its properties.
    mutating func mapWith(mapper: Mapper)
    
}

public protocol Mapper {
    
    /// Maps `v` for `key` in the current object.
    func map<V : Serialisable>(inout v: V, forKey key: String)
    
}

extension Mappable {
    
    public static func createForDeserialising() -> Serialisable /* Self */ {
        return self.createForMapping()
    }
    
    public mutating func deserialiseFrom(value: Deserialising) throws {
        try DeserialisingMapper(deserialising: value).map(&self)
    }
    
    public var serialisingValue: Serialising {
        return Serialising(map: SerialisingMapper().map(self))
    }
    
}

private final class SerialisingMapper: Mapper {
    
    private var map: ContiguousArray<(Serialisable, Serialisable)>!
    
    private func map(var v: Mappable) -> ContiguousArray<(Serialisable, Serialisable)> {
        map = []
        v.mapWith(self)
        return map
    }
    
    func map<V : Serialisable>(inout v: V, forKey key: String) {
        map.append((key, v))
    }
    
}

private final class DeserialisingMapper: Mapper {
    
    private let map: [String : Primitive]
    private let deserialiser: PrimitiveDeserialiser!
    
    private init(deserialising value: Deserialising) throws {
        do {
            self.map = Dictionary(sequence: try value.stringKeyedPrimitiveMapValue())
            self.deserialiser = value.deserialiser
        }
        catch {
            // "All stored properties of a class instance must be initialized before throwing from an initializer"
            self.deserialiser = nil
            self.map = [:]
            throw error
        }
    }
    
    /// An error that occured in the `map` function, to be thrown after `mapWith` returns.
    /// - Remarks: For API usage simplicity, the user-facing `map` and `mapWith` functions are non-throwing, so any errors that prevent decoding from succeeding return to the caller of `deserialise`.
    /// - Remarks: This design may change in the future, if the possibility for the erroneous object to catch its mapping errors and allow mapping to continue demonstrates utility.
    private var mapErrorToThrow: ErrorType?
    
    private var mappingType: Mappable.Type!
    
    private func map<T : Mappable>(inout v: T) throws {
        mappingType = T.self
        v.mapWith(self)
        if let error = mapErrorToThrow {
            mapErrorToThrow = nil
            throw error
        }
    }
    
    func map<V : Serialisable>(inout v: V, forKey key: String) {
        guard let primitive = map[key] else {
            mapErrorToThrow = DeserialiseError.MapFailed(type: mappingType, key: key)
            return
        }
        do {
            v = try deserialiser.deserialise(primitive)
        }
        catch {
            mapErrorToThrow = error
        }
    }
    
}
		