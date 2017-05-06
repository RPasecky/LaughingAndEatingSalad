//
//  customPhotoPicker.swift
//  Laughing and Eating Salad
//
//  Created by Ryan Pasecky on 3/15/17.
//  Copyright © 2017 Ryan Pasecky. All rights reserved.
//


import UIKit


class customPhotoPicker : UIView {
    
    public weak var saladController : SaladController?
    
    @IBOutlet var cameraViewFinder: SobrCameraView!
    
    public func initSaladCam() {
        cameraViewFinder.setupCameraView()
        
        let nc = NotificationCenter.default
        //nc.addObserver(forName:.refreshNotificationNumber, object:nil, queue:nil, using:refreshNotificationNumber)
        
    }
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "customPhotoPicker", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }
    
    public func initForAssignmentCreation() {
        
        
    }
}






