//
//  String+Extension.swift
//  TestNFC
//
//  Created by jujien on 6/17/20.
//  Copyright © 2020 fitden. All rights reserved.
//

import Foundation

extension String {
    var hexadecimal: Data {
        Data(self.utf8)
    }
    
    static func randomString(length: Int) -> String {
      let letters = "!#$%0123456789?@ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }
}
