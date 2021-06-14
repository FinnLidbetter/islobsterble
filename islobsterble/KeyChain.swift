//
//  KeyChain.swift
//  islobsterble
//  Class for accessing the KeyChain service.
//
//  Created by Finn Lidbetter on 2021-06-06.
//  Copyright © 2021 Finn Lidbetter. All rights reserved.
//

import Foundation


class KeyChain {

    class func save(location: String, value: String) -> OSStatus {
        let valueData = value.data(using: .utf8)
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: location,
            kSecValueData as String: valueData as Any]

        let existsQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: location]
        SecItemDelete(existsQuery as CFDictionary)
        
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        
        return addStatus
    }
    
    class func delete(location: String) -> OSStatus {
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: location]
        return SecItemDelete(deleteQuery as CFDictionary)
    }

    class func load(location: String) -> Data? {
        let getQuery: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                       kSecAttrAccount as String: location,
                                       kSecReturnData as String: kCFBooleanTrue!,
                                       kSecMatchLimit as String: kSecMatchLimitOne]

        var dataTypeRef: AnyObject? = nil

        let getStatus: OSStatus = SecItemCopyMatching(getQuery as CFDictionary, &dataTypeRef)
        if getStatus == noErr {
            return dataTypeRef as! Data?
        } else {
            return nil
        }
    }

    class func createUniqueID() -> String {
        let uuid: CFUUID = CFUUIDCreate(nil)
        let cfStr: CFString = CFUUIDCreateString(nil, uuid)

        let swiftString: String = cfStr as String
        return swiftString
    }
}

extension Data {

    init<T>(from value: T) {
        var value = value
        var myData = Data()
        withUnsafePointer(to:&value, { (ptr: UnsafePointer<T>) -> Void in
            myData = Data( buffer: UnsafeBufferPointer(start: ptr, count: 1))
        })
        self.init(myData)
    }

    func to<T>(type: T.Type) -> T {
        return self.withUnsafeBytes { $0.load(as: T.self) }
    }
}
