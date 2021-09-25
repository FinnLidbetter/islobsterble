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
    
    func renewedRequest(successCompletion: @escaping ((Token) -> Void), errorCompletion: @escaping ((RenewedRequestError) -> Void)) -> Void {
        if !self.isExpired() {
            successCompletion(self.token!)
            return
        }
        guard let receivedData = KeyChain.load(location: REFRESH_TAG) else {
            errorCompletion(RenewedRequestError.keyChainRetrieveError)
            return
        }
        let refreshTokenString = String(decoding: receivedData, as: UTF8.self)
        let refreshToken = Token(keyChainString: refreshTokenString)
        
        guard let url = URL(string: ROOT_URL + "api/refresh-access") else {
            errorCompletion(RenewedRequestError.urlError)
            return
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addAuthorization(token: refreshToken)
        request.httpMethod = "POST"
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .secondsSince1970
                    if let token = try? decoder.decode(Token.self, from: data) {
                        DispatchQueue.main.async {
                            self.token = token
                        }
                        let _ = print("Successfully retrieved new token")
                        successCompletion(token)
                    } else {
                        errorCompletion(RenewedRequestError.decodeError)
                    }
                } else {
                    let _ = print("Non 200 renew access response")
                    errorCompletion(RenewedRequestError.renewAccessError(response))
                }
            } else {
                let _ = print("Error in renew access url session")
                errorCompletion(RenewedRequestError.urlSessionError(error!))
            }
        }.resume()
    }
}

enum RenewedRequestError {
    case keyChainRetrieveError, urlError, decodeError, renewAccessError(HTTPURLResponse), urlSessionError(Error)
}

extension URLRequest {
    mutating func addAuthorization(token: Token) {
        self.setValue(token.toHttpHeaderString(), forHTTPHeaderField: "Authorization")
    }
}

extension Data {
    var prettyPrintedJSONString: NSString? { /// NSString gives us a nice sanitized debugDescription
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }

        return prettyPrintedString
    }
}

let tokenSeparator: Character = "@"

struct Token: Codable {
    let token: String
    let expiration_date: Date
    
    init(token: String, expiration_date: Date) {
        self.token = token
        self.expiration_date = expiration_date
    }

    init(keyChainString: String) {
        let parts = keyChainString.split(separator: tokenSeparator)
        self.token = String(parts[0])
        self.expiration_date = Date(timeIntervalSince1970: Double(String(parts[1]))!)
    }
    
    func toKeyChainString() -> String {
        return self.token + String(tokenSeparator) + String(Int(self.expiration_date.timeIntervalSince1970))
    }
    func toHttpHeaderString() -> String {
        return "Bearer " + self.token
    }
    func isExpired() -> Bool {
        let now = Date()
        return now.addingTimeInterval(renewAccessBufferTime) > self.expiration_date
    }
}

struct TokenPair: Decodable {
    let access_token: Token
    let refresh_token: Token
}
