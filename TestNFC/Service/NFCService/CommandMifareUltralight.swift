//
//  CommandMifareUltralight.swift
//  TestNFC
//
//  Created by jujien on 6/17/20.
//  Copyright © 2020 fitden. All rights reserved.
//

import Foundation

struct CommandMifareUltralight {
    static let READ: UInt8 = 0x30
    static let WRITE: UInt8 = 0xa2
    static let AUTHENTICATE: UInt8 = 0x1a
    
    static let ACK_AUTHENTICATE: UInt8 = 0xaf
    static let END_AUTHENTICATE: UInt8 = 0x00
    
    static let EMPTY: UInt8 = 0x00
}
