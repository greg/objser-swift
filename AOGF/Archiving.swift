//
//  Archiving.swift
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

/// The base protocol for types that can be archived.
/// - Important: Types must conform to a subprotocol, `Encoding` or `Mapping`, as appropriate. Conforming only to this protocol will result in a runtime error.
public protocol Archiving {
	
}

/// Print an explanatory message and unconditionally stop execution.
/// - Requires: `obj` does not conform to either `Encoding` or `Mapping`.
@transparent @noreturn func archivingConformanceFailure(type: Archiving.Type) {
	// don't confuse the user if the implementation is broken
	assert(!(type is Encoding.Type || type is Mapping.Type), "Archiving conformance failure incorrectly raised for type \(type).")
	preconditionFailure("Type \(type) conforms to Archiving, but not Encoding or Mapping.")
}
