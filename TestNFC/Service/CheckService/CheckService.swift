//
//  CheckService.swift
//  TestNFC
//
//  Created by jujien on 6/18/20.
//  Copyright © 2020 fitden. All rights reserved.
//

import Foundation
import RxSwift

protocol CheckService {
    func check() -> Observable<Bool>
}

struct DefaultCheckService: CheckService {
    fileprivate let detect: NFCTagDetectSession
    fileprivate let connect: NFCTagConnect
    fileprivate let authentication: NFCTagAuthentication
    fileprivate let read: NFCTagReadService
    fileprivate let write: NFCTagWriteService
    
    init(detect: NFCTagDetectSession, connect: NFCTagConnect, authentication: NFCTagAuthentication, read: NFCTagReadService, write: NFCTagWriteService) {
        self.detect = detect
        self.connect = connect
        self.authentication = authentication
        self.read = read
        self.write = write
    }
    
    func check() -> Observable<Bool> {
        return .empty()
    }
}
