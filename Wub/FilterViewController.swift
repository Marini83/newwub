//
//  FilterViewController.swift
//  Wub
//  Feb 5 2014
//  Created by User  on 2014-12-19.
//  Copyright (c) 2014 Wub.com. All rights reserved.
//

import UIKit

class FilterViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var collectionView: UICollectionView!
    var thisFeedItem: FeedItem!
    var context : CIContext = CIContext(options: nil)
    
    var filters: [CIFilter] = []
    
    let kIntensity = 0.7
    
    let placeHolderImage =  UIImage(named: "Placeholder" )
    
    var tmp = NSTemporaryDirectory()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        println("entering filterview")
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: 150.0, height: 150.0)
        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.whiteColor()
        collectionView.registerClass(FilterCell.self, forCellWithReuseIdentifier: "MyCell")
        self.view.addSubview(collectionView)
        
        filters = photoFilters()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // UICollectionView DataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filters.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell:FilterCell = collectionView.dequeueReusableCellWithReuseIdentifier("MyCell", forIndexPath: indexPath) as FilterCell
    
        cell.imageView.image = placeHolderImage
        
        let filterQueue:dispatch_queue_t = dispatch_queue_create("filter queue", nil)
        println(thisFeedItem)
        dispatch_async(filterQueue, { () -> Void in
           // let filterImage = self.filteredImageFromImage(self.thisFeedItem.thumbNail, filter: self.filters[indexPath.row])
            let filteredImage  = self.getCachedImage(indexPath.item)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                cell.imageView.image = filteredImage
            })
        })
            
       
       
       // cell.imageView.image = filteredImageFromImage(thisFeedItem.image, filter: filters[indexPath.row])
        return cell
    }
    
    // UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        createUIAlertController(indexPath)
    }
    
    
    // Helper Function
    
    func photoFilters() -> [CIFilter] {
        let blur = CIFilter(name:   "CIGaussianBlur")
        let instant = CIFilter(name: "CIPhotoEffectInstant")
        let noir = CIFilter(name: "CIPhotoEffectNoir")
        let transfer = CIFilter(name:   "CIPhotoEffectTransfer")
        let unsharpen = CIFilter(name: "CIUnsharpMask")
        let monochrome = CIFilter( name:    "CIColorMonochrome")
        let colorControls = CIFilter(name: "CIColorControls")
        colorControls.setValue(0.5 , forKey:kCIInputSaturationKey)
        
        let sepia = CIFilter(name: "CISepiaTone")
        sepia.setValue(kIntensity, forKey: kCIInputIntensityKey)
        
        let colorClamp = CIFilter(name: "CIColorClamp")
        colorClamp.setValue(CIVector(x: 0.9, y: 0.9, z: 0.9, w: 0.9), forKey: "inputMaxComponents")
        colorClamp.setValue(CIVector(x: 0.2, y: 0.2, z: 0.2, w: 0.2), forKey: "inputMinComponents")
        
        
        let composite = CIFilter(name: "CIHardLightBlendMode")
        composite.setValue(sepia.outputImage, forKey: kCIInputImageKey)
        
        let vignette = CIFilter(name: "CIVignette")
        vignette.setValue(composite.outputImage, forKey: kCIInputImageKey)
        vignette.setValue(kIntensity * 2 , forKey: kCIInputIntensityKey)
        vignette.setValue(kIntensity * 30, forKey: kCIInputRadiusKey)
        
        
       // return [blur,instant,noir,transfer, unsharpen, monochrome]
       return [blur,instant,noir,transfer,unsharpen,monochrome, colorControls,sepia, colorClamp, composite, vignette]
    }
    
    func filteredImageFromImage(imageData: NSData, filter:CIFilter) -> UIImage {
        
        let unfilteredImage = CIImage(data: imageData)
        filter.setValue(unfilteredImage, forKey: kCIInputImageKey)
        let filteredImage:CIImage = filter.outputImage
        
        let extent = filteredImage.extent()
        let cgImage:CGImageRef  = context.createCGImage(filteredImage, fromRect: extent)
        
        //let finalImage = UIImage(CGImage: cgImage, scale: 1.0, orientation: UIImageOrientation.Up)
        let finalImage = UIImage(CGImage   : cgImage)
        return finalImage!
        
    }
    
    //UIAlertController Helper Functions
    
    func createUIAlertController (indexPath: NSIndexPath) {
        let alert = UIAlertController(title: "Photo Options", message: "Please choose an option", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.placeholder = "Add Caption!"
            textField.secureTextEntry = false
        }
        
        var text:String
        let textField = alert.textFields![0] as UITextField
        
        
        
        let photoAction = UIAlertAction(title: "Post Photo to Facebook with Captions", style: UIAlertActionStyle.Destructive) { (UIAlertAction) -> Void in
            
            var text = textField.text
            self.saveFilterToCoreData(indexPath, caption: text)
            self.shareToFacebook(indexPath)
            
        }
        alert.addAction(photoAction)
        
        let saveFilterAction = UIAlertAction(title: "Save Filter without posting on Facebook", style: UIAlertActionStyle.Default) { (UIAlertAction) -> Void in
            var text = textField.text
            self.saveFilterToCoreData(indexPath, caption: text)
        }
        alert.addAction(saveFilterAction)
        
        let cancelAction = UIAlertAction(title: "Select another Filter", style: UIAlertActionStyle.Cancel) { (UIAlertAction) -> Void in
        }
        alert.addAction(cancelAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func saveFilterToCoreData(indexPath: NSIndexPath, caption: String){
        
        let filteredImage = self.filteredImageFromImage(self.thisFeedItem.image, filter: self.filters[indexPath.item])
        let imageData = UIImageJPEGRepresentation(filteredImage, 1.0)
        self.thisFeedItem.image = imageData
        let thumbNailData = UIImageJPEGRepresentation(filteredImage, 0.1)
        self.thisFeedItem.thumbNail = thumbNailData
        
        self.thisFeedItem.caption = caption
        self.thisFeedItem.filtered = true
        (UIApplication.sharedApplication().delegate as AppDelegate).saveContext()
        self.navigationController?.popViewControllerAnimated(true)

        
    }
    // facebook app needed
    func shareToFacebook(indexPath: NSIndexPath) {
        let filteredImage = self.filteredImageFromImage(self.thisFeedItem.image, filter: self.filters[indexPath.item])
        let newRotatedForFacebookImage = UIImage(CGImage: filteredImage.CGImage, scale: 1.0, orientation: UIImageOrientation.Right)!
        let photos:NSArray = [newRotatedForFacebookImage]
        var params = FBPhotoParams()
        params.photos = photos as [AnyObject]
        
        if FBDialogs.canPresentMessageDialogWithPhotos() {
            FBDialogs.presentShareDialogWithPhotoParams(params, clientState: nil) { (call, result, error) -> Void in
                if (result != nil) {
                    println(result)
                } else {
                println(error)
                }
            }
        }
        else {
            println("FacebookApp not available")
        }
        
    }
    
    // caching functions
    
    func cacheImage(imageNumber: Int) {
        
         let fileName = "\(thisFeedItem.uniqueID)\(imageNumber)"
      
        let uniquePath = tmp.stringByAppendingPathComponent(fileName)
        if !NSFileManager.defaultManager().fileExistsAtPath(fileName) {
            let data = self.thisFeedItem.thumbNail
            let filter = self.filters[imageNumber]
            let image = filteredImageFromImage(data, filter: filter)
            UIImageJPEGRepresentation(image, 1.0).writeToFile(uniquePath, atomically: true)
        }
    }
    
    
        func getCachedImage (imageNumber: Int) -> UIImage {
            
             let fileName = "\(thisFeedItem.uniqueID)\(imageNumber)"
            let uniquePath = tmp.stringByAppendingPathComponent(fileName)
            
            var image:UIImage
            
            if NSFileManager.defaultManager().fileExistsAtPath(uniquePath) {
                var returnedImage = UIImage(contentsOfFile: uniquePath)!
                image = UIImage(CGImage: returnedImage.CGImage, scale: 1.0, orientation: UIImageOrientation.Right)!
            } else {
                self.cacheImage(imageNumber)
                var returnedImage = UIImage(contentsOfFile: uniquePath)!
                image = UIImage(CGImage: returnedImage.CGImage, scale: 1.0, orientation: UIImageOrientation.Right)!
            }
            return image
        }
    
    
    
    
    
    
    
    
    
}
