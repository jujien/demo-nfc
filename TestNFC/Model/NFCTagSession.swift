//
//  NFCTagSession.swift
//  TestNFC
//
//  Created by jujien on 6/17/20.
//  Copyright © 2020 fitden. All rights reserved.
//

import Foundation
import CoreNFC

struct NFCTagSession {
    var tags: [NFCTag]
    var session: NFCTagReaderSession
}
