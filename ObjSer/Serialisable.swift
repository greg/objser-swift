//
//  Serialisable.swift
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

/// An object that can be serialised.
public protocol Serialisable {
	
	/// Initialise an instance of `self` from the given serialised value.
	/// - Remarks: This is a workaround for the impossibility of implementing initialisers as extensions on non-final classes.
	/// - Note: If you are able to implement a required initialiser on your type, conform to `InitableEncoding` instead.
	static func createFromSerialised(value: Serialised) throws -> Self
	
	var serialisedValue: Serialised { get }
	
}

/// An object that can be serialised and is able to implement required initialisers.
public protocol InitableSerialisable: Serialisable {
	
	/// Initialise from the given encoded value.
	init(serialised value: Serialised) throws
	
}

extension InitableSerialisable {
	
	@transparent public static func createFromSerialised(value: Serialised) throws -> Self {
		return try Self.init(serialised: value)
	}
	
}
