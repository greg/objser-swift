//
//  AOGF.swift
//  AOGF
//
//  Created by Greg Omelaenko on 7/12/2015.
//  Copyright © 2015 Greg Omelaenko. All rights reserved.
//

import Foundation

public enum Error: ErrorType {
	
	case Invalid
	
}

public func archive(rootObject: Archivable) -> NSData {
	fatalError()
}

public func unarchive<T: Archivable>(data: NSData) throws -> T {
	fatalError()
}
