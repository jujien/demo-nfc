//
//  TripleDESService.swift
//  TestNFC
//
//  Created by jujien on 6/17/20.
//  Copyright © 2020 fitden. All rights reserved.
//

import Foundation
import CommonCrypto

protocol TripleDESService {
    func encrypt(data: Data, key: Data, iv: Data) -> Data?
    
    func decrypt(data: Data, key: Data, iv: Data) -> Data?
}

struct DefaultTripleDESService: TripleDESService {
    func encrypt(data: Data, key: Data, iv: Data) -> Data? {
        var myKeyData : Data = key
        let myRawData : Data = data
        let buffer_size : size_t = myRawData.count + kCCBlockSize3DES
        var buffer = [UInt8](repeating: UInt8(0), count: buffer_size)
        var num_bytes_encrypted : size_t = 0

        let operation: CCOperation = UInt32(kCCEncrypt)
        let algoritm:  CCAlgorithm = UInt32(kCCAlgorithm3DES)
        let options:   CCOptions   = 0
        let keyLength        = size_t(kCCKeySize3DES)

        myKeyData = self.fillKey(length: keyLength, key: myKeyData)
        let Crypto_status: CCCryptorStatus = CCCrypt(operation, algoritm, options, (myKeyData as NSData).bytes, keyLength, (iv as NSData).bytes, (myRawData as NSData).bytes, myRawData.count, &buffer, buffer_size, &num_bytes_encrypted)
        if UInt32(Crypto_status) == UInt32(kCCSuccess) {
            let data = Data(bytes: buffer, count: num_bytes_encrypted)
            return data
        } else{
            return nil
        }
    }
    
    func decrypt(data: Data, key: Data, iv: Data) -> Data? {
        let mydata_len : Int = data.count
        var myKeyData : Data = key

        let buffer_size : size_t = mydata_len + kCCBlockSize3DES
        var buffer = [UInt8](repeating: UInt8(0), count: buffer_size)
        var num_bytes_encrypted : size_t = 0

        let operation: CCOperation = UInt32(kCCDecrypt)
        let algoritm:  CCAlgorithm = UInt32(kCCAlgorithm3DES)
        let options:   CCOptions   = UInt32() // default mode cbc
        let keyLength        = size_t(kCCKeySize3DES)


        myKeyData = self.fillKey(length: keyLength, key: myKeyData)
        let decrypt_status : CCCryptorStatus = CCCrypt(operation, algoritm, options, (myKeyData as NSData).bytes, keyLength, (iv as NSData).bytes, (data as NSData).bytes, mydata_len, &buffer, buffer_size, &num_bytes_encrypted)

        if UInt32(decrypt_status) == UInt32(kCCSuccess){
            let data = Data(bytes: buffer, count: num_bytes_encrypted)
            return data
        } else{
            return nil

        }
    }
}

extension DefaultTripleDESService {
    fileprivate func fillKey(length: size_t, key: Data) -> Data {
        let missingBytes = length - key.count
        if missingBytes > 0 {
            let keyBytes = (key as NSData).bytes
            var bytes = [UInt8](repeating: UInt8(0), count: length)
            memccpy(&bytes[0], keyBytes.advanced(by: 0), Int32(key.count), key.count)
            memccpy(&bytes[key.count], keyBytes.advanced(by: 0), Int32(missingBytes), missingBytes)
            return Data(bytes)
        } else {
            return key
        }
    }
}
