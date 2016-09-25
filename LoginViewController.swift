//
//  LoginViewController.swift
//  Chat
//
//  Created by Dominik Grafik on 21.09.2016.
//  Copyright © 2016 Dominik Grafik. All rights reserved.
//

import UIKit
import GoogleSignIn

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
        

        // Do any additional setup after loading the view.
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
