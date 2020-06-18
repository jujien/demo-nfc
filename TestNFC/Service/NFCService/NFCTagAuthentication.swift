//
//  NFCTagAuthentication.swift
//  TestNFC
//
//  Created by jujien on 6/17/20.
//  Copyright © 2020 fitden. All rights reserved.
//

import Foundation
import RxSwift
import CoreNFC

fileprivate let KEY_AUTHENTICATION = "qMVsOd8szYWv!HQU"

protocol NFCTagAuthentication {
    func authenticate(session: NFCTagSession) -> Observable<NFCTagSession> 
}

struct DefaultNFCTagAuthentication {
    fileprivate let tripleDESService: TripleDESService
    
    init(tripleDESService: TripleDESService) {
        self.tripleDESService = tripleDESService
    }
    
    fileprivate func rotateLeft(in data: Data) -> Data {
        var bytes = data.bytes
        let first = bytes.removeFirst()
        bytes.append(first)
        return bytes.data
    }
}

extension DefaultNFCTagAuthentication: NFCTagAuthentication {
    func authenticate(session: NFCTagSession) -> Observable<NFCTagSession> {
        guard session.tags.count == 1 else { return .error(ErrorCode.ConnectNFCError.notSupportMultipleTags) }
        
        guard case .miFare(let tag) = session.tags[0] else { return .error(ErrorCode.ConnectNFCError.notSupportTag) }
        
        return Observable
            .just((tag, session.session))
            .flatMap { (tag, session) -> Observable<AuthenticationSession> in
                return .create { (observer) -> Disposable in
                    let startAuthenticationCommand: [UInt8] = [CommandMifareUltralight.AUTHENTICATE, CommandMifareUltralight.EMPTY]
                    
                    tag.sendMiFareCommand(commandPacket: startAuthenticationCommand.data) { (data, error) in
                        if let error = error {
                            observer.onError(error)
                        } else {
                            observer.onNext(.init(tag: tag, session: session, receiveData: data, command: Data()))
                        }
                    }
                    return Disposables.create()
                }
        }
        .flatMap { (session) -> Observable<AuthenticationSession> in
            var session = session
            if session.receiveData.count == 9 && session.receiveData[0] == CommandMifareUltralight.ACK_AUTHENTICATE {
                session.receiveData = session.receiveData[1..<9]
                return .just(session)
            } else {
                return .error(ErrorCode.AuthenticationNFCError.failed)
            }
        }
        .withLatestFrom(Observable.just(self), resultSelector: { ($0, $1) })
        .flatMap { (session, service) -> Observable<AuthenticationSession> in
            var session = session

            guard let randomB = service.tripleDESService.decrypt(data: session.receiveData, key: KEY_AUTHENTICATION.data(using: .utf8)!, iv: session.iv), let randomA = Data.random(count: 8) else { return .error(ErrorCode.AuthenticationNFCError.failed) }
            
            session.iv = session.receiveData
            
            let randomBRotate = service.rotateLeft(in: randomB)
            let newData = randomA + randomBRotate
            
            guard let encrypt = self.tripleDESService.encrypt(data: newData, key: KEY_AUTHENTICATION.data(using: .utf8)!, iv: session.iv) else { return .error(ErrorCode.AuthenticationNFCError.failed) }
            
            var command: [UInt8] = [CommandMifareUltralight.ACK_AUTHENTICATE]
            command.append(contentsOf: encrypt)
            
            session.randomA = randomA
            session.receiveData = Data()
            session.command = command.data
            session.iv = encrypt[8..<16]
            return .just(session)
        }
        .flatMap { (session) -> Observable<AuthenticationSession> in
            return .create { (observer) -> Disposable in
                session.tag.sendMiFareCommand(commandPacket: session.command) { (data, error) in
                    if let error = error {
                        observer.onError(error)
                    } else {
                        var session = session
                        session.receiveData = data
                        session.command = Data()
                        observer.onNext(session)
                    }
                }
                return Disposables.create()
            }
        }
        .flatMap { (session) -> Observable<AuthenticationSession> in
            if session.receiveData.count == 9 && session.receiveData[0] == CommandMifareUltralight.END_AUTHENTICATE {
                var session = session
                session.receiveData = session.receiveData[1..<9]
                return .just(session)
            } else {
                return .error(ErrorCode.AuthenticationNFCError.failed)
            }
        }
        .withLatestFrom(Observable.just(self), resultSelector: { ($0, $1)})
        .flatMap { (session, service) -> Observable<NFCTagSession> in
            guard let decrypt = service.tripleDESService.decrypt(data: session.receiveData, key: KEY_AUTHENTICATION.data(using: .utf8)!, iv: session.iv) else { return .error(ErrorCode.AuthenticationNFCError.failed) }
            if service.rotateLeft(in: session.randomA) == decrypt {
                return .just(.init(tags: [NFCTag.miFare(session.tag)], session: session.session))
            } else {
                return .error(ErrorCode.AuthenticationNFCError.failed)
            }
        }
    }
}

extension DefaultNFCTagAuthentication {
    fileprivate struct AuthenticationSession {
        let tag: NFCMiFareTag
        let session: NFCTagReaderSession
        var receiveData: Data
        var randomA: Data = Data()
        var iv: Data = .init(count: 8)
        var command: Data
    }
}

extension ErrorCode {
    enum AuthenticationNFCError: Int, LocalizedError {
        case failed = 0
        
        var errorDescription: String? {
            switch self {
            case .failed: return "Authenticate failed"
            }
        }
    }
}
