//
//  FeedViewController.swift
//  Wub
//
//  Created by User  on 2014-12-12.
//  Copyright (c) 2014 Wub.com. All rights reserved.
//

import UIKit
import MobileCoreServices
import CoreData
import MapKit


class FeedViewController: UIViewController, UICollectionViewDataSource,UICollectionViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var feedArray: [AnyObject] = []
    var locationManager: CLLocationManager!
    
    
    override func viewDidLoad() {
         super.viewDidLoad()
        // collectionview background image
        
//        let request = NSFetchRequest(entityName: "FeedItem")
//        let appDelegate:AppDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)
//        let context:NSManagedObjectContext = appDelegate.managedObjectContext!
//        feedArray = context.executeFetchRequest(request, error: nil)!
       
        
        let backgroundImage = UIImage(named: "AutumnBackground")
        self.view.backgroundColor = UIColor(patternImage: backgroundImage!)
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // most precise possible location
        locationManager.requestAlwaysAuthorization()
        
        locationManager.distanceFilter = 100.0 // in meters (min distance before an update event is generated)
        locationManager.startUpdatingLocation()//        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: "onScrollViewDoubleTapped:");
//        doubleTapRecognizer.numberOfTapsRequired = 1;
//        doubleTapRecognizer.numberOfTouchesRequired = 1;
//        collectionView.addGestureRecognizer(doubleTapRecognizer);
    }
    
    
//    func onScrollViewDoubleTapped(recognizer:UITapGestureRecognizer)
//    {
//        println("double tapped")
//    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        let request = NSFetchRequest(entityName: "FeedItem")
        let appDelegate:AppDelegate = (UIApplication.sharedApplication().delegate as AppDelegate)
        let context:NSManagedObjectContext = appDelegate.managedObjectContext!
        feedArray = context.executeFetchRequest(request, error: nil)!
        collectionView.reloadData()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func profileTapped(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("profileSegue", sender: nil)
    }
    
   
    
    @IBAction func snapBarButtonItemTapped(sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera){
            
        
        var cameraController = UIImagePickerController()
            cameraController.delegate = self
            cameraController.sourceType = UIImagePickerControllerSourceType.Camera
            
            let mediaTypes:[AnyObject] = [kUTTypeImage]
            cameraController.mediaTypes = mediaTypes
            cameraController.allowsEditing = false //allow user to edit photos
            
            self.presentViewController(cameraController, animated: true, completion: nil)
        }
        else if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary){
            var photoLibraryController = UIImagePickerController()
            photoLibraryController.delegate = self
            photoLibraryController.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            
           
            let mediaTypes:[AnyObject] = [kUTTypeImage]
            photoLibraryController.mediaTypes = mediaTypes
            photoLibraryController.allowsEditing = false
            
            self.presentViewController(photoLibraryController, animated: true, completion: nil)
            
        }
        else {
            var alertView = UIAlertController(title: "Alert", message: "Your device does not support the camera or photo library", preferredStyle: UIAlertControllerStyle.Alert)
            alertView.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alertView, animated: true, completion: nil)
            
        }
    }
    
    //UIImagePickerControllerDelegate
    
     func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        let image = info[UIImagePickerControllerOriginalImage] as UIImage
        //normal image
        let imageData = UIImageJPEGRepresentation(image, 1.0)
        //compressed
        let thumbNailData = UIImageJPEGRepresentation(image, 0.1)
        
        let managedObjectContext = (UIApplication.sharedApplication().delegate as AppDelegate).managedObjectContext
        let entityDescription = NSEntityDescription.entityForName("FeedItem", inManagedObjectContext: managedObjectContext!)
        let feedItem = FeedItem(entity: entityDescription!, insertIntoManagedObjectContext: managedObjectContext!)
        
        feedItem.image = imageData
        feedItem.caption = "\(getCurrentTimeStamp())"
       feedItem.cdate = getCurrentTimeStamp()
        
        
        //println(feedItem.cdate)
        feedItem.thumbNail = thumbNailData
        if locationManager.location != nil {
        feedItem.latitude = locationManager.location.coordinate.latitude
        feedItem.longitude = locationManager.location.coordinate.longitude
        }
        else {
            println("No location available")
        }
        //generate unique ID for the images stored in the CoreData
        let UUID = NSUUID().UUIDString
        feedItem.uniqueID = UUID
        
        feedItem.filtered = false
        
        (UIApplication.sharedApplication().delegate as AppDelegate).saveContext()
        
        feedArray.append(feedItem)
        
        self.dismissViewControllerAnimated(true, completion: nil)
        self.collectionView.reloadData()
        println(info)
    }
    
    
    //UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return feedArray.count
        
        
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return UIInterfaceOrientation.Portrait.rawValue
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        var cell:FeedCell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as FeedCell
        
        let thisItem = feedArray[indexPath.item] as FeedItem
        
        if thisItem.filtered == true {
            let returnedImage = UIImage(data: thisItem.image)
            let rotatedImage = UIImage(CGImage: returnedImage?.CGImage, scale: 1.0, orientation: UIImageOrientation.Right)
            cell.imageView.image = rotatedImage

        }
        else {
            cell.imageView.image = UIImage(data: thisItem.image)
        }
        
        cell.captionLabel.text = thisItem.caption
        
        return cell
    }
    
    //MARK: UICOllectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let thisItem = feedArray[indexPath.row] as FeedItem
        
        var filterVC = FilterViewController()
        filterVC.thisFeedItem = thisItem
        self.navigationController?.pushViewController(filterVC, animated: false)
    }
    
    //MARK: CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        println("locations = \(locations)")
    }
    
    //MARK: Helper Functions
    
    func getCurrentTime() -> String {
        
        let date = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateStyle = .LongStyle
        var stringValue = formatter.stringFromDate(date)
        
        return stringValue
        
    }
    
     func getCurrentTimeStamp() -> NSTimeInterval {
        let date = NSDate()
        let timestamp = date.timeIntervalSince1970
        //let timestampString = "\(timestamp)"
        return timestamp
    }
    
    
    
    
}
