//
//  NFCTagReadService.swift
//  TestNFC
//
//  Created by jujien on 6/18/20.
//  Copyright © 2020 fitden. All rights reserved.
//

import Foundation
import RxSwift

protocol NFCTagRead {
    func read(session: NFCTagSession, start page: UInt8) -> Observable<Data>
}

struct DefaultNFCTagRead: NFCTagRead {
    func read(session: NFCTagSession, start page: UInt8) -> Observable<Data> {
        guard session.tags.count == 1 else { return .error(ErrorCode.ConnectNFCError.notSupportMultipleTags) }
        
        guard case .miFare(let tag) = session.tags[0] else { return .error(ErrorCode.ConnectNFCError.notSupportTag) }
        return .create { (observer) -> Disposable in
            let command = [CommandMifareUltralight.READ, page]
            tag.sendMiFareCommand(commandPacket: command.data) { (data, error) in
                if let error = error {
                    observer.onError(error)
                } else {
                    observer.onNext(data)
                }
            }
            return Disposables.create()
        }
    }
}

protocol NFCTagReadService {
    func read(session: NFCTagSession, start page: UInt8, totalByte: Int) -> Observable<Data>
}

extension NFCTagReadService {
    func readData(session: NFCTagSession) -> Observable<Data> {
        let size = MifareUltralightMemoryOrganization.totalSize()!
        return self.read(session: session, start: MifareUltralightMemoryOrganization.USER_PAGES.first!, totalByte: Int(size))
    }
    
    func readMessage(session: NFCTagSession, encoding: String.Encoding = .ascii) -> Observable<String> {
        self.readData(session: session).compactMap { String(data: $0, encoding: encoding) }
    }
}

struct DefaultNFCTagReadService: NFCTagReadService {
    
    fileprivate let readTag: NFCTagRead
    
    fileprivate var NUMBER_BYTE_PER_ONE_READ: UInt8 { MifareUltralightMemoryOrganization.SIZE_PER_PAGE * self.NUMBER_PAGE_PER_ONE_READ }
    fileprivate let NUMBER_PAGE_PER_ONE_READ: UInt8 = 4
    
    init(readTag: NFCTagRead) {
        self.readTag = readTag
    }
    
    func read(session: NFCTagSession, start page: UInt8, totalByte: Int) -> Observable<Data> {
        guard MifareUltralightMemoryOrganization.containUserPages(of: page) else { return .error(ErrorCode.ReadNFCTagError.notExistPage) }
        guard totalByte != .zero else { return .error(ErrorCode.ReadNFCTagError.notRead) }
        
        let totalByteOfPage = MifareUltralightMemoryOrganization.totalSize(start: page)!
        
        let total = totalByte > totalByteOfPage ? totalByteOfPage : UInt8(totalByte)
        
        var pagesRead: [UInt8] = []
        
        if total <= self.NUMBER_BYTE_PER_ONE_READ {
            pagesRead = [page]
        } else {
            let numberPageRead = (total / self.NUMBER_BYTE_PER_ONE_READ) + (total % self.NUMBER_BYTE_PER_ONE_READ == 0 ? 0 : 1)
            (0..<numberPageRead).forEach { (offset) in
                pagesRead.append(page + offset * self.NUMBER_PAGE_PER_ONE_READ)
            }
        }
        
        return Observable
            .combineLatest(pagesRead.map { self.readTag.read(session: session, start: $0) })
            .map { (data) -> Data in
                guard !data.isEmpty else { return Data() }
                let bigEndianValue = data[0].bytes[0..<4].withUnsafeBufferPointer { $0.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) { $0 } }.pointee
                let value = UInt32(bigEndian: bigEndianValue)
                let result = data.reduce(Data()) { (result, element) -> Data in
                    var r = result
                    r.append(element)
                    return r
                }
                if value < 4 {
                    return result
                } else {
                    return result[4...(value + 3)]
                }
                
            }
    }
}


extension ErrorCode {
    enum ReadNFCTagError: Int, LocalizedError {
        case notExistPage = 0
        case notRead = 1
        
        var localizedDescription: String {
            switch self {
            case .notExistPage: return "Not exist Page"
            case .notRead: return "Not read"
            }
        }
    }
}
