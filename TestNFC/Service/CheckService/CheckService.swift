//
//  CheckService.swift
//  TestNFC
//
//  Created by jujien on 6/18/20.
//  Copyright © 2020 fitden. All rights reserved.
//

import Foundation
import RxSwift
import CoreNFC

protocol CheckService {
    var status: Observable<Bool> { get }
    
    var detectError: Observable<NFCReaderError> { get }
    
    func start(message: String)
}

struct DefaultCheckService: CheckService {
    fileprivate let detect: NFCTagDetectSession
    fileprivate let connect: NFCTagConnect
    fileprivate let authentication: NFCTagAuthentication
    fileprivate let read: NFCTagReadService
    fileprivate let write: NFCTagWriteService
    fileprivate let network: CheckNetwork
    
    fileprivate let disposeBag = DisposeBag()
    
    fileprivate let statusBook: PublishSubject<Bool> = .init()
    
    var status: Observable<Bool> { self.statusBook }
    
    var detectError: Observable<NFCReaderError> { self.detect.error }
    
    init(detect: NFCTagDetectSession, connect: NFCTagConnect, authentication: NFCTagAuthentication, read: NFCTagReadService, write: NFCTagWriteService, network: CheckNetwork) {
        self.detect = detect
        self.connect = connect
        self.authentication = authentication
        self.read = read
        self.write = write
        self.network = network
        
        let data = self.checkData().share()
        
        data.map { $0.result.status }.subscribe(self.statusBook).disposed(by: self.disposeBag)
        self.update(data: data)
    }
    
    func start(message: String) {
        self.detect.begin(pollingOption: [.iso14443, .iso15693], startMessage: message)
    }
    
    fileprivate func checkData() -> Observable<CheckSession> {
        return self.detect.session
            .withLatestFrom(Observable.just(self), resultSelector: { ($0, $1) })
            .flatMap { (session, service) -> Observable<NFCTagSession> in
                return service.connect.connect(session: session)
                    .catchError { (error) -> Observable<NFCTagSession> in
                        session.session.invalidate(errorMessage: "Error")
                        return .empty()
                    }
            }
            .withLatestFrom(Observable.just(self), resultSelector: { ($0, $1) })
            .flatMap { (session, service) -> Observable<NFCTagSession> in
                return service.authentication.authenticate(session: session)
                .catchError { (error) -> Observable<NFCTagSession> in
                    session.session.invalidate(errorMessage: "Error")
                    return .empty()
                }
            }
        .withLatestFrom(Observable.just(self), resultSelector: { ($0, $1) })
        .flatMap { (session, service) -> Observable<CheckSession> in
            guard case .miFare(let tag) = session.tags[0] else { return .empty() }
            return service.read
                .readMessage(session: session, encoding: .ascii)
                .map { (data) -> CheckSession in
                    return .init(session: session, info: .init(uid: tag.identifier.hexEncodedString(), data: data), result: .init(status: false, newData: nil))
                }
                .catchError { (error) -> Observable<CheckSession> in
                    session.session.invalidate(errorMessage: "Error")
                    return .empty()
                }
        }
        .withLatestFrom(Observable.just(self), resultSelector: { ($0, $1) })
        .flatMap { (session, service) -> Observable<CheckSession> in
            return service.network
                .check(uid: session.info.uid, data: session.info.data)
                .map { (result) -> CheckSession in
                    var session = session
                    session.result = result
                    return session
                }
            .do(onError: { (error) in
                session.session.session.invalidate(errorMessage: "Error")
            })
        }
    }
    
    fileprivate func update(data: Observable<CheckSession>) {
        data.filter { $0.result.newData == nil }.subscribe(onNext: { (session) in
            session.session.session.invalidate()
        })
            .disposed(by: self.disposeBag)
        
        data.filter { $0.result.newData != nil }
            .withLatestFrom(Observable.just(self), resultSelector: { ($0, $1) })
            .flatMap { (session, service) -> Observable<CheckSession> in
                return service.write
                    .write(session: session.session, text: session.result.newData!)
                    .map { (_) -> CheckSession in
                        return session
                    }
                .catchError { (error) -> Observable<CheckSession> in
                    session.session.session.alertMessage = "Success"
                    session.session.session.invalidate()
                    return .empty()
                }
            }
        .do(onNext: { (session) in
            session.session.session.alertMessage = "Success"
            session.session.session.invalidate()
        })
        .withLatestFrom(Observable.just(self), resultSelector: { ($0, $1) })
        .flatMap { (session, service) -> Observable<()> in
            return service.network
                .commit(uid: session.info.uid, data: session.result.newData!)
                .catchErrorJustReturn(())
        }
        .subscribe().disposed(by: self.disposeBag)
    }
}

extension DefaultCheckService {
    fileprivate struct CheckSession {
        let session: NFCTagSession
        var info: CheckBookInfo
        var result: CheckBookResult
        
    }
}
