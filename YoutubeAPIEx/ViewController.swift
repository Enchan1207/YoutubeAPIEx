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
    
    private let userDefaults = UserDefaults.standard
    private var credential: YoutubeKit.AccessCredential?
    
    private let youtube = YoutubeKit(apiCredential: YoutubeKit.APICredential(APIKey: DefaultCredential.APIKey, clientID: DefaultCredential.clientID, clientSecret: DefaultCredential.clientSecret), accessCredential: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let storedCredentialString = self.userDefaults.object(forKey: "CREDENTIAL") as? String,
           let storedCredential = YoutubeKit.AccessCredential.deserialize(object: storedCredentialString){
            print("stored credential has been loaded.")
            self.credential = storedCredential
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let credential = self.credential{
            youtube.accessCredential = credential
            youtube.getPlayList(part: ["id", "snippet"], channelID: nil, maxResults: 50)
        }
    }
    
    @IBAction func onTapAuth(_ sender: Any) {
        // 認証画面を開く
        let scope: [YoutubeKit.Scope] = [.readwrite, .audit]
        youtube.authorize(presentViewController: self, scope: scope) { (credential) in
            // credentialを保存
            print("success! credential will be saved.")
            self.credential = credential
            self.userDefaults.setValue(credential.serialize()!, forKey: "CREDENTIAL")
        } failure: { (error) in
            print(error)
        }
    }
}
