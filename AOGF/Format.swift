//
//  Format.swift
//  AOGF
//
//  Created by Greg Omelaenko on 7/12/2015.
//  Copyright © 2015 Greg Omelaenko. All rights reserved.
//

public typealias FormatArray = ContiguousArray<Format>

// MARK: Formats

/// Defines the AOGF storage formats.
public enum Format {
	
	case Reference(UInt32)
	case Integer(AnyInteger)
	case Nil
	case Boolean(Bool)
	case Float(AnyFloat)
	case String(Swift.String)
	case Data(ByteArray)
	indirect case Pair(Format, Format)
	indirect case Array(FormatArray)
	/// Provide an array of alternating keys and values.
	indirect case Map(FormatArray)
	
	struct Codes {
		/// 0x00 – 0x3f
		static let Ref6: Byte = 0x00
		static let Ref8: Byte = 0x40
		static let Ref16: Byte = 0x60
		static let Ref32: Byte = 0x70
		
		/// 0x80 – 0xbf
		static let PosInt6: Byte = 0x80
		/// 0xe0 – 0xff
		static let NegInt5: Byte = 0xe0
			
		static let False: Byte = 0xc0
		static let True: Byte = 0xc1
			
		static let Nil: Byte = 0xc2
			
		static let Int8: Byte = 0xc3
		static let Int16: Byte = 0xc4
		static let Int32: Byte = 0xc5
		static let Int64: Byte = 0xc6
		static let UInt8: Byte = 0xc7
		static let UInt16: Byte = 0xc8
		static let UInt32: Byte = 0xc9
		static let UInt64: Byte = 0xca
			
		static let Float32: Byte = 0xcb
		static let Float64: Byte = 0xcd
			
		static let Pair: Byte = 0xcc
		
		/// 0x71 – 0x7f
		static let FString: Byte = 0x70
		static let VString: Byte = 0xce
		static let EString: Byte = 0xcf
		
		/// 0x61 – 0x6f
		static let FData: Byte = 0x60
		static let VData8: Byte = 0xd0
		static let VData16: Byte = 0xd1
		static let VData32: Byte = 0xd2
		static let VData64: Byte = 0xd3
		static let EData: Byte = 0xd4
		
		/// 0x41 – 0x5f
		static let FArray: Byte = 0x40
		static let VArray: Byte = 0xd5
		static let EArray: Byte = 0xd6
			
		static let Map: Byte = 0xd7
		static let EMap: Byte = 0xd8
		
		static let Sentinel: Byte = 0xd9
	}
	
	struct Ranges {
		static let Ref6: Range<Byte> = 0x00...0x3f
		
		static let PosInt6: Range<Byte> = 0x80...0xbf
		static let NegInt5: ClosedInterval<Byte> = 0xe0...0xff
		
		static let FString: Range<Byte> = 0x71...0x7f
		
		static let FData: Range<Byte> = 0x61...0x6f
		
		static let FArray: Range<Byte> = 0x41...0x5f
		
		static let Reserved: Range<Byte> = 0xda...0xdf
	}
	
}

extension Format: NilLiteralConvertible {
	
	public init(nilLiteral: ()) {
		self = .Nil
	}
	
}
