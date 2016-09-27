//
//  LoginViewController.swift
//  Chat
//
//  Created by Dominik Grafik on 21.09.2016.
//  Copyright © 2016 Dominik Grafik. All rights reserved.
//

import UIKit
import GoogleSignIn
import FirebaseAuth
import FirebaseDatabase

class LoginViewController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //Border colour and width
        
        logAnon.layer.borderWidth = 1.8
        logAnon.layer.borderColor = UIColor.whiteColor().CGColor
        logAnon.layer.cornerRadius = 5
        
        GIDSignIn.sharedInstance().clientID = "864611289170-kp3u2fjhls5168cb5002e8o0rjon1idf.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        FIRAuth.auth()?.addAuthStateDidChangeListener({ (auth: FIRAuth, user: //autologin
            FIRUser?) in
            
            if user != nil{
                print(user)
                Helper.helper.switchToNavigationViewController()
            }else{
                print("unauto")
            }
        
        })
        
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can e recreated.
    }
    @IBAction func logAnonDidTaped(sender: AnyObject) {
        print("Anon")
        Helper.helper.logAnonymously()
    }
    @IBAction func logGoogleDidTaped(sender: AnyObject) {
        print("Gogole")
        
        GIDSignIn.sharedInstance().signIn()
    }
    
    @IBOutlet weak var logAnon: UIButton!
    
    func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!, withError error: NSError!){
        if error != nil{
            print(error!.localizedDescription)
        }
        print(user.authentication)
        Helper.helper.loginWithGoogle(user.authentication)

    }
    
 

}
