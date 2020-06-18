//
//  NFCTagReadService.swift
//  TestNFC
//
//  Created by jujien on 6/18/20.
//  Copyright © 2020 fitden. All rights reserved.
//

import Foundation
import RxSwift

protocol NFCTagRead {
    func read(session: NFCTagSession, start page: UInt8) -> Observable<Data>
}

struct DefaultNFCTagReadService: NFCTagRead {
    func read(session: NFCTagSession, start page: UInt8) -> Observable<Data> {
        guard session.tags.count == 1 else { return .error(ErrorCode.ConnectNFCError.notSupportMultipleTags) }
        
        guard case .miFare(let tag) = session.tags[0] else { return .error(ErrorCode.ConnectNFCError.notSupportTag) }
        return .create { (observer) -> Disposable in
            let command = [CommandMifareUltralight.READ, page]
            tag.sendMiFareCommand(commandPacket: command.data) { (data, error) in
                if let error = error {
                    observer.onError(error)
                } else {
                    observer.onNext(data)
                }
            }
            return Disposables.create()
        }
    }
}
