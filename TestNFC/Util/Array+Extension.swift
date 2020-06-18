//
//  Array+Extension.swift
//  TestNFC
//
//  Created by jujien on 6/17/20.
//  Copyright © 2020 fitden. All rights reserved.
//

import Foundation

extension Array where Element == UInt8 {
    var data: Data { Data(self) }
    
    func hexEncodedString(options: Data.HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined(separator: ":")
    }
}
