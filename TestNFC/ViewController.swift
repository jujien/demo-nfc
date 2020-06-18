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
    
//    var session: NFCNDEFReaderSession?
    
    var session: NFCTagReaderSession?
//    let newKey: String = String.randomString(length: 16)
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        print(self.newKey)
//        print(self.newKey.data(using: .ascii)?.hexEncodedString())
//        let observable = Observable.combineLatest(self.detect.session, self.action)
//            .filter { $0.1 != .none }
//            .withLatestFrom(Observable.just(self), resultSelector: { ($0, $1) })
//            .flatMap { (tuple, vc) -> Observable<(NFCTagSession, Action)> in
//                return vc.connect.connect(session: tuple.0)
//                    .map { ($0, tuple.1) }
//            }
//            .withLatestFrom(Observable.just(self), resultSelector: { ($0, $1) })
//            .flatMap { (tuple, vc) -> Observable<(NFCTagSession, Action)> in
//            return vc.authentication.authenticate(session: tuple.0)
//                .map { ($0, tuple.1) }
//            }
//        .catchError({ (error) -> Observable<(NFCTagSession, Action)> in
//            self.detect.end(error: error.localizedDescription)
//            return .empty()
//        })
//        .debug()
//            .share()
//        observable.filter { $0.1 == .read }.map { $0.0 }
//            .withLatestFrom(Observable.just(self), resultSelector: { ($0, $1) })
//            .flatMap { (session, vc) -> Observable<String> in
//                return vc.read.readMessage(session: session, encoding: .utf8)
//                    .catchError { (error) -> Observable<String> in
//                        session.session.invalidate(errorMessage: error.localizedDescription)
//                        return .empty()
//                    }
//            }
//    .debug()
//        .subscribe(onNext: { (message) in
//            print(message)
//            self.detect.end()
//        })
//            .disposed(by: self.disposeBag)
//
//        observable.filter { $0.1 == .writeEmpty }.map { $0.0 }
//            .withLatestFrom(Observable.just(self), resultSelector: { ($0, $1) })
//            .flatMap { (session, vc) -> Observable<Data> in
//                return vc.write.empty(session: session)
//                    .catchError { (error) -> Observable<Data> in
//                        session.session.invalidate(errorMessage: error.localizedDescription)
//                        return .empty()
//                }
//            }
//        .subscribe(onNext: { (data) in
//            print(data.hexEncodedString())
//            self.detect.end()
//        })
//            .disposed(by: self.disposeBag)
//
//        observable.filter { $0.1 == .write }.map { $0.0 }
//            .withLatestFrom(Observable.just(self), resultSelector: { ($0, $1) })
//            .flatMap { (session, vc) -> Observable<Data> in
//                let text = "Hello, world! This is mifare ultralight c"
//                return vc.write.write(session: session, text: text, encoding: .utf8)
//                    .catchError { (error) -> Observable<Data> in
//                        session.session.invalidate(errorMessage: error.localizedDescription)
//                        return .empty()
//                }
//        }
//        .subscribe(onNext: { (data) in
//            print(data.hexEncodedString())
//            self.detect.end()
//        })
//            .disposed(by: self.disposeBag)
    }
    
    @IBAction func writeDidTapped(_ sender: Any) {
//        self.action.accept(.write)
//        self.detect.begin(pollingOption: [.iso14443, .iso15693], startMessage: "Hold your device near a tag to scan it.")
    }
    
    //        @IBAction func startDidTapped(_ sender: Any) {
    //        guard NFCReaderSession.readingAvailable else {
    //            return
    //        }
    //        self.session = NFCTagReaderSession(pollingOption: [.iso14443, .iso15693], delegate: self, queue: nil)
    //        self.session?.alertMessage = "Hold your device near a tag to scan it."
    //        self.session?.begin()
    //    }
    
    func fillKey(keyLength: size_t, key: Data) -> Data {
        let missingBytes = keyLength - key.count
        if missingBytes > 0 {
            let keyBytes = (key as NSData).bytes
            var bytes = [UInt8](repeating: UInt8(0), count: keyLength)
            memccpy(&bytes[0], keyBytes.advanced(by: 0), Int32(key.count), key.count)
            memccpy(&bytes[key.count], keyBytes.advanced(by: 0), Int32(missingBytes), missingBytes)
            return Data(bytes)
        } else {
            return key
        }
    }
    
    func my3DESEncrypt(encryptData: Data, key: Data, iv: Data) -> Data? {
        var myKeyData : Data = key
        let myRawData : Data = encryptData
        let buffer_size : size_t = myRawData.count + kCCBlockSize3DES
        var buffer = [UInt8](repeating: UInt8(0), count: buffer_size)
        var num_bytes_encrypted : size_t = 0

        let operation: CCOperation = UInt32(kCCEncrypt)
        let algoritm:  CCAlgorithm = UInt32(kCCAlgorithm3DES)
        let options:   CCOptions   = 0
        let keyLength        = size_t(kCCKeySize3DES)

        myKeyData = self.fillKey(keyLength: keyLength, key: myKeyData)
        let Crypto_status: CCCryptorStatus = CCCrypt(operation, algoritm, options, (myKeyData as NSData).bytes, keyLength, (iv as NSData).bytes, (myRawData as NSData).bytes, myRawData.count, &buffer, buffer_size, &num_bytes_encrypted)
        if UInt32(Crypto_status) == UInt32(kCCSuccess) {
            let data = Data(bytes: buffer, count: num_bytes_encrypted)
            return data
        } else{
            return nil
        }
    }
    
    func my3DESDecrypt(decryptData : Data, key: Data, iv: Data) -> Data? {
        let mydata_len : Int = decryptData.count
        var myKeyData : Data = key

        let buffer_size : size_t = mydata_len+kCCBlockSize3DES
        var buffer = [UInt8](repeating: UInt8(0), count: buffer_size)
        var num_bytes_encrypted : size_t = 0

        let operation: CCOperation = UInt32(kCCDecrypt)
        let algoritm:  CCAlgorithm = UInt32(kCCAlgorithm3DES)
        let options:   CCOptions   = UInt32()//UInt32(kCCOptionPKCS7Padding)
        let keyLength        = size_t(kCCKeySize3DES)


        myKeyData = self.fillKey(keyLength: keyLength, key: myKeyData)
        let decrypt_status : CCCryptorStatus = CCCrypt(operation, algoritm, options, (myKeyData as NSData).bytes, keyLength, (iv as NSData).bytes, (decryptData as NSData).bytes, mydata_len, &buffer, buffer_size, &num_bytes_encrypted)

        if UInt32(decrypt_status) == UInt32(kCCSuccess){
            let data = Data(bytes: buffer, count: num_bytes_encrypted)
            return data
        } else{
            return nil

        }
    }
    
    func rotateLeft(in data: Data) -> Data {
        var bytes = data.bytes
        let first = bytes.removeFirst()
        bytes.append(first)
        return bytes.data
    }
}

