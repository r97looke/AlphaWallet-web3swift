//
//  Promise+HttpProvider.swift
//  web3swift
//
//  Created by Alexander Vlasov on 16.06.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import PromiseKit

extension Web3HttpProvider {
    
    static func post(_ request: JSONRPCrequest, providerURL: URL, queue: DispatchQueue = .main, session: URLSession) -> Promise<JSONRPCresponse> {
        let rp = Promise<Data>.pending()
        var task: URLSessionTask? = nil
        queue.async {
            do {
                let encoder = JSONEncoder()
                let requestData = try encoder.encode(request)
                var urlRequest = try URLRequest(url: providerURL, method: .post)
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
                if let basicAuth = generateBasicAuthCredentialsHeaderValue(fromURL: providerURL) {
                    urlRequest.setValue("Basic \(basicAuth)", forHTTPHeaderField: "Authorization")
                }
                urlRequest.httpBody = requestData
//                let debugValue = try JSONSerialization.jsonObject(with: requestData, options: JSONSerialization.ReadingOptions(rawValue: 0))
//                print(debugValue)
//                let debugString = String(data: requestData, encoding: .utf8)
//                print(debugString)
                task = session.dataTask(with: urlRequest){ (data, response, error) in
                    guard error == nil else {
                        rp.resolver.reject(error!)
                        return
                    }
                    guard data != nil else {
                        rp.resolver.reject(Web3Error.nodeError("Node response is empty"))
                        return
                    }
                    rp.resolver.fulfill(data!)
                }
                task?.resume()
            } catch {
                rp.resolver.reject(error)
            }
        }
        return rp.promise.ensure(on: queue) {
                task = nil
            }.map(on: queue){ (data: Data) throws -> JSONRPCresponse in
                let parsedResponse = try JSONDecoder().decode(JSONRPCresponse.self, from: data)
                if parsedResponse.error != nil {
                    throw Web3Error.nodeError("Received an error message from node\n" + String(describing: parsedResponse.error!))
                }
                return parsedResponse
            }
        }
    
    private static func generateBasicAuthCredentialsHeaderValue(fromURL url: URL) -> String? {
        guard let username = url.user, let password = url.password  else { return nil }
        return "\(username):\(password)".data(using: .utf8)?.base64EncodedString()
    }

    static func post(_ request: JSONRPCrequestBatch, providerURL: URL, queue: DispatchQueue = .main, session: URLSession) -> Promise<JSONRPCresponseBatch> {
        let rp = Promise<Data>.pending()
        var task: URLSessionTask? = nil
        queue.async {
            do {
                let encoder = JSONEncoder()
                let requestData = try encoder.encode(request)
                var urlRequest = try URLRequest(url: providerURL, method: .post)
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
                if let basicAuth = generateBasicAuthCredentialsHeaderValue(fromURL: providerURL) {
                    urlRequest.setValue("Basic \(basicAuth)", forHTTPHeaderField: "Authorization")
                }
                urlRequest.httpBody = requestData
//                let debugValue = try JSONSerialization.jsonObject(with: requestData, options: JSONSerialization.ReadingOptions(rawValue: 0))
//                print(debugValue)
//                let debugString = String(data: requestData, encoding: .utf8)
//                print(debugString)
                task = session.dataTask(with: urlRequest){ (data, response, error) in
                    guard error == nil else {
                        rp.resolver.reject(error!)
                        return
                    }
                    guard data != nil, data!.count != 0 else {
                        rp.resolver.reject(Web3Error.nodeError("Node response is empty"))
                        return
                    }
                    rp.resolver.fulfill(data!)
                }
                task?.resume()
            } catch {
                rp.resolver.reject(error)
            }
        }
        return rp.promise.ensure(on: queue) {
            task = nil
            }.map(on: queue){ (data: Data) throws -> JSONRPCresponseBatch in
//                let debugValue = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0))
//                print(debugValue)
                let parsedResponse = try JSONDecoder().decode(JSONRPCresponseBatch.self, from: data)
                return parsedResponse
        }
    }
}

