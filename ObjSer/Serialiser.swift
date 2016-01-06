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

    private enum Indexing {
        case Empty
        case Mapping(ContiguousArray<Primitive>)
        case Value(Primitive)
    }

    init() { }

    func serialiseRoot<T : Serialisable>(v: T) {
        index(v)
    }

    private var indexStack = ContiguousArray<Indexing>()
    private var indexing = true

    /// Serialise `v` for `key` in the object.
    public func serialise<T : Serialisable>(v: T, forKey key: String) {
        let i = indexStack.count - 1
        var dict: ContiguousArray<Primitive>
        switch indexStack[i] {
        case .Empty:
            dict = []
        case .Mapping(let v):
            dict = v
        case .Value(_):
            preconditionFailure("Cannot store value for key in object that already has a sole value.")
        }
        dict.append(indexAndPromise(key))
        dict.append(indexAndPromise(v))
        indexStack[i] = .Mapping(dict)
    }

    private func setSoleValue(v: Primitive) {
        guard case .Empty = currentObject else {
            preconditionFailure("Cannot set a sole value for an object that already has a value.")
        }
        currentObject = .Value(v)
    }

    // MARK: Indexing

    private var currentObject: Indexing {
        get { return indexStack.last! }
        set { indexStack[indexStack.count-1] = newValue }
    }

    private func startNewObject() {
        indexStack.append(.Empty)
    }

    private func finishObject() -> Primitive {
        let v = indexStack.popLast()!
        switch v {
        case .Empty:
            preconditionFailure("Object being serialised (of type \(v.dynamicType)) did not call any serialise functions in its implementation of serialiseWith.")
        case .Mapping(let m):
            return .Map(m)
        case .Value(let v):
            return v
        }
    }

    private var objects = ContiguousArray<(primitive: Primitive!, typedIDs: [String : Int]?)>()
    private var objectIDs = [ObjectIdentifier : Int]()
    private var stringIDs = [String : Int]()

    /// - Requires: `T : Serialisable`
    private func index<T /*: Serialisable*/>(v: T) -> Int {
        precondition(indexing, "Cannot index object: indexing has already completed.")
        precondition(v is Serialisable, "Object of type \(v.dynamicType) : \(T.self) does not conform to Serialisable.")
        let v = v as! Serialisable

        func unidentifiedIndex(v: Serialisable) -> Int {
            let newID = objects.count
            // TODO: complete graph deduplication, including value types
            // deduplicate strings
            if let s = v as? String {
                if let sid = stringIDs[s] {
                    return sid
                }
                stringIDs[s] = newID
            }
            // deduplicate objects to prevent cycles
            else if let o = v as? AnyObject {
                let oid = ObjectIdentifier(o)
                if let oid = objectIDs[oid] {
                    return oid
                }
                objectIDs[oid] = newID
            }
            
            objects.append((nil, nil))
            startNewObject()
            v.serialiseWith(self)
            objects[newID].primitive = finishObject()
            return newID
        }

        let id = unidentifiedIndex(v)

        // type-identify if non-concrete
        if !(T.self is Serialisable.Type) {
            guard let name = v.dynamicType.typeUniqueIdentifier else {
                preconditionFailure("Object of type \(v.dynamicType) placed in container requiring a typeUniqueIdentifier to be provided, but does not provide one.")
            }
            objects[id].typedIDs = objects[id].typedIDs ?? [:]
            if let tid = objects[id].typedIDs![name] { return tid }
            let tid = objects.count
            objects.append((nil, nil))
            objects[tid].primitive = .TypeIdentified(name: self.indexAndPromise(name), value: promise(id))
            objects[id].typedIDs![name] = tid
            return tid
        }
        return id
    }

    /// - Requires: `T : Serialisable`
    private func indexAndPromise<T /*: Serialisable*/>(v: T) -> Primitive {
        let id = index(v)
        return promise(id)
    }

    private func promise(id: Int) -> Primitive {
        return .Promised({
            return self.resolve(id)
        })
    }
    
    // MARK: Output
    
    private func resolve(id: Int) -> Primitive {
        precondition(!indexing, "Cannot resolve promised primitive (index id \(id)) until indexing completes.")
        let n = objects.count
        // Resolve the ids so the largest is the root object, as it should be the least referenced
        
        return .Reference(UInt32(n-id-1))
    }
    
    func writeTo(stream: OutputStream) {
        indexing = false
        // Write in reverse order, since the root object must be last.
        // TODO: count object references and sort by count, so most used objects get smaller ids
        for p in objects.reverse() {
            p.primitive.writeTo(stream)
        }
    }
    
}

