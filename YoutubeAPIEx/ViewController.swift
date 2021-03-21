//
//  ViewController.swift
//  YoutubeAPIEx
//
//  Created by EnchantCode on 2021/03/19.
//

import UIKit
import WebKit
import SafariServices

class ViewController: UIViewController {
    
    private let youtube = YoutubeKit(apiCredential: YoutubeKit.APICredential(APIKey: DefaultCredential.APIKey, clientID: DefaultCredential.clientID, clientSecret: DefaultCredential.clientSecret), accessCredential: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func onTapAuth(_ sender: Any) {
        // 認証画面を開く
        let scope: [YoutubeKit.Scope] = [.readwrite, .audit]
        youtube.authorize(presentViewController: self, scope: scope) { (credential) in
            print(credential)
        } failure: { (error) in
            print(error)
        }

    }
    
}
