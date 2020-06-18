//
//  NFCTagConnectSession.swift
//  TestNFC
//
//  Created by jujien on 6/17/20.
//  Copyright © 2020 fitden. All rights reserved.
//

import Foundation
import RxSwift
//import CombineExt
import CoreNFC
import RxCocoa

protocol NFCTagDetectSession {
    var session: Observable<NFCTagSession> { get }
    
    var active: Observable<()> { get }
    
    func begin(pollingOption: NFCTagReaderSession.PollingOption, startMessage: String)
    
    func end()
    
    func end(error: String)
}

class DefaultNFCTagDetectSession: NSObject {
    fileprivate var didActive: PublishSubject<()> = .init()
    fileprivate let _session = PublishSubject<NFCTagSession>()
    fileprivate var readerSession: NFCReaderSession?
    
    override init() {
        super.init()
        
    }
}

extension DefaultNFCTagDetectSession: NFCTagDetectSession {
    var session: Observable<NFCTagSession> { self._session.asObservable() }

    var active: Observable<()> { self.didActive.asObservable() }

    func begin(pollingOption: NFCTagReaderSession.PollingOption, startMessage: String) {
        self.readerSession = NFCTagReaderSession(pollingOption: pollingOption, delegate: self)
        self.readerSession?.alertMessage = startMessage
        self.readerSession?.begin()
    }
    
    func end() {
        self.readerSession?.invalidate()
        self.readerSession = nil
    }
    
    func end(error: String) {
        self.readerSession?.invalidate(errorMessage: error)
        self.readerSession = nil 
    }
}

extension DefaultNFCTagDetectSession: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        self.didActive.onNext(())
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        self._session.onError(error)
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        print("Detected")
        self._session.onNext(.init(tags: tags, session: session))
    }


}


