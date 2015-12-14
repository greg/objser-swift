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
	
	static func createFromSerialised(value: Serialised) throws -> Self {
		fatalError()
	}
	
	var serialisingValue: Serialising {
		return Serialising(map: SerialisingMapper().map(self))
	}
	
}

private class SerialisingMapper: Mapper {
	
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
		