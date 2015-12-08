//
//  Mapping.swift
//  AOGF
//
//  Created by Greg Omelaenko on 7/12/2015.
//  Copyright © 2015 Greg Omelaenko. All rights reserved.
//

import Foundation

public protocol Mapping {
	
	/// Uses the provided mapper's `map` function to map itself or its properties.
	mutating func archiveMap(mapper: Mapper)
	
}
