//
//  Archiver.swift
//  AOGF
//
//  Created by Greg Omelaenko on 7/12/2015.
//  Copyright © 2015 Greg Omelaenko. All rights reserved.
//

import Foundation

public class Mapper {
	
	@available(*, unavailable)
	private init() { fatalError("Abstract class Mapper may not be initialised.") }
	
	/// Maps `v` for `key` in the current object.
	/// If `key` is not given, `v` is mapped as the *only* value of the current object. In this case, no values may be mapped for keys within the object.
	public func map<T: Mapping>(inout v: T, forKey key: String? = nil, type: T.Type = T.self) {
		
	}
	
}

class Archiver: Mapper {
	
}

class Unarchiver: Mapper {
	
}
