//
//  Tests.swift
//  Tests
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

import XCTest
@testable import ObjSer

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTypeCoding() {
		
		let f = Primitive.Array([
			Primitive.Integer(152352050802),
			Primitive.String("aoeu"),
			Primitive.Data([]),
			Primitive.Float(3.14159265358979323846),
			Primitive.Data([4, 255]),
			Primitive.Map([]),
			Primitive.Integer(-1),
			Primitive.Array([]),
			Primitive.Nil,
			Primitive.Boolean(true),
			Primitive.Array([
				Primitive.String(""),
				Primitive.Map([
					Primitive.Integer(-7), Primitive.Boolean(false)
					])
				])
			])
		
		let o = OutputStream()
		f.writeTo(o)
//		o.close()
//		let data = o.propertyForKey(NSStreamDataWrittenToMemoryStreamKey) as! NSData
//		print("data of size \(data.length): \(data)")
		let data = o.bytes
//		print("data of size \(data.count): \(data)")
//		let i = NSInputStream(data: data)
//		i.open()
		let i = InputStream(bytes: data)
		let g = try! Primitive(readFrom: i)
//		i.close()
//		
		XCTAssertEqual(String(f), String(g))
		
//		let b = [215,68,113,97,117,97,195,184,101,117,113,98,66,113,99,207] as [UInt8]
//		let ii = NSInputStream(data: NSData(bytes: b, length: b.count))
//		ii.open()
//		let h = try! Primitive(stream: ii)
//		ii.close()
//		print(h)
    }
	
	func testMapping() {
		
		struct S: Mappable {
			var a: [String : Int]
			var b: [Float]
			var c: Bool
			var d: Int!
			var e: [String?]?
			var f: Bool!
			
			private static func createForMapping() -> S {
				return S(a: [:], b: [], c: false, d: nil, e: nil, f: nil)
			}
			
			private mutating func mapWith(mapper: Mapper) {
				mapper.map(&a, forKey: "a")
				mapper.map(&b, forKey: "à very long name that will øverflow into vstring Å.")
				mapper.map(&c, forKey: "ç")
				mapper.map(&d, forKey: "d (implicit optional)")
				mapper.map(&e, forKey: "e (explicit optional)")
				mapper.map(&f, forKey: "implicit f")
			}
		}
		
		
		let a = S(a: ["aoeu": 5, "cgp": -1], b: [4.6, 7.9], c: true, d: nil, e: ["ao´u", nil, "Å"], f: nil)
		
		let o = OutputStream()
		serialise(a, to: o)
		
		let i = InputStream(bytes: o.bytes)
		do {
			let b = try deserialise(i) as S
			print("unarchived", b)
			
			XCTAssertEqual(String(a), String(b))
		}
		catch {
			XCTFail("\(error)")
		}
	}
    
}
