//
//  Tests.swift
//  Tests
//
//  Created by Greg Omelaenko on 7/12/2015.
//  Copyright © 2015 Greg Omelaenko. All rights reserved.
//

import XCTest
@testable import AOGF

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFormatCoding() {
		
		let f = Format.Array([
			Format.Integer(152352050802),
			Format.String("aoeu"),
			Format.Data([]),
			Format.Float(3.14159265358979323846),
			Format.Data([4, 255]),
			Format.Map([]),
			Format.Integer(-1),
			Format.Array([]),
			nil,
			Format.Boolean(true),
			Format.Array([
				Format.String(""),
				Format.Map([
					Format.Integer(-7), Format.Boolean(false)
					])
				])
			])
		
		let o = NSOutputStream.outputStreamToMemory()
		o.open()
		f.writeTo(o)
		o.close()
		let data = o.propertyForKey(NSStreamDataWrittenToMemoryStreamKey) as! NSData
		print("data of size \(data.length): \(data)")
		let i = NSInputStream(data: data)
		i.open()
		let g = try! Format(stream: i)
		i.close()
		
		XCTAssertEqual(String(f), String(g))
    }
    
}
