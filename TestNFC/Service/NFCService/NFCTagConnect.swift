//
//  NFCTagConnect.swift
//  TestNFC
//
//  Created by jujien on 6/17/20.
//  Copyright © 2020 fitden. All rights reserved.
//

import Foundation
import CoreNFC
import RxSwift
import RxCocoa
//import CombineExt

protocol NFCTagConnect {
    func connect(session: NFCTagSession) -> Observable<NFCTagSession> 
}

struct DefaultNFCTagConnect: NFCTagConnect {
    func connect(session: NFCTagSession) -> Observable<NFCTagSession>  {
        guard session.tags.count == 1 else { return .error(ErrorCode.ConnectNFCError.notSupportMultipleTags) }
        
        return .create { (observer) -> Disposable in
            session.session.connect(to: session.tags[0]) { (error) in
                if let error = error {
                    observer.onError(error)
                } else {
                    observer.onNext(session)
                }
            }
            return Disposables.create { }
        }
    }
}

extension ErrorCode {
    enum ConnectNFCError: Int, LocalizedError {
        case notSupportMultipleTags = 0
        case notSupportTag = 1
        
        var errorDescription: String? {
            switch self {
            case .notSupportMultipleTags: return "Not support connect multiple tags"
            case .notSupportTag: return "Not support tag"
            }
        }
    }
}
