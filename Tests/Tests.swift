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
    
    func testTypeCoding() {
		
		let f = ArchiveType.Array([
			ArchiveType.Integer(152352050802),
			ArchiveType.String("aoeu"),
			ArchiveType.Data([]),
			ArchiveType.Float(3.14159265358979323846),
			ArchiveType.Data([4, 255]),
			ArchiveType.Map([]),
			ArchiveType.Integer(-1),
			ArchiveType.Array([]),
			nil,
			ArchiveType.Boolean(true),
			ArchiveType.Array([
				ArchiveType.String(""),
				ArchiveType.Map([
					ArchiveType.Integer(-7), ArchiveType.Boolean(false)
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
		let g = try! ArchiveType(stream: i)
		i.close()
		
		XCTAssertEqual(String(f), String(g))
    }
    
}
