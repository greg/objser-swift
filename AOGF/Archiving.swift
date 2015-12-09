//
//  Archiving.swift
//  AOGF
//
//  Created by Greg Omelaenko on 8/12/2015.
//  Copyright © 2015 Greg Omelaenko. All rights reserved.
//

import Foundation

public protocol Archiving {
	
	init?(archivingType: ArchiveType)
	
	var archivingType: ArchiveType { get }
	
}
