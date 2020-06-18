//
//  NFCTagWriteService.swift
//  TestNFC
//
//  Created by jujien on 6/18/20.
//  Copyright © 2020 fitden. All rights reserved.
//

import Foundation
import RxSwift

protocol NFCTagWrite {
    func write(session: NFCTagSession, data: [UInt8], on page: UInt8) -> Observable<Data>
}

struct DefaultNFCTagWrite: NFCTagWrite {
    func write(session: NFCTagSession, data: [UInt8], on page: UInt8) -> Observable<Data> {
        guard session.tags.count == 1 else { return .error(ErrorCode.ConnectNFCError.notSupportMultipleTags) }
        
        guard case .miFare(let tag) = session.tags[0] else { return .error(ErrorCode.ConnectNFCError.notSupportTag) }
        
        guard data.count > 4 else { return .error(ErrorCode.WriteNFCTagError.largeData) }
        
        return .create { (observer) -> Disposable in
            var command = [CommandMifareUltralight.WRITE, page]
            command.append(contentsOf: data)
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

protocol NFCTagWriteService {
    func write(session: NFCTagSession, data: Data) -> Observable<Data>
}

struct DefaultNFCTagWriteService: NFCTagWriteService {
    func write(session: NFCTagSession, data: Data) -> Observable<Data> {
        return .empty()
    }
    
    
}

extension ErrorCode {
    enum WriteNFCTagError: Int, LocalizedError {
        case largeData = 0
        
        var errorDescription: String? {
            switch  self {
            case .largeData: return "Can only write 4 bytes"
            }
        }
    }
}
