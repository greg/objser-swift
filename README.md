# ObjSer: object graph serialisation for Swift

[![GitHub license](https://img.shields.io/github/license/ObjSer/objser-swift.svg)](https://github.com/ObjSer/objser-swift/blob/master/LICENSE)
[![GitHub release](https://img.shields.io/github/release/ObjSer/objser-swift.svg)](https://github.com/ObjSer/objser-swift/releases)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

ObjSer reference implementation in Swift.

*Note: Though this library complies with the ObjSer specification, it is in alpha stages and is not recommended for production use as it is largely untested, and the API is subject to breaking changes.*

## Features

See the [ObjSer](https://github.com/ObjSer/objser) repository for a description of the serialisation format.

- Serialisation of any Swift type, including custom structs, classes, and enums (protocol conformance required, but provided by the library for most standard library types)
- Serialisation of **any object graph**, including cyclic graphs (where objects reference each other in a loop)
- Deduplication: objects that are referenced multiple times are only stored once

## Installation

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a simple, decentralised dependency manager. Add the following line to your [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile):

```
github "ObjSer/objser-swift" ~> 0.1
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
Serialiser.serialiseRoot(rootObject, to: stream)
// get the resulting byte array
let bytes = stream.bytes
```

### Deserialisation

```swift
// create an input stream (this API will change in the future)
let stream = InputStream(bytes: bytes)
// provide the deserialiser with necessary type information by specifying the root object's type
let rootObject = try? Deserialiser.deserialiseFrom(stream) as [CGPoint]
```

### Custom types

To make a type serialisable, add conformance to the `Serialisable` or `Mappable` protocol.

#### `Serialisable`

The `Serialisable` protocol is intended for encoding primitive types: integers, strings, arrays, dictionaries, etc. A conforming object must be able to initialise from a `Deserialising` value, and produce a `Serialising` value representing itself when requested.

Conformance extensions for most standard library types are provided, so using this protocol is rarely necessary.

If you are extending a class that may be part of a cycle in the object graph, conform to `Serialisable` directly.

If you are extending a non-final class out of your control that **never forms cycles**, e.g. `NSData`, and are not able to add required initialisers, conform to `AcyclicSerialisable`:

```swift
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
```

If you are able to implement required initialisers in a type *that also matches the previous criteria*, and it is more convenient to do so than use a static method, conform to `InitableSerialisable` instead: 

```swift
extension Bool: InitableSerialisable {

	public init(deserialising value: Deserialising) throws {
		self = try value.booleanValue()
	}
	
	public var serialisingValue: Serialising {
		return Serialising(boolean: self)
	}
	
}
```

See [Serialisable.swift](ObjSer/Serialisable.swift) for explanatory documentation, and [Conformance.swift](ObjSer/Conformance.swift) for further examples.

**Note:** Do not catch errors thrown by `Deserialising`'s accessor functions, unless you intend to try a different primitive value if one does not work. If initialisation fails, rethrow a caught error, or throw a new one.

#### `Mappable`

To add archiving support to a class or struct with multiple properties to be serialised, conform to the `Mappable` protocol.

Rather than `NSCoder`-style encode and decode methods, `Mappable` provides a single `mapWith` method that handles both serialisation and deserialisation, to reduce repeated code.

```swift
extension CGPoint: Mappable {
	
	// minimally initialise to dummy values in preparation for mapWith
	public static func createForMapping() -> CGPoint {
		return CGPointZero
	}
	
	// call mapper.map with instance variables and keys to be mapped
	public mutating func mapWith(mapper: Mapper) {
		mapper.map(&x, forKey: "x")
		mapper.map(&y, forKey: "y")
	}
	
}
```

### Collections of protocol type

To serialise a collection of protocol type, each object in the collection must be saved along with a unique type identifier. Override the static variable `typeUniqueIdentifier` in each type you need to serialise in such a collection to return a unique value:

```swift
extension Int {
    static var typeUniqueIdentifier: String? {
        return "Int"
    }
}
```

To successfully deserialise a collection of protocol type, pass an array of the types that may occur in the collection to the deserialiser:

```swift
let array: [Serialisable] = try Deserialiser.deserialiseFrom(stream, identifiableTypes: [Int.self, Float.self])
```

Note: `typeUniqueIdentifier` is defined in the `Serialisable` protocol. All protocol types must conform to the `Serialisable` protocol in order to be serialised.

## Implementation notes

-	The errors thrown by various functions are currently largely undocumented, and their associated objects are not very useful for determining the cause of an error. These will be significantly changed, and should not be depended on (use `try?` on throwing functions instead trying to make sense of a caught error).

-	The current `InputStream` and `OutputStream` structs are temporary; a better IO API will be added in the future.

-	Due to the inability to add constrained protocol inheritance (`extension Array: Serialisable where Element : Serialisable`) in Swift 2.1, extensions to `Array`, `Dictionary`, `Optional`, and `ImplicitlyUnwrappedOptional` mark the entire type as conforming, and raise runtime errors if a non-conforming type is contained within.

	An unfortunate side effect of this is the lack of compile-time errors when archiving or mapping an array, dictionary, or optional containing value(s) that do not conform to `Serialisable`. This is eased somewhat by descriptive runtime error messages that provide sufficient type information to locate and correct non-conforming types.

	The alternative to this approach would be to provide a large number of boilerplate methods in the serialiser and deserialiser to handle various permutations of nested arrays, dictionaries, optionals, etc., which would provide compile-time type-checking at the expense of API simplicity, code size, and the inevitable lack of support for an obscure edge case.

	In future, it will hopefully be possible to amend this as complete generics are added to [Swift 3.0](https://github.com/apple/swift-evolution).

