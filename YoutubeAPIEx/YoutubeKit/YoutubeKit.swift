//
//  YoutubeKit.swift
//  YoutubeAPIEx
//
//  Created by EnchantCode on 2021/03/20.
//

import Foundation
import UIKit
import WebKit

class YoutubeKit {
    
    // credentials
    let apiCredential: APICredential
    var accessCredential: AccessCredential?
    
    /// Generate Instance.
    /// - Parameters:
    ///    - accessCredential: Credentials of Youtube Data API
    ///    - clientID: Youtube Data API client ID
    init(apiCredential: APICredential, accessCredential: AccessCredential?){
        self.apiCredential = apiCredential
        self.accessCredential = accessCredential
    }
    
    /// Authorize user and generate token.
    ///  - Parameters:
    ///    - presentViewController: viewcontroller that shows authorization screen.
    ///    - scope: scopes that app requires from user
    ///    - success: callback when authorization succeeded.
    ///    - failure: callback when authorization failed.
    func authorize (presentViewController: UIViewController, scope: [YoutubeKit.Scope], success: @escaping (_ credential: YoutubeKit.AccessCredential) -> Void, failure: @escaping (_ error: Error) -> Void){
        
        // Storyboardから認証画面を生成
        let storyboard = UIStoryboard(name: "AuthScreen", bundle: nil)
        guard let navigationController = storyboard.instantiateInitialViewController(),
              let authViewController = navigationController.children.first as? AuthViewController else{
            fatalError("Couldn't instantiate authorize view controller.")
        }
        
        // データを渡して
        authViewController.configure(apiCredential: self.apiCredential, scope: scope) { (credential) in
            self.accessCredential = credential
            success(credential)
        } failure: { (error) in
            failure(error)
        }
        
        // 表示
        presentViewController.present(navigationController, animated: true, completion: nil)
    }
    
    /// こんな関数欲しいね
//    func getAuthenticatedUser() -> YoutubeKit.User{
//
//    }
    
    /// テスト関数 眠い
    public func getPlayList(part: [String], channelID: String, maxResults: Int? = nil){
        // あー無理!
        // URLSession簡単にたたける設計にしてくだしあ 寝る
    }
    
    enum Scope: String, Codable {
        case readwrite = "https://www.googleapis.com/auth/youtube"
        case readonly = "https://www.googleapis.com/auth/youtube.readonly"
        case upload = "https://www.googleapis.com/auth/youtube.upload"
        case audit = "https://www.googleapis.com/auth/youtubepartner-channel-audit"
    }
    
    enum AuthError: Error {
        case denied
        case invalidToken
        case invalidCredential
        case invalidResponse
        case unknown
    }
    
}

// 資格情報s
extension YoutubeKit {
    // API系
    struct APICredential{
        let APIKey: String
        let clientID: String
        let clientSecret: String
    }
    
    // ユーザ系
    struct AccessCredential: Codable{
        var accessToken: String
        var refreshToken: String
        var expires: Date = Date()
        var grantedScopes: [YoutubeKit.Scope] = []

        public func isOutdated() -> Bool{
            return Date() > expires
        }
    }
    
}

// エラーの説明
extension YoutubeKit.AuthError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .denied: return "user denied app to access user data"
        case .invalidCredential: return "invalid internal credentials"
        case .invalidToken: return "invalid access or refresh token"
        case .invalidResponse: return "invalid authorization response"
        default: return "unknown error"
        }
    }
}
