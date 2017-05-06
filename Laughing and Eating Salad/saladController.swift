//
//  saladController.swift
//  Laughing and Eating Salad
//
//  Created by Ryan Pasecky on 3/15/17.
//  Copyright © 2017 Ryan Pasecky. All rights reserved.
//

//
//  homeViewController.swift
//  FloopInContainer
//
//  Created by Ryan Pasecky on 4/26/16.
//  Copyright © 2016 Ryan Pasecky. All rights reserved.
//

import UIKit



class SaladController : UIViewController, UIImagePickerControllerDelegate {
    
    var capturedImage : UIImage?
    var capturingImage: Bool = false
    var attemptedToCaptureImage: Bool = true
    var photoPicker : customPhotoPicker?
    var myScrollView : UIScrollView?
    let tappy = UITapGestureRecognizer()
    
    @IBOutlet var saladScrollView: UIScrollView!
    
    override func viewDidLoad() {
        
        let screenSize = UIScreen.main.bounds.size
        
        let scrollViewSize = CGSize(width: screenSize.width * 3, height: screenSize.height - 65)
        
        let frame1 = CGRect(x: 0, y: -2, width: screenSize.width, height: screenSize.height - 65)
        let frame2 = CGRect(x: screenSize.width, y: 0, width: screenSize.width, height: screenSize.height - 65 )
        let frame3 = CGRect(x: screenSize.width * 2, y: 0, width: screenSize.width, height: screenSize.height - 65)
        
        myScrollView = UIScrollView(frame: frame1)
        myScrollView!.contentSize = scrollViewSize
        myScrollView!.isPagingEnabled = true
        
        let view1 = saladView1.instanceFromNib()
        view1.frame = frame1
        self.myScrollView!.addSubview(view1)
        
        let view2 = saladView2.instanceFromNib()
        view2.frame = frame2
        self.myScrollView!.addSubview(view2)
        
        let view3 = saladView3.instanceFromNib()
        view3.frame = frame3
        self.myScrollView!.addSubview(view3)
        
        
        let myPhotoPicker = customPhotoPicker.instanceFromNib()
        //photoPicker!.saladController = self
        myPhotoPicker.frame = CGRect(x: 0,
                                    y: screenSize.height * 0.1,
                                    width: screenSize.width,
                                    height: screenSize.height * 0.9)
        
        myPhotoPicker.sendSubview(toBack: self.view)
        self.view.addSubview(myPhotoPicker)
        photoPicker = (myPhotoPicker as! customPhotoPicker)
        photoPicker!.initSaladCam()
        photoPicker!.cameraViewFinder!.start()
        photoPicker!.cameraViewFinder.addSubview(myScrollView!)
        //photopicker.ame =
        
        let scrollViewTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(saveScreenshot(_:)))
        scrollViewTapGestureRecognizer.numberOfTapsRequired = 2
        scrollViewTapGestureRecognizer.isEnabled = true
        scrollViewTapGestureRecognizer.cancelsTouchesInView = false
        myScrollView!.addGestureRecognizer(scrollViewTapGestureRecognizer)
        

    }
    
 
  
    
    func saveScreenshot(_ sender: UITapGestureRecognizer) {
        
        print("saving screenshot")
        // Declare the snapshot boundaries
        let top: CGFloat = 65
        let bottom: CGFloat = 0
        
        // The size of the cropped image
        let size = CGSize(width: view.frame.size.width, height: view.frame.size.height - top - bottom)
        
        // Start the context
        UIGraphicsBeginImageContext(size)
        
        // we are going to use context in a couple of places
        let context = UIGraphicsGetCurrentContext()!
        
        // Transform the context so that anything drawn into it is displaced "top" pixels up
        // Something drawn at coordinate (0, 0) will now be drawn at (0, -top)
        // This will result in the "top" pixels being cut off
        // The bottom pixels are cut off because the size of the of the context
        context.translateBy(x: 0, y: -top)
        
        // Draw the view into the context (this is the snapshot)
        self.view.layer.render(in: context)
        let snapshot = UIGraphicsGetImageFromCurrentImageContext()
        
        // End the context (this is required to not leak resources)
        UIGraphicsEndImageContext()
        
        // Save to photos
        UIImageWriteToSavedPhotosAlbum(snapshot!, nil, nil, nil)
    }
    
    func showImageFromLibrary(image: UIImage) {
        
    }
 
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            showImageFromLibrary(image: image)
        } else{
            print("Something went wrong")
        }
        
        self.dismiss(animated: true, completion: nil);
    }
    

    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
}

/*

protocol UIViewLoading {}
extension UIView : UIViewLoading {}

extension UIViewLoading where Self : UIView {
    
    // note that this method returns an instance of type `Self`, rather than UIView
    static func loadFromNib() -> Self {
        let nibName = "\(self)".characters.split{$0 == "."}.map(String.init).last!
        let nib = UINib(nibName: nibName, bundle: nil)
        return nib.instantiate(withOwner: self, options: nil).first as! Self
    }
    
}
*/

