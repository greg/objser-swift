//
//  NumericType-Bytes.swift
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

import CoreFoundation

public typealias Byte = UInt8
public typealias ByteArray = ContiguousArray<Byte>

private var isLittleEndian: Bool {
    return __CFByteOrder(UInt32(CFByteOrderGetCurrent())) == CFByteOrderLittleEndian
}

extension NumericType {
    
    /// The bytes of the number, in little-endian order
    var bytes: ByteArray {
        var v = self
        let count = MemoryLayout.size(ofValue: v)
        let b = withUnsafePointer(to: &v) {
            $0.withMemoryRebound(to: Byte.self, capacity: count) {
                ByteArray(UnsafeBufferPointer(start: $0, count: count))
            }
        }
        return isLittleEndian ? b : ByteArray(b.reversed())
    }
    
    /// Initialises the number from bytes given in little-endian order
    init(bytes: ByteArray) {
        func bcast<T>(bytes: ByteArray) -> T {
            return bytes.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: T.self, capacity: 1) {
                    $0.pointee
                }
            }
        }
        self = bcast(bytes: isLittleEndian ? bytes : ByteArray(bytes.reversed()))
    }
    
}
