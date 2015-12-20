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

public final class Serialiser {
	
	public class func serialiseRoot<T : Serialisable>(v: T, to stream: OutputStream) {
		let ser = self.init()
		ser.index(v)
		ser.indexingFinished = true
		ser.writeTo(stream)
	}
	
	private var indexingFinished: Bool = false
	
	private init() { }
	
	// MARK: Indexing
	
	private var objects = ContiguousArray<Primitive!>()
	private var objectIDs = [ObjectIdentifier : Int]()
	private var stringIDs = [String : Int]()
	
	private func index(v: Serialisable, typeIdentified: Bool = false) -> Int {
		let id: Int
		idx: do {
			let newID = objects.count
			// TODO: complete graph deduplication, including value types
			// deduplicate strings
			if let s = v as? String {
				if let sid = stringIDs[s] {
					id = sid
					break idx
				}
				stringIDs[s] = newID
			}
			// deduplicate objects to prevent cycles, exclude ImplicitlyUnwrappedOptional
			else if !(v is ImplicitlyUnwrappedOptionalType), let o = v as? AnyObject {
				let oid = ObjectIdentifier(o)
				if let oid = objectIDs[oid] {
					id = oid
					break idx
				}
				objectIDs[oid] = newID
			}
			
			let ser = v.serialisingValue
			objects.append(nil)
			objects[newID] = ser.convertUsing({ serialisable, typeIdentified in
				self.indexAndPromise(serialisable, typeIdentified: typeIdentified)
			})
			id = newID
		}
		tid: if typeIdentified {
			if case .TypeIdentified = objects[id] as Primitive { break tid }
			guard let name = v.dynamicType.typeUniqueIdentifier else {
				preconditionFailure("Object of type \(v.dynamicType) placed in container requiring a typeUniqueIdentifier to be provided, but does not provide one.")
			}
			objects[id] = .TypeIdentified(name: self.indexAndPromise(name), value: objects[id])
			
		}
		return id
	}
	
	private func indexAndPromise(v: Serialisable, typeIdentified: Bool = false) -> Primitive {
		let id = index(v, typeIdentified: typeIdentified)
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
	
	private func writeTo(stream: OutputStream) {
		// Write in reverse order, since the root object must be last.
		// TODO: count object references and sort by count, so most used objects get smaller ids
		for p in objects.reverse() {
			p.writeTo(stream)
		}
	}
	
}
