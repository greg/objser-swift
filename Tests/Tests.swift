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
		
		let f = Format(array: [
			Format(integer: 152352050802),
			Format(string: "aoeu"),
			Format(data: []),
			Format(float: 3.14159265358979323846),
			Format(data: [4, 255]),
			Format(map: []),
			Format(integer: -1),
			Format(array: []),
			nil,
			Format(boolean: true),
			Format(array: [
				Format(string: ""),
				Format(map: [
					Format(integer: -7), Format(boolean: false)
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

		XCTAssertEqual(f, g)
    }
    
}
