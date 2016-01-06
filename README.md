# ObjSer: object graph serialisation for Swift

[![GitHub license](https://img.shields.io/github/license/ObjSer/objser-swift.svg)](https://github.com/ObjSer/objser-swift/blob/master/LICENSE)
[![GitHub release](https://img.shields.io/github/release/ObjSer/objser-swift.svg)](https://github.com/ObjSer/objser-swift/releases)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

ObjSer reference implementation in Swift.

*Note: Though this library complies with the ObjSer specification, it is in alpha stages and is not recommended for production use as it is largely untested, and the API is subject to breaking changes.*

## Features

See the [ObjSer](https://github.com/ObjSer/objser) repository for a description of the serialisation format.

- Serialisation of any Swift type, including custom structs, classes, and enums ([protocol conformance](#custom-types) required, but provided by the library for most standard library types)
- Serialisation of values & collections of non-concrete type (see [Protocol types](#protocol-types-and-collections-thereof))
- Serialisation of **any object graph**, including cyclic graphs (where objects reference each other in a loop)
- Deduplication: objects that are referenced multiple times are only stored once

## Installation

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a simple, decentralised dependency manager. Add the following line to your [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile):

```
github "ObjSer/objser-swift" ~> 0.3
```

After running `carthage update`, add the relevant framework (ObjSer iOS or ObjSer Mac) from Carthage/Build to the Embedded Binaries section in your target.

### Manual

Download or clone the repository, and drag ObjSer.xcodeproj into your project. In your target settings, add the relevant framework (ObjSer iOS or ObjSer Mac) to the Embedded Binaries section in the General tab, and to Target Dependences in the Build Phases tab.

OR

Add all source files in the Objser folder directly to your project. They will be treated as part of your project's module, which may cause namespace conflicts.

## Usage

### Serialisation

The serialiser serialises a single root object, as per the specification.

```swift
// the root object to be serialised, for example an array of CGPoint
let rootObject: [CGPoint] = ...
// create an output stream (this API will change in the future)
let stream = OutputStream()
// serialise the object to the output stream
ObjSer.serialise(rootObject, to: stream)
// get the resulting byte array
let bytes = stream.bytes
```

### Deserialisation

```swift
// create an input stream (this API will change in the future)
let stream = InputStream(bytes: bytes)
// provide the deserialiser with necessary type information by specifying the root object's type
let rootObject = try? ObjSer.deserialiseFrom(stream) as [CGPoint]
```

### Custom types

To make a type serialisable, add conformance to the `Serialisable` protocol or one of its subprotocols.

Conformance extensions for most standard library types are provided.

#### `Serialisable`

The `Serialisable` protocol is intended for encoding primitive types: integers, strings, arrays, dictionaries, etc. A conforming object must be able to initialise from a `Deserialising` value, and produce a `Serialising` value representing itself when requested.

A class that may be part of a cycle in the object graph must conform to `Serialisable` directly:

```swift
class Cyclic: Serialisable {
    
    var a = 0
    weak var c: Cyclic!
    
    required init() { }
    
    static func createForDeserialising() -> Serialisable {
        return self.init()
    }

    func deserialiseWith(des: Deserialiser) throws {
        a = try des.deserialiseKey("a") ?? 0
        c = try des.deserialiseKey("c")
    }

    func serialiseWith(ser: Serialiser) {
        ser.serialise(a, forKey: "a")
        ser.serialise(c, forKey: "c")
    }

}
```

A static constructor is required in place of an initialiser in order to make it possible to extend non-final classes to conform to `Serialisable` (it is impossible to add required initialisers in extensions).

An empty initialiser separated from the deserialisation process is used in order to correctly reconstruct cycles in the object graph if necessary.

#### `AcyclicSerialisable`

If you are extending a non-final class out of your control that **never forms cycles**, e.g. `NSData`, and are not able to add required initialisers, conform to `AcyclicSerialisable`:

```swift
extension NSData: AcyclicSerialisable {

    public static func createByDeserialisingWith(des: Deserialiser) throws -> AcyclicSerialisable {
        let bytes = try des.deserialiseData()
        return bytes.withUnsafeBufferPointer { buf in
            return self.init(bytes: buf.baseAddress, length: bytes.count)
        }
    }

    public func serialiseWith(ser: Serialiser) {
        var bytes = ByteArray(count: length, repeatedValue: 0)
        bytes.withUnsafeMutableBufferPointer { (inout buf: UnsafeMutableBufferPointer<Byte>) in
            self.getBytes(buf.baseAddress, length: length)
        }
        ser.serialise(data: bytes)
    }
    
}
```

#### `InitableSerialisable`

This protocol is provided as a convenience for types that match the criteria for `AcyclicSerialisable`, and are able to implement required initialisers.

```swift
extension Bool: InitableSerialisable {

    public init(deserialiser des: Deserialiser) throws {
        self = try des.deserialiseBool()
    }

    public func serialiseWith(ser: Serialiser) {
        ser.serialise(boolean: self)
    }

}
```

See [Conformance.swift](ObjSer/Conformance.swift) for further examples.

**Note:** Do not catch errors thrown by `Deserialiser`'s `deserialise` functions. If deserialisation fails, rethrow a caught error, or throw a new one.

### Protocol types, and collections thereof

To serialise an object of protocol type, the object must be saved along with a unique type identifier so it can be correctly deserialised. Override the static variable `typeUniqueIdentifier` in each concrete type you plan to serialise when stored in a variable of protocol type, to return a unique value:

```swift
extension Int {
    static var typeUniqueIdentifier: String? {
        return "Int"
    }
}
```

To successfully deserialise a collection of protocol type, pass an array of the types that may occur in the collection to the deserialiser:

```swift
let array: [Serialisable] = try ObjSer.deserialiseFrom(stream, identifiableTypes: [Int.self, Float.self])
```

Note: `typeUniqueIdentifier` is defined in the `Serialisable` protocol. All protocol types must conform to the `Serialisable` protocol in order to be serialised.

## Implementation notes

-	The errors thrown by various functions are currently largely undocumented, and their associated objects are not very useful for determining the cause of an error. These will be significantly changed, and should not be depended on (use `try?` on throwing functions instead trying to make sense of a caught error).

-	The current `InputStream` and `OutputStream` structs are temporary; a better IO API will be added in the future.

-	Due to the inability to add constrained protocol inheritance (`extension Array : Serialisable where Element : Serialisable`) in Swift 2.1, extensions to `Array`, `Dictionary` mark the entire type as conforming, and raise runtime errors if a non-conforming type is contained within.

	An unfortunate side effect of this is the lack of compile-time errors when archiving or mapping an array, dictionary, or optional containing value(s) that do not conform to `Serialisable`. This is eased somewhat by descriptive runtime error messages that provide sufficient type information to locate and correct non-conforming types.

	The alternative to this approach would be to provide a large number of boilerplate methods in the serialiser and deserialiser to handle various permutations of nested arrays, dictionaries, optionals, etc., which would provide compile-time type-checking at the expense of API simplicity, code size, and the inevitable lack of support for an obscure edge case.

	In future, it will hopefully be possible to amend this as complete generics are added to [Swift 3.0](https://github.com/apple/swift-evolution).

