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
//import CombineExt

let KEY = "qMVsOd8szYWv!HQU"//"BREAKMEIFYOUCAN!"//"BREAKMEIFYOUCAN!"
//let NEW_KEY = "BREAKMEIFYOUCAN!"

class ViewController: UIViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    
    var session: NFCTagReaderSession?
    let service: CheckService = DefaultCheckService(detect: DefaultNFCTagDetectSession(), connect: DefaultNFCTagConnect(), authentication: DefaultNFCTagAuthentication(tripleDESService: DefaultTripleDESService()), read: DefaultNFCTagReadService(readTag: DefaultNFCTagRead()), write: DefaultNFCTagWriteService(writeNFC: DefaultNFCTagWrite()), network: DefaultCheckNetwork())
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.service.detectError.filter { $0.code != .readerSessionInvalidationErrorUserCanceled }.subscribe(onNext: { (error) in
            print(error.localizedDescription)
        }).disposed(by: self.disposeBag)
        self.service.status.map { $0 ? "Real book" : "Fake book" }.bind(to: self.statusLabel.rx.text).disposed(by: self.disposeBag)
    }
    
    @IBAction func writeDidTapped(_ sender: Any) {
        self.service.start(message: "Hold your device near a tag to scan it.")
    }

}
