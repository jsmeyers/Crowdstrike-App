//
//  KeychainManager.swift
//  Crowdstrike-App
//
//  Created by scotteberg@gmail.com on 2/22/26.
//

import Foundation
import Security

actor KeychainManager {
    
    static let shared = KeychainManager()
    
    private let service = "com.crowdstrike-app.credentials"
    private let clientIdKey = "clientId"
    private let clientSecretKey = "clientSecret"
    private let bearerTokenKey = "bearerToken"
    
    private init() {}
    
    // MARK: - OAuth Credentials
    
    func storeCredentials(clientId: String, clientSecret: String) throws {
        try store(key: clientIdKey, value: clientId)
        try store(key: clientSecretKey, value: clientSecret)
    }
    
    func retrieveCredentials() throws -> (clientId: String, clientSecret: String)? {
        guard let clientId = retrieve(key: clientIdKey),
              let clientSecret = retrieve(key: clientSecretKey) else {
            return nil
        }
        return (clientId, clientSecret)
    }
    
    func deleteCredentials() throws {
        try delete(key: clientIdKey)
        try delete(key: clientSecretKey)
    }
    
    func hasCredentials() -> Bool {
        guard let _ = retrieve(key: clientIdKey),
              let _ = retrieve(key: clientSecretKey) else {
            return false
        }
        return true
    }
    
    // MARK: - Bearer Token
    
    func storeBearerToken(_ token: String) throws {
        try store(key: bearerTokenKey, value: token)
    }
    
    func retrieveBearerToken() throws -> String? {
        return retrieve(key: bearerTokenKey)
    }
    
    func deleteBearerToken() throws {
        try delete(key: bearerTokenKey)
    }
    
    func hasBearerToken() -> Bool {
        return retrieve(key: bearerTokenKey) != nil
    }
    
    // MARK: - Storage Operations
    
    private func store(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.storeFailed(status)
        }
    }
    
    private func retrieve(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    private func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
    
    // MARK: - Clear All
    
    func clearAll() throws {
        try deleteCredentials()
        try deleteBearerToken()
    }
    
    // MARK: - Check Any Auth
    
    func hasAnyAuthentication() -> Bool {
        return hasCredentials() || hasBearerToken()
    }
}
enum KeychainError: Error, LocalizedError {
    case encodingFailed
    case storeFailed(OSStatus)
    case deleteFailed(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode credentials"
        case .storeFailed(let status):
            return "Failed to store credentials (OSStatus: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete credentials (OSStatus: \(status))"
        }
    }
}

