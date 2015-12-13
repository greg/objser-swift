//
//  Serialiser.swift
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

final class Serialiser: Mapper {
	
	// MARK: Initialisers
	
	private var indexingFinished: Bool = false
	
	init<T : Serialisable>(serialiseRoot obj: T) {
		index(obj)
		indexingFinished = true
	}
	
	// MARK: Indexing
	
	private var objects = ContiguousArray<Primitive!>()
	private var objectIDs = [(UnsafePointer<Void>) : Int]()
	
	private func index(v: Serialisable) -> Int {
		if let v = v as? Mappable {
			// Only objects can cause cycles
			if let o = v as? AnyObject {
				let addr = unsafeAddressOf(o)
				if let id = objectIDs[addr] {
					return id
				}
				else {
					objectIDs[addr] = objects.count
				}
			}
			let id = objects.count
			
			// append a nil object first, since mapping will index more objects
			objects.append(nil)
			objects[id] = .Map(map(v))
			
			return id
		}
		else {
			let ser = v.serialisedValue
			switch ser.value {
			case .Type(let t):
				let id = objects.count
				objects.append(t)
				return id
			case .EncodingArray(let s):
				let id = objects.count
				objects.append(nil)
				var a = ContiguousArray<Primitive>()
				a.reserveCapacity(s.underestimateCount())
				for v in s {
					a.append(indexAndPromise(v))
				}
				objects[id] = .Array(a)
				return id
			case .EncodingMap(let s):
				let id = objects.count
				objects.append(nil)
				var a = ContiguousArray<Primitive>()
				a.reserveCapacity(s.underestimateCount() * 2)
				for (k, v) in s {
					a.append(indexAndPromise(k))
					a.append(indexAndPromise(v))
				}
				objects[id] = .Map(a)
				return id
			case .EncodingValue(let v):
				return index(v)
			default:
				preconditionFailure("Could not index case \(ser.value).")
			}
		}
	}
	
	private func indexAndPromise(v: Serialisable) -> Primitive {
		let id = index(v)
		return .Promised({
			return self.resolve(id)
		})
	}
	
	// MARK: Mapper
	
	private var maps = ContiguousArray<ContiguousArray<Primitive>>()
	
	func lastMapAppend(v: Primitive) {
		maps[maps.count-1].append(v)
	}
	
	private func map(var v: Mappable) -> ContiguousArray<Primitive> {
		maps.append(ContiguousArray<Primitive>())
		v.mapWith(self)
		return maps.popLast()!
	}
	
	func map<V : Serialisable>(inout v: V, forKey key: String) {
		lastMapAppend(indexAndPromise(key))
		lastMapAppend(indexAndPromise(v))
	}
	
	// MARK: Output
	
	private func resolve(id: Int) -> Primitive {
		precondition(indexingFinished, "Cannot resolve promised primitive (index id \(id)) until indexing completes.")
		let n = objects.count
		// Resolve the ids so the largest is the root object, as it should be the least referenced
		return .Reference(UInt32(n-id-1))
	}
	
	func writeTo(stream: OutputStream) {
		// Write in reverse order, since the root object must be last.
		// TODO: count object references and sort by count, so most used objects get smaller ids
		for t in objects.reverse() {
			t.writeTo(stream)
		}
	}
	
}
