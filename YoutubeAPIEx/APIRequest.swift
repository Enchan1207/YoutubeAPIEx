//
//  APIRequest.swift
//  YoutubeAPIEx
//
//  Created by EnchantCode on 2021/03/22.
//

import Foundation
import WebKit

struct RequestConfig {
    let url: URL
    var method: HTTPMethod = .GET
    var requestHeader: [String: String]? = nil
    var requestBody: Data? = nil
    var queryItems: [String: String]? = nil
    
    // configからURLRequestを生成
    func createURLRequest() -> URLRequest {
        var components = URLComponents(url: self.url, resolvingAgainstBaseURL: false)!
        components.queryItems = self.queryItems?.map({URLQueryItem(name: $0.key, value: $0.value)})
        let requestURL = components.url!
        
        var req = URLRequest(url: requestURL)
        req.httpMethod = self.method.rawValue
        req.httpBody = self.requestBody
        self.requestHeader?.forEach({req.setValue($0.value, forHTTPHeaderField: $0.key)})
        
        return req
    }
}

enum HTTPMethod: String {
    case GET
    case POST
    case DELETE
    case PATCH
    case PUT
}
