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
import FirebaseStorage
import FirebaseAuth
//import SDWebImage
class ChatViewController: JSQMessagesViewController {

    var messages = [JSQMessage]()
    var messageRef = FIRDatabase.database().reference().child("message")
    var avatarDict = [String: JSQMessagesAvatarImage]()
    let photoCache = NSCache() //czaem wczytuje zły obrazek - do rozwiązania problemu
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let currentUser = FIRAuth.auth()?.currentUser {
            self.senderId = currentUser.uid
            
            if currentUser.anonymous == true{
                self.senderDisplayName = "Anonymous"
            }else{
                self.senderDisplayName = "\(currentUser.displayName!)"
            }
        }
        observeMessages()
    }
    
    func observeUser(id: String){
        
        FIRDatabase.database().reference().child("user").child(id).observeEventType(.Value, withBlock: { snapshot in
            if let dict = snapshot.value as? [String: AnyObject]
            {
                //print(dict)
                let avatarUrl = dict["profileUrl"] as! String
                self.setupAvatar(avatarUrl, messageId: id)
            }
        })
    }
    
    func setupAvatar(url: String, messageId: String){
        if url != ""{
            let fileUrl = NSURL(string: url)
            let data = NSData(contentsOfURL: fileUrl!)
            let image = UIImage(data: data!)
            let userImage = JSQMessagesAvatarImageFactory.avatarImageWithImage(image, diameter: 30)
            avatarDict[messageId] = userImage
            
        }else{
            avatarDict[messageId] = JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(named: "deadPool"), diameter: 30)
    
        }
        collectionView.reloadData()
}
    
    func observeMessages(){//wyrzucić ciężkie dane poza główny wątek = Photo i Video - Asynchroniczność
        messageRef.observeEventType(.ChildAdded, withBlock: { snapshot in
            if let dict = snapshot.value as? [String: AnyObject]{
                let MediaType = dict["MediaType"] as! String
                let senderId = dict["senderId"] as! String
                let senderName = dict["senderName"] as! String
                self.observeUser(senderId)
                let startTime = CFAbsoluteTimeGetCurrent()
                
                switch MediaType{ //switch zamiast else if - default -> gdy nie rozpozna MediaType
                    
                case "TEXT":
                    
                    let text = dict["text"] as! String
                    self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, text: text))
                    print(CFAbsoluteTimeGetCurrent() - startTime)
                    
                case "PHOTO": //OGARNĄĆ JESZCZE SDWebImage do asynchronicznego pobierania zdjęć !!! -> Problem z frameworkiem - niewidoczny
                    
                    var photo = JSQPhotoMediaItem(image: nil)
                    let fileUrl = dict["fileUrl"] as! String
                    
                    if let cachePhoto = self.photoCache.objectForKey(fileUrl) as? JSQPhotoMediaItem{
                        photo = cachePhoto
                        self.collectionView.reloadData()
                    }else{
                        
                        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), {
                            let data = NSData(contentsOfURL: NSURL(string: fileUrl)!)
                            dispatch_async(dispatch_get_main_queue(), {
                                //let url = NSURL(string: fileUrl)
                                let image = UIImage(data: data!)
                                photo.image = image
                                self.collectionView.reloadData()
                                self.photoCache.setObject(photo, forKey: fileUrl)
                            })
                             //print("później test wątku")
                       })

                        
                    }
                    //print("wcześniej test wątku")
                    self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, media: photo))
                    
                    if self.senderId == senderId{
                        photo.appliesMediaViewMaskAsOutgoing = true
                    }else{
                        photo.appliesMediaViewMaskAsOutgoing = false
                    }
                    print(CFAbsoluteTimeGetCurrent() - startTime)

                case "VIDEO":
                    
                    let fileUrl = dict["fileUrl"] as! String
                    let video = NSURL(string: fileUrl)
                    let videoItem = JSQVideoMediaItem(fileURL: video, isReadyToPlay: true)
                    self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, media: videoItem))
                
                    if self.senderId == senderId{
                        videoItem.appliesMediaViewMaskAsOutgoing = true
                    }else{
                        videoItem.appliesMediaViewMaskAsOutgoing = false
                    print(CFAbsoluteTimeGetCurrent() - startTime)

                }
                    
                default:
                    print("nieznany typ danych!")
                }                
                self.collectionView.reloadData()
            }
            
        })
    }
    
    
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        print("didpress")
        
        let newMessage = messageRef.childByAutoId()
        let messageData = ["text": text, "senderId": senderId, "senderName": senderDisplayName, "MediaType": "TEXT"]
        newMessage.setValue(messageData)
        self.finishSendingMessage()
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
        let message = messages[indexPath.item]
        return avatarDict[message.senderId]
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        let bubbleFactory = JSQMessagesBubbleImageFactory()

        if message.senderId == self.senderId{
            return bubbleFactory.outgoingMessagesBubbleImageWithColor(.blueColor())

        }else{
            return bubbleFactory.outgoingMessagesBubbleImageWithColor(.blackColor())

        }
        
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
        
        do{
            try FIRAuth.auth()?.signOut()
        } catch let error{
            print(error)
        }

        //Stwórz główną instancję (main) storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        //Z głównego storyboardu stwórz instantiate View controller
        let loginVC = storyboard.instantiateViewControllerWithIdentifier("LoginVC") as! LoginViewController
        // App Delegate -> get
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        //Ustaw login view controller jako root
        appDelegate.window?.rootViewController = loginVC
    }

    func sendMedia(picture: UIImage?, video: NSURL?){
        print(picture)
        if let picture = picture{
            let filePath = "\(FIRAuth.auth()!.currentUser!)/\(NSDate.timeIntervalSinceReferenceDate())" //scieżka
            print(filePath)
            let data = UIImageJPEGRepresentation(picture, 0.1) //lżejsza wersja z 1 na 0.1
            let metadata = FIRStorageMetadata() //String!
            metadata.contentType = "image/jpg"
            FIRStorage.storage().reference().child(filePath).putData(data!, metadata: metadata){ (metadata, error) in
                if error != nil{
                    print(error?.localizedDescription)
                    return
                }
                let fileUrl = metadata!.downloadURLs![0].absoluteString
                let newMessage = self.messageRef.childByAutoId()
                let messageData = ["fileUrl": fileUrl, "senderId": self.senderId, "senderName": self.senderDisplayName, "MediaType": "PHOTO"] // można wysłać w końcu zdjęcie, zapsane w storage, fileUrl z z storage
                newMessage.setValue(messageData)
            }
        }else if let video = video {
            let filePath = "\(FIRAuth.auth()!.currentUser!)/\(NSDate.timeIntervalSinceReferenceDate())" //scieżka
            print(filePath)
            let data = NSData(contentsOfURL: video)
            let metadata = FIRStorageMetadata() //String!
            metadata.contentType = "video/mp4"
            FIRStorage.storage().reference().child(filePath).putData(data!, metadata: metadata){ (metadata, error) in
                if error != nil{
                    print(error?.localizedDescription)
                    return
                }
                let fileUrl = metadata!.downloadURLs![0].absoluteString
                let newMessage = self.messageRef.childByAutoId()
                let messageData = ["fileUrl": fileUrl, "senderId": self.senderId, "senderName": self.senderDisplayName, "MediaType": "VIDEO"]
                newMessage.setValue(messageData)
            }
            
        }
    }
        
    
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        print("finish picking")
        // bierzemy obrazek lub video
        print(info)
        
        if let picture = info[UIImagePickerControllerOriginalImage] as? UIImage {
            sendMedia(picture, video: nil)
        }else if let video = info[UIImagePickerControllerMediaURL] as? NSURL{
            sendMedia(nil, video: video)
        }
        self.dismissViewControllerAnimated(true, completion: nil)
        collectionView.reloadData()
        
    }
}
