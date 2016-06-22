//
//  PairSequence.swift
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

struct PairSequenceGenerator<T>: IteratorProtocol {
    
    typealias Element = (T, T)
    private var generator: AnyIterator<T>
    
    mutating func next() -> (T, T)? {
        guard let a = generator.next(), let b = generator.next() else { return nil }
        return (a, b)
    }
    
}

struct PairSequence<Element>: Sequence {
    
    private let sequence: AnySequence<Element>
    
    init<S : Sequence where S.Iterator.Element == Element, S.SubSequence : Sequence, S.SubSequence.Iterator.Element == Element, S.SubSequence.SubSequence == S.SubSequence>(_ seq: S) {
        sequence = AnySequence(seq)
    }
    
    typealias Iterator = PairSequenceGenerator<Element>
    
    func makeIterator() -> PairSequenceGenerator<Element> {
        return PairSequenceGenerator(generator: sequence.makeIterator())
    }
    
    func underestimateCount() -> Int {
        return sequence.underestimatedCount / 2
    }
    
}
