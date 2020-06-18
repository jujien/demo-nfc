//
//  NFCTagWriteService.swift
//  TestNFC
//
//  Created by jujien on 6/18/20.
//  Copyright © 2020 fitden. All rights reserved.
//

import Foundation
import RxSwift

protocol NFCTagWrite {
    func write(session: NFCTagSession, data: [UInt8], on page: UInt8) -> Observable<Data>
}

struct DefaultNFCTagWrite: NFCTagWrite {
    func write(session: NFCTagSession, data: [UInt8], on page: UInt8) -> Observable<Data> {
        guard session.tags.count == 1 else { return .error(ErrorCode.ConnectNFCError.notSupportMultipleTags) }
        
        guard case .miFare(let tag) = session.tags[0] else { return .error(ErrorCode.ConnectNFCError.notSupportTag) }
        
        guard data.count <= MifareUltralightMemoryOrganization.SIZE_PER_PAGE else { return .error(ErrorCode.WriteNFCTagError.largeDataOnPage) }
        
        return .create { (observer) -> Disposable in
            var command = [CommandMifareUltralight.WRITE, page]
            command.append(contentsOf: data)
            print(command.hexEncodedString())
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

protocol NFCTagWriteService {
    func write(session: NFCTagSession, data: Data, start page: UInt8) -> Observable<Data>
}

extension NFCTagWriteService {
    func write(session: NFCTagSession, data: Data) -> Observable<Data> {
        self.write(session: session, data: data, start: MifareUltralightMemoryOrganization.USER_PAGES[0])
    }
    
    func empty(session: NFCTagSession) -> Observable<Data> {
        let emptyData = Data(count: Int(MifareUltralightMemoryOrganization.totalSize()!))
        return self.write(session: session, data: emptyData)
    }
    
    func write(session: NFCTagSession, text: String, encoding: String.Encoding = .ascii) -> Observable<Data> {
        guard let data = text.data(using: encoding) else { return .empty() }
        return self.write(session: session, data: data)
    }
}

struct DefaultNFCTagWriteService: NFCTagWriteService {
    
    fileprivate let writeTag: NFCTagWrite
    
    init(writeNFC: NFCTagWrite) {
        self.writeTag = writeNFC
    }
    
    func write(session: NFCTagSession, data: Data, start page: UInt8) -> Observable<Data> {
        guard MifareUltralightMemoryOrganization.containUserPages(of: page) else { return .error(ErrorCode.WriteNFCTagError.notExistPage) }
        
        guard MifareUltralightMemoryOrganization.enoughMemory(data: data, page: page) else { return .error(ErrorCode.WriteNFCTagError.notEnoughMemory) }
                
        let index = MifareUltralightMemoryOrganization.USER_PAGES.firstIndex(of: page)!
        
        let items = self.pages(bytes: data.bytes)
        let pages = MifareUltralightMemoryOrganization.USER_PAGES[index..<items.count]
        
        let observables = zip(items, pages).map { (item, page) -> Observable<Data> in
            return self.writeTag.write(session: session, data: item, on: page)
        }
        return Observable.combineLatest(observables)
            .flatMap { (data) -> Observable<Data> in
                let ack = data.filter { $0.count == 1 && $0[0] == CommandMifareUltralight.ACK_WRITE }
                if ack.count == data.count {
                    return .just(data[0])
                } else {
                    return .error(ErrorCode.WriteNFCTagError.writeFailed)
                }
        }
    }
    
    
}

extension DefaultNFCTagWriteService {
    fileprivate func fillEmptyByteInPage(bytes: [UInt8]) -> [UInt8] {
        guard bytes.count < MifareUltralightMemoryOrganization.SIZE_PER_PAGE else { return bytes }
        var bytes = bytes
        let totalMissingBytes = MifareUltralightMemoryOrganization.SIZE_PER_PAGE - UInt8(bytes.count)
        (0..<totalMissingBytes).forEach { (_) in
            bytes.append(.zero)
        }
        return bytes
    }
    
    fileprivate func splitBytesToPage(bytes: [UInt8], totalPage: UInt8) -> [[UInt8]] {
        var items: [[UInt8]] = []
        (0..<totalPage).enumerated().forEach { (offset, element) in
            let start = offset * Int(MifareUltralightMemoryOrganization.SIZE_PER_PAGE)
            let end = (offset + 1) * Int(MifareUltralightMemoryOrganization.SIZE_PER_PAGE)
            items.append(bytes[start..<end].map { $0 })
        }
        return items
    }
    
    fileprivate func pages(bytes: [UInt8]) -> [[UInt8]] {
        var items: [[UInt8]] = []
        if bytes.count < MifareUltralightMemoryOrganization.SIZE_PER_PAGE {
            items = [self.fillEmptyByteInPage(bytes: bytes)]
        } else {
            let totalPage = UInt8(bytes.count) / MifareUltralightMemoryOrganization.SIZE_PER_PAGE
            if UInt8(bytes.count) % MifareUltralightMemoryOrganization.SIZE_PER_PAGE == 0 {
                items = self.splitBytesToPage(bytes: bytes, totalPage: totalPage)
            } else {
                items = self.splitBytesToPage(bytes: bytes, totalPage: totalPage)
                var bytesInLastPage = bytes[Int(totalPage * MifareUltralightMemoryOrganization.SIZE_PER_PAGE)..<bytes.count].map { $0 }
                bytesInLastPage = self.fillEmptyByteInPage(bytes: bytesInLastPage)
                items.append(bytesInLastPage)
            }
        }
        return items
    }
}

extension ErrorCode {
    enum WriteNFCTagError: Int, LocalizedError {
        case largeDataOnPage = 0
        case notExistPage = 1
        case notEnoughMemory = 2
        case writeFailed = 3
        
        var errorDescription: String? {
            switch  self {
            case .largeDataOnPage: return "Can only write 4 bytes per page"
            case .notExistPage: return "Not exist page"
            case .notEnoughMemory: return "Not enough memory"
            case .writeFailed: return "Write Failed"
            }
        }
    }
}