extension ViewController: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        print("SessionDidBecomeActive")
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        print(error.localizedDescription)
        UITableView().rx.itemSelected
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "Can not write to more than one tag.")
            return
        }
        session.connect(to: tag) { (error) in
            guard error == nil else {
                session.invalidate(errorMessage: "Not connect")
                return
            }
            guard case .miFare(let mifareTag) = tag else {
                session.invalidate(errorMessage: "Not support nfc tag")
                return
            }
            let bytes: [UInt8] = [0x1A, 0x00]
            mifareTag.sendMiFareCommand(commandPacket: bytes.data) { (data, error) in
                if let error = error {
                    print(error.localizedDescription)
                    session.invalidate(errorMessage: "Error")
                } else {
                    guard data.count == 9 && data[0] == 0xAF else {
                        session.invalidate(errorMessage: "Authentication failed")
                        return
                    }
                    guard let randomB = self.my3DESDecrypt(decryptData: data[1...8], key: KEY.data(using: .utf8)!, iv: Data(count: 0)), let randomA = Data.random(count: 8) else {
                        session.invalidate(errorMessage: "Authentication failed")
                        return
                    }
                    let randomBRotate = self.rotateLeft(in: randomB)
                    let newData = randomA + randomBRotate
                    guard let encrypt = self.my3DESEncrypt(encryptData: newData, key: KEY.data(using: .utf8)!, iv: data[1...8]) else {
                        session.invalidate(errorMessage: "Authentication failed")
                        return
                    }
                    let command = Data([0xaf]) + encrypt
                    mifareTag.sendMiFareCommand(commandPacket: command) { (data1, error) in
                        if let error = error {
                            print(error.localizedDescription)
                            session.invalidate(errorMessage: "Authentication failed")
                        } else {
                            guard data1.count == 9 && data1[0] == 0x00 else {
                                session.invalidate(errorMessage: "Authentication failed")
                                return
                            }
                            guard let decrypt = self.my3DESDecrypt(decryptData: data1[1...8], key: KEY.data(using: .utf8)!, iv: encrypt[8...15]) else {
                                session.invalidate(errorMessage: "Authentication failed")
                                return
                            }
                            if self.rotateLeft(in: randomA) == decrypt {
                                
//                                mifareTag.sendMiFareCommand(commandPacket: Data([0x30, 0x03])) { (data, error) in
//                                    if let error = error {
//                                        print("error: \(error.localizedDescription)")
//                                        session.invalidate(errorMessage: "Not read")
//                                    } else {
//                                        let text = "HILL"
//                                        print(text.data(using: .ascii)!.hexEncodedString())
//                                        print(data.hexEncodedString())
//                                        session.alertMessage = "Read success"
//                                        session.invalidate()
//                                    }
//                                }
//
                                let text = "HILL"
                                var write: [UInt8] = [0xa2, 0x04]
                                write.append(contentsOf: text.data(using: .ascii)!.bytes)
                                let commandData = write.data
                                print(commandData.hexEncodedString())
                                mifareTag.sendMiFareCommand(commandPacket: commandData) { (data, error) in
                                    if let error = error {
                                        print("error: \(error.localizedDescription)")
                                        session.invalidate(errorMessage: "Not write")
                                    } else {
                                        print(data.hexEncodedString())
                                        session.alertMessage = "Write Success"
                                        session.invalidate()
                                    }
                                }
/*
                                // Set new key
                                let keyData = self.newKey.data(using: .ascii)!.bytes
                                let key1Data = keyData[0..<8].map { $0 }
                                let key2Data = keyData[8..<16].map { $0 }
                                var write1: [UInt8] = [0xa2, 0x2c]
                                write1.append(contentsOf: key1Data[4..<8].reversed())
                                print(write1.data.hexEncodedString())
                                mifareTag.sendMiFareCommand(commandPacket: write1.data) { (data, error) in
                                    if let error = error {
                                        print("error1: \(error.localizedDescription)")
                                        session.invalidate(errorMessage: "Not write 1")
                                    } else {
                                        print(data.hexEncodedString())
                                        var write2: [UInt8] = [0xa2, 0x2d]
                                        write2.append(contentsOf: key1Data[0..<4].reversed())
                                        mifareTag.sendMiFareCommand(commandPacket: write2.data) { (data, error) in
                                            if let error = error {
                                                print("error2: \(error.localizedDescription)")
                                                session.invalidate(errorMessage: "Not write 2")
                                            } else {
                                                print(data.hexEncodedString())
                                                var write3: [UInt8] = [0xa2, 0x2e]
                                                write3.append(contentsOf: key2Data[4..<8].reversed())
                                                mifareTag.sendMiFareCommand(commandPacket: write3.data) { (data, error) in
                                                    if let error = error {
                                                        print("error3: \(error.localizedDescription)")
                                                        session.invalidate(errorMessage: "Not write 3")
                                                    } else {
                                                        print(data.hexEncodedString())
                                                        var write4: [UInt8] = [0xa2, 0x2f]
                                                        write4.append(contentsOf: key2Data[0..<4].reversed())
                                                        mifareTag.sendMiFareCommand(commandPacket: write4.data) { (data, error) in
                                                            if let error = error {
                                                                print("error4: \(error.localizedDescription)")
                                                                session.invalidate(errorMessage: "Not write 4")
                                                            } else {
                                                                print(data.hexEncodedString())
                                                                session.alertMessage = "Write new key success"
                                                                session.invalidate()
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
*/
                            } else {
                                session.invalidate(errorMessage: "Authentication failed")
                            }

                        }
                    }
                }
            }
        }
    }
}

