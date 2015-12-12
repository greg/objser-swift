//
//  Unarchiver.swift
//  AOGF
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

import Foundation

final class Unarchiver: Mapper {
	
	private var objects = ContiguousArray<ArchiveType>()
	
	// MARK: Initialisers
	
	init(readFromStream stream: InputStream) throws {
		while stream.hasBytesAvailable {
			objects.append(try ArchiveType(stream: stream))
		}
	}
	
	// MARK: Conversion
	
	func decodeRootObject<R : Archiving>() throws -> R {
		guard let root = objects.last else { throw UnarchiveError.EmptyInput }
		return try decodeObject(root)
	}
	
	/// An error that occured in the `map` function, to be thrown by `decodeObject` after `archiveMap` returns.
	/// - Remarks: For API usage simplicity, the user-facing `map` and `archiveMap` functions are non-throwing, so any errors that prevent decoding from succeeding are thrown from `decodeObject`, returning to the caller of `unarchive`.
	/// - Remarks: This design may change in the future, if the possibility for the erroneous object to catch its mapping errors and allow mapping to continue demonstrates utility.
	private var mapErrorToThrow: ErrorType?
	
	/// Unconstrained `decodeObject` implementation with runtime assertion of conformance to `Archiving`.
	/// Used for decoding arrays and dictionaries whose conformance to Archiving can't be specialised.
	/// - Requires: `_R : Archiving`. A runtime error will be thrown otherwise.
	private func unconstrainedDecodeObject<_R/** : Archiving */>(t: ArchiveType) throws -> _R {
		let R = _R.self as! Archiving.Type
		// Resolve references
		if case .Reference(let i) = t {
			return try unconstrainedDecodeObject(objects[Int(i)])
		}
		
		if let T = R.self as? Encoding.Type {
			if case .Array(let contents) = t {
				var decoder = ItemDecoder(contents: contents, unarchiver: self)
				defer { decoder.invalidate() }
				return try T.initWithEncodedValue(ArchiveValue(arrayDecoder: decoder)) as! _R
			}
			else if case .Map(let contents) = t {
				var decoder = ItemDecoder(contents: contents, unarchiver: self)
				defer { decoder.invalidate() }
				return try T.initWithEncodedValue(ArchiveValue(mapDecoder: decoder)) as! _R
			}
			else {
				return try T.initWithEncodedValue(ArchiveValue(t)) as! _R
			}
		}
		else if let T = R.self as? Mapping.Type {
			guard case .Map(let contents) = t else {
				throw UnarchiveError.IncorrectType(ArchiveValue(t))
			}
			let map = Dictionary(sequence: try PairSequence(contents).lazy.map {
				(try decodeObject($0.0) as String, $0.1)
				})
			
			maps.append(map)
			mappingObjects.append(T.self)
			
			var v = T.initForMapping()
			v.archiveMap(self)
			
			maps.removeLast()
			mappingObjects.removeLast()
			
			// throw any errors that occured in the map function here.
			if let error = mapErrorToThrow {
				mapErrorToThrow = nil
				throw error
			}
			
			return v as! _R
		}
		else {
			archivingConformanceError(R)
		}
	}
	
	private func decodeObject<R : Archiving>(t: ArchiveType) throws -> R {
		return try unconstrainedDecodeObject(t)
	}
	
	// MARK: Array & Map decoding
	
	private struct ItemDecoder: ArrayDecoder, MapDecoder {
		
		let contents: ArchiveTypeArray
		var unarchiver: Unarchiver!
		mutating func invalidate() { unarchiver = nil }
		
		private func decodeArray<R : Archiving>() throws -> AnySequence<R> {
			return AnySequence(try contents.lazy.map { try unarchiver.decodeObject($0) })
		}
		
		private func unconstrainedDecodeArray<_R>() throws -> AnySequence<_R> {
			return AnySequence(try contents.lazy.map { try unarchiver.unconstrainedDecodeObject($0) })
		}
		
		private func decodeMap<K : Archiving, V : Archiving>() throws -> AnySequence<(K, V)> {
			return try AnySequence(PairSequence(contents).lazy.map({
				(try unarchiver.decodeObject($0.0), try unarchiver.decodeObject($0.1))
			}))
		}
		
		private func unconstrainedDecodeMap<_K, _V>() throws -> AnySequence<(_K, _V)> {
			return try AnySequence(PairSequence(contents).lazy.map({
				(try unarchiver.unconstrainedDecodeObject($0.0), try unarchiver.unconstrainedDecodeObject($0.1))
			}))
		}
		
	}
	
	// MARK: Mapper
	
	private var mappingObjects = ContiguousArray<Mapping.Type>()
	private var maps = ContiguousArray<[String : ArchiveType]>()
	
	func map<V : Archiving>(inout v: V, forKey key: String) {
		guard let t = maps.last![key] else {
			// TODO: handle failure here such as to return silently then throw from decodeObject
			mapErrorToThrow = UnarchiveError.MapFailed(type: mappingObjects.last!, key: key)
			return
		}
		do {
			v = try decodeObject(t)
		}
		catch {
			mapErrorToThrow = error
		}
	}
	
}
