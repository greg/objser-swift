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

final class Serialiser {
	
	// MARK: Initialisers
	
	private var indexingFinished: Bool = false
	
	init<T : Serialisable>(serialiseRoot obj: T) {
		index(obj)
		indexingFinished = true
	}
	
	// MARK: Indexing
	
	private var objects = ContiguousArray<Primitive!>()
	private var objectIDs = [(UnsafePointer<Void>) : Int]()
	private var stringIDs = [String : Int]()
	
	private func index(v: Serialisable) -> Int {
		let newID = objects.count
		// strings somehow magically conform to AnyObject, so handle them first separately.
		if let s = v as? String {
			if let id = stringIDs[s] {
				return id
			}
			stringIDs[s] = newID
		}
		// temporary workaround, assumes that non-mappable objects can't cause cycles, which should usually be true.
		// TODO: proper graph deduplication
		else if v is Mappable, let o = v as? AnyObject {
			// only objects can cause cycles
			let addr = unsafeAddressOf(o)
			if let id = objectIDs[addr] {
				return id
			}
			objectIDs[addr] = newID
		}
		
		let ser = v.serialisingValue
		objects.append(nil)
		objects[newID] = ser.convertUsing({ serialisable in
			self.indexAndPromise(serialisable)
		})
		return newID
	}
	
	private func indexAndPromise(v: Serialisable) -> Primitive {
		let id = index(v)
		return .Promised({
			return self.resolve(id)
		})
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
