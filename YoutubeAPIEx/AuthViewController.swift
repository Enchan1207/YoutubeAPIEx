//
//  AuthViewController.swift
//  YoutubeAPIEx
//
//  Created by EnchantCode on 2021/03/19.
//

import UIKit
import WebKit

class AuthViewController: UIViewController {
    
    // credentials
    internal var apiCredential: YoutubeKit.APICredential? = nil
    internal var scope: [YoutubeKit.Scope] = []
    
    // callback
    internal var successCallback: ((_ credential: YoutubeKit.AccessCredential) -> Void)?
    internal var failureCallback: ((_ error: YoutubeKit.AuthError) -> Void)?
    
    // consts
    internal let authEndPointString = "https://accounts.google.com/o/oauth2/auth"
    
    // webview
    internal var isLoaded: Bool = false
    internal var estimatedProgressObservationToken: NSKeyValueObservation?
    internal var navigationGoBackObservationToken: NSKeyValueObservation?
    internal var navigationGoForwardObservationToken: NSKeyValueObservation?
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var webProgressBar: UIProgressView!
    @IBOutlet weak var navigationBackButton: UIBarButtonItem!
    @IBOutlet weak var navigationForwardButton: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // webview初期化
        webView.customUserAgent = "Mozilla/5.0 (iPhone; iPhone like Mac OS X) AppleWebKit (KHTML, like Gecko) Safari"
        webView.navigationDelegate = self
        self.estimatedProgressObservationToken = webView.observe(\.estimatedProgress) { (webView, change) in
            // プログレスバー更新
            let progress = webView.estimatedProgress
            self.webProgressBar.alpha = 1
            self.webProgressBar.setProgress(Float(progress), animated: true)
        }
        
        self.navigationGoBackObservationToken = webView.observe(\.canGoBack) { (object, change) in
            self.navigationBackButton.isEnabled = self.webView.canGoBack
        }
        
        self.navigationGoForwardObservationToken = webView.observe(\.canGoForward) { (object, change) in
            self.navigationBackButton.isEnabled = self.webView.canGoForward
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // 認証URLを生成して読み込み開始
        if(!self.isLoaded){
            guard let authURL = generateAuthURL() else{
                fatalError("Couldn't generate authorization url from passed credentials!")
            }
            webView.load(URLRequest(url: authURL))
            self.isLoaded = true
        }
    }
    
    /// Inject credentials from other class.
    /// - Parameters:
    ///   - apiKey: Youtube Data API Key
    ///   - clientID: Youtube Data API client ID
    ///   - clientSecret: Youtube Data API client secret
    ///   - scope: scopes that app requires from user
    ///   - success: callback when authorize succeeded.
    ///   - failure: callback when authorize failed.
    public func configure(apiCredential: YoutubeKit.APICredential, scope: [YoutubeKit.Scope], success: @escaping (_ credential: YoutubeKit.AccessCredential) -> Void, failure: @escaping (_ error: YoutubeKit.AuthError) -> Void){
        self.apiCredential = apiCredential
        self.scope = scope
        
        self.successCallback = success
        self.failureCallback = failure
        
        
    }
    
    /// Make URL of authorization page from passed credentials.
    private func generateAuthURL() -> URL?{
        
        guard var components = URLComponents(string: authEndPointString) else {fatalError("Invalid authorization endpoint url")}
        
        let param = [
            "key": self.apiCredential!.APIKey,
            "client_id": self.apiCredential!.clientID,
            "redirect_uri": "urn:ietf:wg:oauth:2.0:oob",
            "response_type": "code",
            "scope": self.scope.map({$0.rawValue}).joined(separator: " "),
            "access_type": "offline"
        ]
        
        components.queryItems = param.map({URLQueryItem(name: $0.key, value: $0.value)})
        return components.url
    }
    
    @IBAction func onTapBackButton(_ sender: UIBarButtonItem) {
        self.webView.goBack()
    }
    
    @IBAction func onTapForwardButton(_ sender: UIBarButtonItem) {
        self.webView.goForward()
    }
    
