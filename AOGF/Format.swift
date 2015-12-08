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
/// - Note: Do *not* directly select cases from this enumeration. Use the provided initialisers to correctly select the most appropriate case for a given value.
public enum Format {
	
	case Ref6(Byte)
	case Ref8(Byte)
	case Ref16(ByteArray)
	case Ref32(ByteArray)
	
	case PosInt6(Byte)
	case NegInt5(Byte)
	
	case False
	case True
	
	case Nil
	
	case Int8(Byte)
	case Int16(ByteArray)
	case Int32(ByteArray)
	case Int64(ByteArray)
	case UInt8(Byte)
	case UInt16(ByteArray)
	case UInt32(ByteArray)
	case UInt64(ByteArray)
	
	case Float32(ByteArray)
	case Float64(ByteArray)
	
	indirect case Pair(Format, Format)
	
	case FString(ByteArray)
	case VString(ByteArray)
	case EString
	
	case FData(ByteArray)
	case VData8(ByteArray)
	case VData16(ByteArray)
	case VData32(ByteArray)
	case VData64(ByteArray)
	case EData
	
	indirect case FArray(FormatArray)
	indirect case VArray(FormatArray)
	case EArray
	
	/// Format argument must be an FArray or VArray
	indirect case Map(Format)
	case EMap
	
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

public func ==(a: Format, b: Format) -> Bool {
	switch (a, b) {
	case (.Ref6(let a), .Ref6(let b)): return a == b
	case (.Ref8(let a), .Ref8(let b)): return a == b
	case (.Ref16(let a), .Ref16(let b)): return a == b
	case (.Ref32(let a), .Ref32(let b)): return a == b
	
	case (.PosInt6(let a), .PosInt6(let b)): return a == b
	case (.NegInt5(let a), .NegInt5(let b)): return a == b
	
	case (.False, .False): return true
	case (.True, .True): return true
	
	case (.Nil, .Nil): return true
	
	case (.Int8(let a), .Int8(let b)): return a == b
	case (.Int16(let a), .Int16(let b)): return a == b
	case (.Int32(let a), .Int32(let b)): return a == b
	case (.Int64(let a), .Int64(let b)): return a == b
	case (.UInt8(let a), .UInt8(let b)): return a == b
	case (.UInt16(let a), .UInt16(let b)): return a == b
	case (.UInt32(let a), .UInt32(let b)): return a == b
	case (.UInt64(let a), .UInt64(let b)): return a == b
	
	case (.Float32(let a), .Float32(let b)): return a == b
	case (.Float64(let a), .Float64(let b)): return a == b
	
	case (.Pair(let a1, let a2), .Pair(let b1, let b2)): return a1 == b1 && a2 == b2
	
	case (.FString(let a), .FString(let b)): return a == b
	case (.VString(let a), .VString(let b)): return a == b
	case (.EString, .EString): return true
	
	case (.FData(let a), .FData(let b)): return a == b
	case (.VData8(let a), .VData8(let b)): return a == b
	case (.VData16(let a), .VData16(let b)): return a == b
	case (.VData32(let a), .VData32(let b)): return a == b
	case (.VData64(let a), .VData64(let b)): return a == b
	case (.EData, .EData): return true
	
	case (.FArray(let a), .FArray(let b)): return a == b
	case (.VArray(let a), .VArray(let b)): return a == b
	case (.EArray, .EArray): return true
	
	/// Format argument must be an FArray or VArray
	case (.Map(let a), .Map(let b)): return a == b
	case (.EMap, .EMap): return true
	default: return false
	}
}

extension Format: Equatable { }
