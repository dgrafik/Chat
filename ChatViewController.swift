//
//  ChatViewController.swift
//  Chat
//
//  Created by Dominik Grafik on 21.09.2016.
//  Copyright © 2016 Dominik Grafik. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import MobileCoreServices
import AVKit
import FirebaseDatabase
class ChatViewController: JSQMessagesViewController {

    var messages = [JSQMessage]()
    var messageRef = FIRDatabase.database().reference().child("message")
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.senderId = "1"
        self.senderDisplayName = "Dominik"
        //let rootRef = FIRDatabase.database().reference()
        //let messageRef = rootRef.child("messages")
        //messageRef.childByAutoId().setValue("Dominik123")
        //messageRef.childByAutoId().setValue("First")
        //messageRef.observeEventType(FIRDataEventType.ChildAdded){(snapshot: FIRDataSnapshot) in
            //print(snapshot.value)
            //if let dict = snapshot.value as? NSDictionary {
                //print(dict)
            //}
        //}
        
        observeMessages()
    }
    
    func observeMessages(){
        messageRef.observeEventType(.ChildAdded, withBlock: { snapshot in
            if let dict = snapshot.value as? [String: AnyObject]{
                let MediaType = dict["MediaType"] as! String
                let senderId = dict["senderId"] as! String
                let senderName = dict["senderName"] as! String
                let text = dict["text"] as! String
                self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, text: text))
                self.collectionView.reloadData()
            }
            
        })
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        print("didpress")
        
        //messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, text: text))
        //collectionView.reloadData()
        let newMessage = messageRef.childByAutoId()
        let messageData = ["text": text, "senderId": senderId, "senderName": senderDisplayName, "MediaType": "TEXT"]
        newMessage.setValue(messageData)
    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
        print("accesrry")
        
        let sheet = UIAlertController(title: "Media Messages", message: "Select the media", preferredStyle: UIAlertControllerStyle.ActionSheet)
        let cancel = UIAlertAction(title: "cancel", style: UIAlertActionStyle.Cancel){ (alert: UIAlertAction) in
        }
        
        let photoLibrary = UIAlertAction(title: "Photo Library", style: UIAlertActionStyle.Default){ (alert: UIAlertAction) in
            self.getMediaFrom(kUTTypeImage)

        }
        let videoLibrary = UIAlertAction(title: "Video Library", style: UIAlertActionStyle.Default){ (alert: UIAlertAction) in
            self.getMediaFrom(kUTTypeMovie)

        }
        
        sheet.addAction(photoLibrary)
        sheet.addAction(videoLibrary)
        sheet.addAction(cancel)
        self.presentViewController(sheet, animated: true, completion: nil)
        
        //let imagePicker = UIImagePickerController()
        //imagePicker.delegate = self
        //self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    func getMediaFrom(type: CFString){
        print(type)
        let mediaPicker = UIImagePickerController()
        mediaPicker.delegate = self
        mediaPicker.mediaTypes = [type as String]
        self.presentViewController(mediaPicker, animated: true, completion: nil)
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        return bubbleFactory.outgoingMessagesBubbleImageWithColor(.blackColor())
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        return cell
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAtIndexPath indexPath: NSIndexPath!) {
        print("didTapMessageBubbleAtIndexPath")
        let message = messages[indexPath.item]
        if message.isMediaMessage{
            if let mediaItem = message.media as? JSQVideoMediaItem{
                let player = AVPlayer(URL: mediaItem.fileURL)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                self.presentViewController(playerViewController, animated: true, completion: nil)
            }
            
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func logOutDidTaped(sender: AnyObject) {
        print("anything")
        // Create a main storyboard instance
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // From main storyboard instantiate a View controller
        let loginVC = storyboard.instantiateViewControllerWithIdentifier("LoginVC") as! LoginViewController
        
        // Get the app delegate
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        // Set Login (View Controller) Controller as root view controller
        appDelegate.window?.rootViewController = loginVC
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

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        print("finich picking")
        // get the image
        print(info)
        
        if let picture = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let photo = JSQPhotoMediaItem(image: picture)
            messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, media: photo))
        }else if let video = info[UIImagePickerControllerMediaURL] as? NSURL{
            let videoItem = JSQVideoMediaItem(fileURL: video, isReadyToPlay: true)
            messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, media: videoItem))
        }
        self.dismissViewControllerAnimated(true, completion: nil)
        collectionView.reloadData()
        
    }
}
