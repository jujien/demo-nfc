//
//  CheckNetwork.swift
//  TestNFC
//
//  Created by jujien on 6/18/20.
//  Copyright © 2020 fitden. All rights reserved.
//

import Foundation
import RxSwift

protocol CheckNetwork {
    func check(uid: String, data: String) -> Observable<CheckBookResult>
    
    func commit(uid: String, data: String) -> Observable<()>
}

struct DefaultCheckNetwork: CheckNetwork {
    func check(uid: String, data: String) -> Observable<CheckBookResult> {
        print(data)
        print(uid)
        return Observable<CheckBookResult>.just(.init(status: true, newData: String.randomString(length: 54)))
            .delay(.milliseconds(3000), scheduler: MainScheduler.asyncInstance)
//        return Observable.just(.init(status: false, newData: nil))
//            .throttle(RxTimeInterval.milliseconds(3000), scheduler: MainScheduler.asyncInstance)
    }
    
    func commit(uid: String, data: String) -> Observable<()>  {
        print(uid)
        print(data)
        return Observable.just(())
        .throttle(RxTimeInterval.milliseconds(5000), scheduler: MainScheduler.asyncInstance)
    }
}
