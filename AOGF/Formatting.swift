//
//  Formatting.swift
//  AOGF
//
//  Created by Greg Omelaenko on 8/12/2015.
//  Copyright © 2015 Greg Omelaenko. All rights reserved.
//

import Foundation

public protocol Formatting {
	
	init?(archivingFormat: Format)
	
	var archivingFormat: Format { get }
	
}