    @IBAction func onTapCloseButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension AuthViewController: WKNavigationDelegate{
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        self.title = webView.url?.host
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        // プログレスバーを消す
        UIView.animate(withDuration: 0.5) {
            self.webProgressBar.alpha = 0
        } completion: { (finished) in
            self.webProgressBar.setProgress(0, animated: true)
        }
        
        // (ユーザがアクセスを承認/拒否するとこのURLに飛ぶ)
        guard let destination = self.webView.url,
              destination.absoluteString.starts(with: "https://accounts.google.com/o/oauth2/approval/v2")
        else {return}
        
        // FIXME: これ以降のguardにreturn使うのまずくないか?
        // 画面の変化が一切ないままメインに戻っちゃう
        
        // responseパラメータの値を取得
        let queries = URLComponents(string: destination.absoluteString)!.queryItems
        let response = queries!.filter({$0.name == "response"}).first!.value!
        
        // パース
        var parameters: [String: String] = [:]
        _ = response.components(separatedBy: "&")
            .map({$0.components(separatedBy: "=")})
            .map ({parameters[$0[0]] = $0[1]})
        
        // ユーザが認証そのものを拒否した場合
        if parameters.index(forKey: "error") != nil {
            self.failureCallback?(YoutubeKit.AuthError.denied)
            self.dismiss(animated: true, completion: nil)
            return
        }
        
        // アクセストークン生成用コードを取得
        let code = parameters["code"]!
        
        // ユーザが許可したスコープを取得
        let grantedScopes = parameters["scope"]?
            .components(separatedBy: "%20")
            .map({YoutubeKit.Scope(rawValue: $0)})
            .filter({return $0 != nil})
            .map({$0!})
        
        // アクセストークンを生成
        // generatetoken <- こいつにrefreshとtokenの違いも吸収させたい
        
        guard let tokenBaseURL = URL(string: "https://accounts.google.com/o/oauth2/token"),
              var tokenURLComponents = URLComponents(url: tokenBaseURL, resolvingAgainstBaseURL: false) else {return}
        
        let queryParameters = [
            "code": code,
            "client_id": self.apiCredential!.clientID,
            "client_secret": self.apiCredential!.clientSecret,
            "redirect_uri": "urn:ietf:wg:oauth:2.0:oob",
            "grant_type": "authorization_code"
        ]
        let paramItems = queryParameters.map({URLQueryItem(name: $0.key, value: $0.value)})
        tokenURLComponents.queryItems = paramItems
        
        guard let tokenURL = tokenURLComponents.url else {return}
        
        var request: URLRequest = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            // ここで発生するエラーはユーザの操作により発生することはないので
            // UIfullyなエラー処理は(多分)必要ない (YoutubeKit.AuthErrorで握り潰してよし)
            if error != nil{
                self.failureCallback?(YoutubeKit.AuthError.unknown)
                self.dismiss(animated: true, completion: nil)
                return
            }
            
            // レスポンスが取得できないのはちょっと意味わからん
            guard let data = data,
                  let response = response as? HTTPURLResponse else {
                fatalError("Unknown Error has been occured!")
            }
            
            // 2XX以外はエラーとみなす
            guard response.typeOfStatusCode() == .Successful else{
                self.failureCallback?(YoutubeKit.AuthError.invalidCredential)
                self.dismiss(animated: true, completion: nil)
                return
            }
            
            // access_tokenを抽出
            struct Response: Codable{
                let access_token: String
                let expires_in: Int
                let refresh_token: String
                let scope: String
                let token_type: String
            }
            guard let responseBody = try? JSONDecoder().decode(Response.self, from: data) else{
                self.failureCallback?(YoutubeKit.AuthError.invalidResponse)
                self.dismiss(animated: true, completion: nil)
                return
            }
            
            // YoutubeKit.Credentialsのインスタンスをsuccessに載せて返す
            let credential = YoutubeKit.AccessCredential(accessToken: responseBody.access_token, refreshToken: responseBody.refresh_token, expires: Date().advanced(by: TimeInterval(responseBody.expires_in)), grantedScopes: grantedScopes ?? [])
            self.successCallback?(credential)
        }.resume()
        
        self.dismiss(animated: true, completion: nil)
    }
}