extension Serialiser {

    /// Serialise `v` as the sole value of the object.
    /// - Warning: Do _not_ call any other `serialise` functions within the same implementation of `serialiseWith`.
    public func serialise<T>(unconstrained serialisable: T) {
        setSoleValue(indexAndPromise(serialisable))
    }

    /// Serialise `v` as the sole value of the object.
    /// - Warning: Do _not_ call any other `serialise` functions within the same implementation of `serialiseWith`.
    public func serialise<T : Serialisable>(serialisable: T) {
        serialise(unconstrained: serialisable)
    }

    /// Serialise `v` as the sole value of the object.
    /// - Warning: Do _not_ call any other `serialise` functions within the same implementation of `serialiseWith`.
    public func serialise<T : IntegralType>(integer v: T) {
        setSoleValue(.Integer(AnyInteger(v)))
    }

    /// Serialise `v` as the sole value of the object.
    /// - Warning: Do _not_ call any other `serialise` functions within the same implementation of `serialiseWith`.
    public func serialise(nilValue v: ()) {
        setSoleValue(.Nil)
    }

    /// Serialise `v` as the sole value of the object.
    /// - Warning: Do _not_ call any other `serialise` functions within the same implementation of `serialiseWith`.
    public func serialise(boolean v: Bool) {
        setSoleValue(.Boolean(v))
    }

    /// Serialise `v` as the sole value of the object.
    /// - Warning: Do _not_ call any other `serialise` functions within the same implementation of `serialiseWith`.
    public func serialise<T : FloatType>(float v: T) {
        setSoleValue(.Float(AnyFloat(v)))
    }

    /// Serialise `v` as the sole value of the object.
    /// - Warning: Do _not_ call any other `serialise` functions within the same implementation of `serialiseWith`.
    public func serialise(string v: String) {
        setSoleValue(.String(v))
    }

    /// Serialise `v` as the sole value of the object.
    /// - Warning: Do _not_ call any other `serialise` functions within the same implementation of `serialiseWith`.
    public func serialise<S : SequenceType where S.Generator.Element == Byte>(data bytes: S) {
        setSoleValue(.Data(ByteArray(bytes)))
    }

    /// Serialise `v` as the sole value of the object.
    /// - Requires: `S.Generator.Element : Serialisable`
    /// - Warning: Do _not_ call any other `serialise` functions within the same implementation of `serialiseWith`.
    public func serialise<S : SequenceType>(unconstrainedArray seq: S) {
        setSoleValue(.Array(ContiguousArray(seq.map { indexAndPromise($0) })))
    }

    /// Serialise `v` as the sole value of the object.
    /// - Warning: Do _not_ call any other `serialise` functions within the same implementation of `serialiseWith`.
    public func serialise<S : SequenceType where S.Generator.Element : Serialisable>(array seq: S) {
        serialise(unconstrainedArray: seq)
    }

    /// Serialise `v` as the sole value of the object.
    /// - Requires: `S.Generator.Element == (K : Serialisable, V : Serialisable)`
    /// - Warning: Do _not_ call any other `serialise` functions within the same implementation of `serialiseWith`.
    public func serialise<S : SequenceType, K, V where S.Generator.Element == (K, V)>(unconstrainedMap seq: S) {
        var a = ContiguousArray<Primitive>()
        a.reserveCapacity(seq.underestimateCount() * 2)
        for (key, val) in seq {
            a.append(indexAndPromise(key))
            a.append(indexAndPromise(val))
        }
        setSoleValue(.Map(a))
    }

    /// Serialise `v` as the sole value of the object.
    /// - Warning: Do _not_ call any other `serialise` functions within the same implementation of `serialiseWith`.
    public func serialise<S : SequenceType, K : Serialisable, V : Serialisable where S.Generator.Element == (K, V)>(map seq: S) {
        serialise(unconstrainedMap: seq)
    }

}
