# Object Graph Serialisation (ObjSer) for Swift

ObjSer reference implementation in Swift.

*Note: Though this library currently complies with the ObjSer specification and is mostly functional, it is not recommended for production use as it is largely untested, and the API is subject to breaking changes.*

## Features

See the [ObjSer](https://github.com/PartiallyFinite/objser) repository for a description of the serialisation format.

- Serialisation of any Swift type, including custom structs, classes, and enums (protocol conformance required, but provided by the library for most standard library types)
- Serialisation of **any object graph**, including cyclic graphs (where objects reference each other in a loop)
- Deduplication: objects that are referenced multiple times are only stored once

## Usage

### Serialisation

The serialiser serialises a single root object, as per the specification.

```swift
// the root object to be serialised, for example an array of CGPoint
let rootObject: [CGPoint] = ...
// create an output stream (this API will change in the future)
let stream = OutputStream()
// serialise the object to the output stream
serialise(rootObject, to: stream)
// get the resulting byte array
let bytes = stream.bytes
```

### Deserialisation

```swift
// create an input stream (this API will change in the future)
let stream = InputStream(bytes: bytes)
// provide the deserialiser with necessary type information by specifying the root object's type
let rootObject = try? deserialise(stream) as [CGPoint]
```

### Custom types

To make a type serialisable, add conformance to the `Serialisable` or `Mappable` protocol.

#### `Serialisable`

The `Serialisable` protocol is intended for encoding primitive types: integers, strings, arrays, dictionaries, etc. A conforming object must be able to initialise from a `Serialised` value, and produce one representing itself when requested.

Conformance extensions for most standard library types are provided, so using this protocol is rarely necessary.

If you are extending a non-final class out of your control, e.g. `NSData`, and are not able to add required initialisers, conform to `Serialisable`:

```swift
extension NSData: Serialisable {
	
	public static func createFromSerialised(value: Serialised) throws -> Self {
		let bytes = try value.dataValue()
		return bytes.withUnsafeBufferPointer { buf in
			return self.init(bytes: buf.baseAddress, length: bytes.count)
		}
	}
	
	public var serialisedValue: Serialised {
		var bytes = ByteArray(count: length, repeatedValue: 0)
		bytes.withUnsafeMutableBufferPointer { (inout buf: UnsafeMutableBufferPointer<Byte>) in
			self.getBytes(buf.baseAddress, length: length)
		}
		return Serialised(data: bytes)
	}
	
}
```

If you are able to implement required initialisers in a class, and it is more convenient to do so than use a static method, conform to `InitableSerialisable` instead: 

```swift
extension Bool: InitableSerialisable {

	public init(serialised value: Serialised) throws {
		self = try value.booleanValue()
	}
	
	public var serialisedValue: Serialised {
		return Serialised(boolean: self)
	}
	
}
```

See [Conformance.swift](ObjSer/Conformance.swift) for further examples.

**Note:** Do not catch errors thrown by `Serialised`'s accessor functions, unless you intend to try a different primitive value if one does not work. If initialisation fails, rethrow a caught error, or throw a new one.

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

It is not currently possible to correctly deserialise collections of non-concrete types. This functionality will be added soon.

## Implementation notes

Due to the inability to add constrained protocol inheritance (`extension Array: Serialisable where Element : Serialisable`) in Swift 2.1, extensions to `Array`, `Dictionary`, `Optional`, and `ImplicitlyUnwrappedOptional` mark the entire type as conforming, and raise runtime errors if a non-conforming type is contained within.

An unfortunate side effect of this is the lack of compile-time errors when archiving or mapping an array, dictionary, or optional containing value(s) that do not conform to `Serialisable`. This is eased somewhat by descriptive runtime error messages that provide sufficient type information to locate and correct non-conforming types.

The alternative to this approach would be to provide a large number of boilerplate methods in the serialiser and deserialiser to handle various permutations of nested arrays, dictionaries, optionals, etc., which would provide compile-time type-checking at the expense of API simplicity, code size, and the inevitable lack of support for an obscure edge case.

In future, it will hopefully be possible to amend this as complete generics are added to [Swift 3.0](https://github.com/apple/swift-evolution).

