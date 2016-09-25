//
//  Helper.swift
//  Chat
//
//  Created by Dominik Grafik on 24.09.2016.
//  Copyright © 2016 Dominik Grafik. All rights reserved.
//

import Foundation
import FirebaseAuth
import UIKit
import GoogleSignIn

class Helper{
    static let helper = Helper()
    
    func logAnonymously() {
        FIRAuth.auth()?.signInAnonymouslyWithCompletion({(anonymouseUser: FIRUser?, error: NSError?) in
            if error == nil{
                print("UserId: \(anonymouseUser!.uid)")
                self.switchToNavigationViewController()
            }else{
                print(error!.localizedDescription)
            }
        })
    }
    
    func loginWithGoogle(authentication: GIDAuthentication) {
        let credential = FIRGoogleAuthProvider.credentialWithIDToken(authentication.idToken, accessToken: authentication.accessToken)
        
        FIRAuth.auth()?.signInWithCredential(credential, completion: { (user: FIRUser?, error: NSError?) in
            if error != nil {
                print(error!.localizedDescription)
                return
            }else{
                print(user?.email)
                print(user?.displayName)
                self.switchToNavigationViewController()
            }
            
        })
        
    }
    
    private func switchToNavigationViewController(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let naviVC = storyboard.instantiateViewControllerWithIdentifier("NavigationVC") as! UINavigationController
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.window?.rootViewController = naviVC
        
    }
}
