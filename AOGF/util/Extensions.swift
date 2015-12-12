//
//  Extensions.swift
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

struct PairSequenceGenerator<T>: GeneratorType {
	
	typealias Element = (T, T)
	private var generator: AnyGenerator<T>
	
	mutating func next() -> (T, T)? {
		guard let a = generator.next(), let b = generator.next() else { return nil }
		return (a, b)
	}
	
}

struct PairSequence<Element>: SequenceType {
	
	private let sequence: AnySequence<Element>
	
	init<S : SequenceType where S.Generator.Element == Element>(_ seq: S) {
		sequence = AnySequence(seq)
	}
	
	typealias Generator = PairSequenceGenerator<Element>
	
	func generate() -> PairSequenceGenerator<Element> {
		return PairSequenceGenerator(generator: sequence.generate())
	}
	
	func underestimateCount() -> Int {
		return sequence.underestimateCount() / 2
	}
	
}

extension Dictionary {
	
	init<S : SequenceType where S.Generator.Element == (Key, Value)>(sequence: S) {
		self.init(minimumCapacity: sequence.underestimateCount())
		for (k, v) in sequence {
			self[k] = v
		}
	}
	
}
