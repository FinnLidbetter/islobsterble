//
//  Token.swift
//  islobsterble
//  Object to store a token and its expiration date.
//
//  Created by Finn Lidbetter on 2021-05-30.
//  Copyright © 2021 Finn Lidbetter. All rights reserved.
//

import Foundation

let renewAccessBufferTime = TimeInterval(60)
let REFRESH_TAG = "slobsterble.refresh"


class ManagedAccessToken: ObservableObject {
    @Published var token: Token? = nil
    
    func isExpired() -> Bool {
        // Return True iff the token is expired or will expire within the buffer time.
        if self.token == nil {
            return true
        }
        let now = Date()
        return now.addingTimeInterval(renewAccessBufferTime) > self.token!.expiration_date
    }
    
    func renew() -> (Bool, String) {
        guard let receivedData = KeyChain.load(location: REFRESH_TAG) else {
            return (false, "Could not retrieve refresh token from keychain")
        }
        let refreshTokenString = String(decoding: receivedData, as: UTF8.self)
        let refreshToken = Token(keyChainString: refreshTokenString)
        
        guard let url = URL(string: ROOT_URL + "refresh-access") else {
            return (false, "Bad URL")
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(refreshToken.toHttpHeaderString(), forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        var success = false
        var resultString = ""
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .secondsSince1970
                    if let token = try? decoder.decode(Token.self, from: data) {
                        self.token = token
                        success = true
                        resultString = "Success"
                    }
                } else {
                    resultString = String(decoding: data, as: UTF8.self)
                }
            } else {
                resultString = "Could not connect to the server."
            }
        }.resume()
        return (success, resultString)
    }
}

let tokenSeparator: Character = "@"

struct Token: Codable {
    let certificate: String
    let expiration_date: Date
    
    init(certificate: String, expiration_date: Date) {
        self.certificate = certificate
        self.expiration_date = expiration_date
    }

    init(keyChainString: String) {
        let parts = keyChainString.split(separator: tokenSeparator)
        self.certificate = String(parts[0])
        self.expiration_date = Date(timeIntervalSince1970: Double(String(parts[1]))!)
    }
    
    func toKeyChainString() -> String {
        return self.certificate + String(tokenSeparator) + String(Int(self.expiration_date.timeIntervalSince1970))
    }
    func toHttpHeaderString() -> String {
        return "Bearer " + self.certificate
    }
}

struct TokenPair: Decodable {
    let access_token: Token
    let refresh_token: Token
}
