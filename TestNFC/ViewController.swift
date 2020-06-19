//
//  ViewController.swift
//  TestNFC
//
//  Created by jujien on 5/22/20.
//  Copyright © 2020 fitden. All rights reserved.
//

import UIKit
import CoreNFC
import CommonCrypto
import RxSwift
import RxCocoa
import CryptoSwift
//import CombineExt

let KEY = "qMVsOd8szYWv!HQU"//"BREAKMEIFYOUCAN!"//"BREAKMEIFYOUCAN!"
//let NEW_KEY = "BREAKMEIFYOUCAN!"

class ViewController: UIViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    
    var session: NFCTagReaderSession?
    let service: CheckService = DefaultCheckService(detect: DefaultNFCTagDetectSession(), connect: DefaultNFCTagConnect(), authentication: DefaultNFCTagAuthentication(tripleDESService: DefaultTripleDESService()), read: DefaultNFCTagReadService(readTag: DefaultNFCTagRead()), write: DefaultNFCTagWriteService(writeNFC: DefaultNFCTagWrite()), network: DefaultCheckNetwork())
    
    let disposeBag = DisposeBag()
    
    let data = """
{
    "uid":"04:B4:C7:92:A8:58:80",
    "editionId":"2435955",
    "publisherId":"23697",
    "timeInterval":"1592527548",
    "copyId":"1"
}

"""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let SECRET_KEY_BYTE: [Int8] = [47, -24, 124, -91, -7, 18, 77, 111, -117, 25, -28, -11, -3, -93, 64, 59, 3, -107, 114, -13, 88, 80, 40, -100, 97, 40, 41, 94, -83, -52, -120, -60]
        let INIT_VECTOR_BYTE: [Int8] = [-25, 109, -58, -75, 120, 122, -39, 104, 87, -44, -85, -51, 70, 65, -69, -30]
        let encrypt = "UfyhHyrZ3+R6nUy+A2drWE/23zCljI4j8j3S+vMSCfHcbOMmt52ujQ7oABPYW+oYEjQDzByst+r3EpwBuHTXRTDxEe6tcGKE6mYrARP1VTLwyr+LzkZL4ybBzrPIJtLV0Qva4ms2dsyJTs7n1o3m+RY+Kti36dmHuz5t5Ocavg8="
        print(Data(base64Encoded: encrypt)!.hexEncodedString())
        let keyData = Data(bytes: SECRET_KEY_BYTE, count: SECRET_KEY_BYTE.count)
        let ivData = Data(bytes: INIT_VECTOR_BYTE, count: INIT_VECTOR_BYTE.count)
        let data = Data(base64Encoded: encrypt)!
        if let decrypt = try? data.decrypt(cipher: AES(key: keyData.bytes, blockMode: CBC(iv: ivData.bytes))), let json = decrypt.string {
            print(json)
        }
//        if let decrypt = try? encrypt.decryptBase64(cipher: AES(key: keyData.bytes, blockMode: CBC(iv: ivData.bytes))), let text = try? encrypt.decryptBase64ToString(cipher: AES(key: keyData.bytes, blockMode: CBC(iv: ivData.bytes))) {
//            print(text)
//        }
        
        
        self.service.detectError.filter { $0.code != .readerSessionInvalidationErrorUserCanceled }.subscribe(onNext: { (error) in
            print(error.localizedDescription)
        }).disposed(by: self.disposeBag)
        self.service.status.map { $0 ? "Real book" : "Fake book" }.bind(to: self.statusLabel.rx.text).disposed(by: self.disposeBag)
    }
    
    @IBAction func writeDidTapped(_ sender: Any) {
        self.service.start(message: "Hold your device near a tag to scan it.")
    }

}
