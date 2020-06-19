//
//  CheckNetwork.swift
//  TestNFC
//
//  Created by jujien on 6/18/20.
//  Copyright © 2020 fitden. All rights reserved.
//

import Foundation
import RxSwift
import CryptoSwift

protocol CheckNetwork {
    func check(uid: String, data: String) -> Observable<CheckBookResult>
    
    func commit(uid: String, data: String) -> Observable<()>
}

struct DefaultCheckNetwork: CheckNetwork {
    func check(uid: String, data: String) -> Observable<CheckBookResult> {
        
        let SECRET_KEY_BYTE: [Int8] = [47, -24, 124, -91, -7, 18, 77, 111, -117, 25, -28, -11, -3, -93, 64, 59, 3, -107, 114, -13, 88, 80, 40, -100, 97, 40, 41, 94, -83, -52, -120, -60]
        let INIT_VECTOR_BYTE: [Int8] = [-25, 109, -58, -75, 120, 122, -39, 104, 87, -44, -85, -51, 70, 65, -69, -30]
        let keyData = Data(bytes: SECRET_KEY_BYTE, count: SECRET_KEY_BYTE.count)
        let ivData = Data(bytes: INIT_VECTOR_BYTE, count: INIT_VECTOR_BYTE.count)
        print(data)
        do {
            let json = try data.decryptBase64ToString(cipher: AES(key: keyData.bytes, blockMode: CBC(iv: ivData.bytes)))
            let jsonDecoder = JSONDecoder()
            var info = try jsonDecoder.decode(DataInfo.self, from: json.data(using: .utf8)!)
            info.timeInterval = "\(Int64(Date().timeIntervalSince1970))"

            let jsonEncoder = JSONEncoder()
            let result = try jsonEncoder.encode(info)
            print(result.string!)
            let encrypt = try result.encrypt(cipher: AES(key: keyData.bytes, blockMode: CBC(iv: ivData.bytes)))
            return Observable<CheckBookResult>.just(.init(status: true, newData: encrypt.base64EncodedString()))
            .delay(.milliseconds(3000), scheduler: MainScheduler.asyncInstance)
        } catch {
            print(error.localizedDescription)
            return Observable<CheckBookResult>.just(.init(status: false, newData: nil))
            .delay(.milliseconds(3000), scheduler: MainScheduler.asyncInstance)
        }
//        return Observable<CheckBookResult>.just(.init(status: true, newData: "UfyhHyrZ3+R6nUy+A2drWE/23zCljI4j8j3S+vMSCfHcbOMmt52ujQ7oABPYW+oYEjQDzByst+r3EpwBuHTXRTDxEe6tcGKE6mYrARP1VTLwyr+LzkZL4ybBzrPIJtLV0Qva4ms2dsyJTs7n1o3m+RY+Kti36dmHuz5t5Ocavg8="))
    }
    
    func commit(uid: String, data: String) -> Observable<()>  {
        return Observable.just(())
        .throttle(RxTimeInterval.milliseconds(5000), scheduler: MainScheduler.asyncInstance)
    }
}

extension DefaultCheckNetwork {
    struct DataInfo: Codable {
        var uid: String
        var editionId: String
        var publisherId: String
        var timeInterval: String
        var copyId: String
    }
}
