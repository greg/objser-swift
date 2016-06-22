//
//  Conformance.swift
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

#if os(OSX)
    import class Foundation.NSData
    import struct Foundation.CGFloat
#elseif os(iOS)
    import Foundation
    import CoreGraphics
#endif

extension IntegralType where Self: InitableSerialisable {

    public init(deserialiser des: Deserialiser) throws {
        self = try des.deserialiseInteger()
    }

    public func serialise(with ser: Serialiser) {
        ser.serialise(integer: self)
    }

}

extension Int8: InitableSerialisable { }
extension UInt8: InitableSerialisable { }
extension Int16: InitableSerialisable { }
extension UInt16: InitableSerialisable { }
extension Int32: InitableSerialisable { }
extension UInt32: InitableSerialisable { }
extension Int64: InitableSerialisable { }
extension UInt64: InitableSerialisable { }
extension Int: InitableSerialisable { }
extension UInt: InitableSerialisable { }


extension Bool: InitableSerialisable {

    public init(deserialiser des: Deserialiser) throws {
        self = try des.deserialiseBool()
    }

    public func serialise(with ser: Serialiser) {
        ser.serialise(boolean: self)
    }

}


extension FloatType where Self: InitableSerialisable {

    public init(deserialiser des: Deserialiser) throws {
        self = try des.deserialiseFloat()
    }

    public func serialise(with ser: Serialiser) {
        ser.serialise(float: self)
    }

}

extension Float32: InitableSerialisable { }
extension Float64: InitableSerialisable { }
extension CGFloat: InitableSerialisable { }


extension String: InitableSerialisable {

    public init(deserialiser des: Deserialiser) throws {
        self = try des.deserialiseString()
    }
    
    public func serialise(with ser: Serialiser) {
        ser.serialise(string: self)
    }

}


extension Data: AcyclicSerialisable {

    public static func createByDeserialising(with des: Deserialiser) throws -> AcyclicSerialisable {
        let bytes = try des.deserialiseData()
        return bytes.withUnsafeBufferPointer { buf in
            return self.init(bytes: buf.baseAddress!, count: bytes.count)
        }
    }

    public func serialise(with ser: Serialiser) {
        var bytes = ByteArray(repeating: 0, count: count)
        bytes.withUnsafeMutableBufferPointer { (buf: inout UnsafeMutableBufferPointer<Byte>) in
            (self as NSData).getBytes(buf.baseAddress!, length: count)
        }
        ser.serialise(data: bytes)
    }
    
}

extension Array: InitableSerialisable {

    public init(deserialiser des: Deserialiser) throws {
        self = Array(try des.deserialiseArrayUnconstrained())
    }

    public func serialise(with ser: Serialiser) {
        ser.serialise(unconstrainedArray: lazy)
    }
    
}

extension Dictionary: InitableSerialisable {

    public init(deserialiser des: Deserialiser) throws {
        self = Dictionary(sequence: try des.deserialiseMapUnconstrained())
    }

    public func serialise(with ser: Serialiser) {
        ser.serialise(unconstrainedMap: self)
    }

}
