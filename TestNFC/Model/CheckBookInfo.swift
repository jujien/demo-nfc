//
//  CheckBookInfo.swift
//  TestNFC
//
//  Created by jujien on 6/18/20.
//  Copyright © 2020 fitden. All rights reserved.
//

import Foundation

struct CheckBookInfo {
    var uid: String
    var data: String
}

struct CheckBookResult {
    var status: Bool
    var newData: String?
    
}
