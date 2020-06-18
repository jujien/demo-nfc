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
    
    static let ACK_WRITE: UInt8 = 0x0a
    
    static let EMPTY: UInt8 = 0x00
}

struct MifareUltralightMemoryOrganization {
    static let NUMBER_PAGE: UInt8 = 48
    
    static let SIZE_PER_PAGE: UInt8 = 4
    
    static var MEMORY_SIZE: UInt8 {
        self.NUMBER_PAGE * self.SIZE_PER_PAGE
    }
    
    static let UID_PAGES: [UInt8] = [0x00, 0x01, 0x02] // first bytes on page 0x02
    static let LOCK_PAGES: [UInt8] = [0x02, 0x28] // 2 last bytes on page 0x02 and 2 bytes first on page 0x28
    static let OTP_PAGES: UInt8 = 0x03
    static let USER_PAGES: [UInt8] = (0x04...0x27).map { $0 }
    static let COUNTER_PAGES: UInt8 = 0x29 // 2 first bytes on page 0x29
    static let AUTHENTICATION_CONFIG_PAGES: [UInt8] = [0x2a, 0x2b]
    static let AUTHENTICATION_KEY_PAGES: [UInt8] = [0x2c, 0x2d, 0x2e, 0x2f]
    
    static func totalSize(start page: UInt8? = nil) -> UInt8? {
        let page = page != nil ? page! : self.USER_PAGES.first!
        guard let index = self.USER_PAGES.firstIndex(of: page) else { return nil }
        
        return self.USER_PAGES[index..<MifareUltralightMemoryOrganization.USER_PAGES.count].map { _ in MifareUltralightMemoryOrganization.SIZE_PER_PAGE }.reduce(UInt8.zero, +)
    }
    
    static func containUserPages(of page: UInt8) -> Bool { self.USER_PAGES.contains(page) }
    
    static func enoughMemory(data: Data, page: UInt8) -> Bool {
        guard let totalSize = self.totalSize(start: page) else { return false }
        return data.count <= totalSize
    }
}
