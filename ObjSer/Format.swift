//
//  Format.swift
//  ObjSer
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Greg Omelaenko
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

/// Defines the ObjSer formats.
enum Format: Byte {
    /// 0x00 – 0x3f
    case Ref6 = 0x00
    case Ref8 = 0x40
    case Ref16 = 0x60
    case Ref32 = 0x70
    
    /// 0x80 – 0xbf
    case PosInt6 = 0x80
    /// 0xe0 – 0xff
    case NegInt5 = 0xe0
    
    case False = 0xc0
    case True = 0xc1
    
    case Nil = 0xc2
    
    case Int8 = 0xc3
    case Int16 = 0xc4
    case Int32 = 0xc5
    case Int64 = 0xc6
    case UInt8 = 0xc7
    case UInt16 = 0xc8
    case UInt32 = 0xc9
    case UInt64 = 0xca
    
    case Float32 = 0xcb
    case Float64 = 0xcc
    
    /// 0x71 – 0x7f
    case FString = 0x71
    case VString = 0xcd
    case EString = 0xce
    
    /// 0x61 – 0x6f
    case FData = 0x61
    case VData8 = 0xd0
    case VData16 = 0xd1
    case VData32 = 0xd2
    case EData = 0xd3
    
    /// 0x41 – 0x5f
    case FArray = 0x41
    case VArray = 0xd4
    case EArray = 0xd5
    
    case Map = 0xd6
    case EMap = 0xd7
    
    case TypeID = 0xd8
    
    case Sentinel = 0xcf
    
    /// 0xd9 – 0xdf
    case Reserved = 0xd9
    
    var byte: Byte {
        switch self {
        case .FString: return 0x70
        case .FData: return 0x60
        case .FArray: return 0x40
        default: return rawValue
        }
    }
    
    var range: ClosedInterval<Byte> {
        switch self {
        case .Ref6: return 0x00...0x3f
        case .PosInt6: return 0x80...0xbf
        case .NegInt5: return 0xe0...0xff
        case .FString: return 0x71...0x7f
        case .FData: return 0x61...0x6f
        case .FArray: return 0x41...0x5f
        case .Reserved: return 0xd9...0xdf
        default: return rawValue...rawValue
        }
    }
}
