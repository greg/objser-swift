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
    case ref6 = 0x00
    case ref8 = 0x40
    case ref16 = 0x60
    case ref32 = 0x70
    
    /// 0x80 – 0xbf
    case posInt6 = 0x80
    /// 0xe0 – 0xff
    case negInt5 = 0xe0
    
    case `false` = 0xc0
    case `true` = 0xc1
    
    case `nil` = 0xc2
    
    case int8 = 0xc3
    case int16 = 0xc4
    case int32 = 0xc5
    case int64 = 0xc6
    case uInt8 = 0xc7
    case uInt16 = 0xc8
    case uInt32 = 0xc9
    case uInt64 = 0xca
    
    case float32 = 0xcb
    case float64 = 0xcc
    
    /// 0x71 – 0x7f
    case fString = 0x71
    case vString = 0xcd
    case eString = 0xce
    
    /// 0x61 – 0x6f
    case fData = 0x61
    case vData8 = 0xd0
    case vData16 = 0xd1
    case vData32 = 0xd2
    case eData = 0xd3
    
    /// 0x41 – 0x5f
    case fArray = 0x41
    case vArray = 0xd4
    case eArray = 0xd5
    
    case map = 0xd6
    case eMap = 0xd7
    
    case typeID = 0xd8
    
    case sentinel = 0xcf
    
    /// 0xd9 – 0xdf
    case reserved = 0xd9
    
    var byte: Byte {
        switch self {
        case .fString: return 0x70
        case .fData: return 0x60
        case .fArray: return 0x40
        default: return rawValue
        }
    }
    
    var range: ClosedRange<Byte> {
        switch self {
        case .ref6: return 0x00...0x3f
        case .posInt6: return 0x80...0xbf
        case .negInt5: return 0xe0...0xff
        case .fString: return 0x71...0x7f
        case .fData: return 0x61...0x6f
        case .fArray: return 0x41...0x5f
        case .reserved: return 0xd9...0xdf
        default: return rawValue...rawValue
        }
    }
}
