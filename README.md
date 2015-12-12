# AOGF for Swift

AOGF object graph serialisation reference implementation in Swift.

*Note: Though this library currently complies with the AOGF specification and is mostly functional, it is not recommended for production use as it is largely untested and the API is liable to change significantly and incompatibly at any time.*

## Features

See the [AOGF](https://github.com/PartiallyFinite/AOGF) repository for a description of the archive format.

- Archiving of any Swift type, including custom structs, classes, and enums (protocol conformance required, but provided by the library for most standard library types)
- Archiving of **any object graph**, including cyclic graphs (where objects reference each other in a loop)
- Deduplication: objects that are referenced multiple times are only stored once

## Usage

### Archiving

The archiver archives a single root object, as per the specification.

```swift
// the root object to be archived, for example an array of CGPoint
let rootObject: [CGPoint] = ...
// create an output stream (this API will change in the future)
let stream = OutputStream()
// archive the object to the output stream
archive(rootObject, to: stream)
// get the resulting byte array
let bytes = stream.bytes
```

### Unarchiving

```swift
// create an input stream (this API will change in the future)
let stream = InputStream(bytes: bytes)
// provide the unarchiver with necessary type information by specifying the root object's type
let rootObject = try? unarchive(stream) as [CGPoint]
```

### Custom types

To make a type archivable, add conformance to the `Encoding` or `Mapping` protocol.

#### `Encoding`

The `Encoding` protocol is intended for encoding primitive types: integers, strings, arrays, dictionaries, etc. A conforming object must be able to initialise from an `ArchiveValue`, and produce one representing itself when requested.

Conformance extensions for most standard library types are provided, so using this protocol is rarely necessary.

If you are extending a non-final class out of your control, e.g. `NSData`, and are not able to add required initialisers, conform to `Encoding`:

```swift
extension NSData: Encoding {
	
	public static func createWithEncodedValue(encodedValue: ArchiveValue) throws -> Self {
		let bytes = try encodedValue.dataValue()
		return bytes.withUnsafeBufferPointer { buf in
			return self.init(bytes: buf.baseAddress, length: bytes.count)
		}
	}
	
	public var encodedValue: ArchiveValue {
		var bytes = ByteArray(count: length, repeatedValue: 0)
		bytes.withUnsafeMutableBufferPointer { (inout buf: UnsafeMutableBufferPointer<Byte>) in
			self.getBytes(buf.baseAddress, length: length)
		}
		return ArchiveValue(data: bytes)
	}
	
}
```

If you are able to implement required initialisers in a class, and it is more convenient to do so than use a static method, conform to `InitableEncoding` instead: 

```swift
extension Bool: InitableEncoding {

	public init(encodedValue: ArchiveValue) throws {
		self = try encodedValue.booleanValue()
	}
	
	public var encodedValue: ArchiveValue {
		return ArchiveValue(boolean: self)
	}
	
}
```

See [Encoding.swift](AOGF/Encoding.swift) for further examples.

**Note:** Do not catch errors thrown by `ArchiveValue`'s accessor functions, unless you intend to try a different primitive value if one does not work. If initialisation fails, rethrow a caught error, or throw a new one.

#### `Mapping`

To add archiving support to a class or struct with multiple properties to be archived, conform to the `Mapping` protocol.

Rather than `NSCoder`-style encode and decode methods, `Mapping` provides a single `archiveMap` method that handles both encoding and decoding, to reduce repeated code.

```swift
extension CGPoint: Mapping {
	
	// minimally initialise to dummy values in preparation for archiveMap
	public static func createForMapping() -> CGPoint {
		return CGPointZero
	}
	
	// call mapper.map with instance variables and keys to be mapped
	public mutating func archiveMap(mapper: Mapper) {
		mapper.map(&x, forKey: "x")
		mapper.map(&y, forKey: "y")
	}
	
}
```

### Collections of protocol type

It is not currently possible to correctly unarchive collections of non-concrete types. This functionality will be added soon.

## Implementation notes

Due to the inability to add constrained protocol inheritance (`extension Array: Encoding where Element : Encoding`) in Swift 2.1, extensions to `Array`, `Dictionary`, `Optional`, and `ImplicitlyUnwrappedOptional` mark the entire type as conforming, and raise runtime errors if a non-conforming type is contained within.

An unfortunate side effect of this is the lack of compile-time errors when archiving or mapping an array, dictionary, or optional containing value(s) that do not conform to `Archiving`. This is eased somewhat by descriptive runtime error messages that provide sufficient type information to locate and correct non-conforming types.

The alternative to this approach would be to provide a large number of boilerplate methods in the archiver and unarchiver to handle various permutations of nested arrays, dictionaries, optionals, etc., which would provide compile-time type-checking at the expense of API simplicity, code size, and the inevitable lack of support for an obscure edge case.

In future, it will hopefully be possible to amend this as complete generics are added to [Swift 3.0](https://github.com/apple/swift-evolution).

