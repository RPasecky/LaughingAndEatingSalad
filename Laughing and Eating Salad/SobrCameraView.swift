//
//  sobrCameraView.swift
//  Laughing and Eating Salad
//
//  Created by Ryan Pasecky on 3/15/17.
//  Copyright © 2017 Ryan Pasecky. All rights reserved.
//

//
//  SobrCameraView.swift
//  SobrCameraView-Example
//
//  Created by Silas Knobel on 16/06/15.
//  Copyright (c) 2015 Software Brauerei AG. All rights reserved.
//

// I am defeated. for some reason my filter function isn't working.....Till next time swift!!!!

import UIKit
import AVFoundation
import CoreVideo
import CoreMedia
import CoreImage
import ImageIO
import GLKit

/**
 Available Image Filters
 
 - `.BlackAndWhite`: A black and white filter to increase the contrast.
 - `.Normal`: Increases the contrast on colored pictures.
 */
public enum SobrCameraViewImageFilter: Int {
    case blackAndWhite = 0
    case normal = 1
}

/**
 *  A simple UIView-Subclass which enables border detection of documents
 */
open class SobrCameraView: UIView, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    //MARK: Properties
    /// Enables realtime border detection.
    /// Sets the torch enabled or disabled.

    
    /// Sets the imageFilter based on `SobrCameraViewImageFilter` Enum.
    
    //MARK: Private Properties
    fileprivate var captureSession = AVCaptureSession()
    fileprivate var captureDevice: AVCaptureDevice?
    fileprivate var context: EAGLContext?
    fileprivate var stillImageOutput: AVCaptureStillImageOutput = AVCaptureStillImageOutput()
    fileprivate var forceStop: Bool = false
    fileprivate var coreImageContext: CIContext?
    fileprivate var renderBuffer: GLuint = 0
    fileprivate var glkView: GLKView?
    fileprivate var stopped: Bool = false
    fileprivate var imageDetectionConfidence = 0.0
    fileprivate var borderDetectFrame: Bool = false
    fileprivate var boundsValidityTally: Int = 0
    fileprivate var capturing: Bool = false
    fileprivate var timeKeeper: Timer?
    fileprivate var filterThreshold : CGFloat = 100000.0
    
    fileprivate static let highAccuracyRectangleDetector = CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
    
    //MARK: Lifecycle
    
    /**
     Adds observers to the NSNotificationCenter.
     */
    open override func awakeFromNib() {
        super.awakeFromNib()
        NotificationCenter.default.addObserver(self, selector: #selector(SobrCameraView._backgroundMode), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SobrCameraView._foregroundMode), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: Actions
    /**
     Set's up all needed Elements for Video and Border detection. Should be called in `viewDidLoad:` in the view controller.
     */
    open func setupCameraView() {
        self.setupGLKView()

        
        let allDevices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
        let aDevice: AnyObject? = allDevices?.first as AnyObject?
        
        if aDevice == nil {
            return
        }
        
        let cameraMediaType = AVMediaTypeVideo
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: cameraMediaType)
        
        
    switch cameraAuthorizationStatus {
         case .denied:
         
            let alertController = UIAlertController(title: "Camera Restricted", message: "It looks like you have not granted Floop permission to use the camera. If you would like to capture images in App, you can change app permissions in Settings", preferredStyle: UIAlertControllerStyle.alert)
         
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
            {
                (result : UIAlertAction) -> Void in
                print("You pressed OK")
            }
                alertController.addAction(okAction)
                //self.present(alertController, animated: true, completion: nil)
         
         case .restricted: break
         case .notDetermined:
         // Prompting user for the permission to use the camera.
            AVCaptureDevice.requestAccess(forMediaType: cameraMediaType) { granted in
                if granted {
                    print("Granted access to \(cameraMediaType)")
                } else {
                    print("Denied access to \(cameraMediaType)")
                }
            }
         case .authorized:
            self.captureSession.beginConfiguration()
            self.captureDevice = (aDevice as! AVCaptureDevice)
        
            let input = try! AVCaptureDeviceInput(device: self.captureDevice)
            self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto
            self.captureSession.addInput(input)
        
            let dataOutput = AVCaptureVideoDataOutput()
            dataOutput.alwaysDiscardsLateVideoFrames = true
            //        dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA]
            dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
            self.captureSession.addOutput(dataOutput)
            
            self.captureSession.addOutput(self.stillImageOutput)
        
            let connection = dataOutput.connections.first as! AVCaptureConnection
            connection.videoOrientation = .portrait
        
            if self.captureDevice!.isFlashAvailable {
                try! self.captureDevice?.lockForConfiguration()
                self.captureDevice?.flashMode = .off
                self.captureDevice?.unlockForConfiguration()
            }
        
            if self.captureDevice!.isFocusModeSupported(.continuousAutoFocus) {
                try! self.captureDevice?.lockForConfiguration()
                self.captureDevice?.focusMode = .continuousAutoFocus
                self.captureDevice?.unlockForConfiguration()
            }
        
            self.captureSession.commitConfiguration()
        
        }
    }
    /**
     Starts the camera.
     */
    open func start() {
        self.stopped = false
        self.captureSession.startRunning()

    }
    
    /**
     Stops the camera
     */
    open func stop() {
        self.stopped = true
        self.captureSession.stopRunning()
        self.timeKeeper?.invalidate()
    }
    
    /**
     Sets the focus of the camera to a given point if supported.
     
     :param: point      The point to focus.
     :param: completion The completion handler will be called everytime. Even if the camera does not support focus.
     */
    open func focusAt(_ point: CGPoint, completion:((Void)-> Void)?) {
        if let device = self.captureDevice {
            let poi = CGPoint(x: point.y / self.bounds.height, y: 1.0 - (point.x / self.bounds.width))
            if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                try! device.lockForConfiguration()
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                    device.focusPointOfInterest = poi
                }
                
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposurePointOfInterest = poi
                    device.exposureMode = .continuousAutoExposure
                }
                
                device.unlockForConfiguration()
                completion?()
            }
        }
        else {
            completion?()
        }
    }
    
    /**
     Captures the image. If `borderDetectionEnabled` is `true`, a perspective correction will be applied to the image.
     The selected `imageFilter` will also be applied to the image.
     
     :param: completion Returns the image as `UIImage`.
     */
    open func captureImage(_ completion: @escaping (_ image: UIImage?, _ feature: CIRectangleFeature?, _ abort: Bool) -> Void) {
        if self.capturing {
            return
        }
        
        var abortedCapture = false
        
        self.capturing = true
        
        var videoConnection: AVCaptureConnection?
        for connection in self.stillImageOutput.connections as! [AVCaptureConnection] {
            for port in connection.inputPorts as! [AVCaptureInputPort] {
                if port.mediaType == AVMediaTypeVideo {
                    videoConnection = connection
                    break
                }
            }
            if let _ = videoConnection {
                break
            }
        }
        
        
        
        self.stillImageOutput.captureStillImageAsynchronously(from: videoConnection!, completionHandler: { (imageSampleBuffer, error) -> Void in
            
            var jpg = Data()
            var image: UIImage?
            var newFeature : CIRectangleFeature?
            
            if imageSampleBuffer == nil {
                abortedCapture = true
                print("sample buffer = nil")
                return
            } else {
                jpg = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageSampleBuffer)
                
                var enhancedImage: CIImage = CIImage(data: jpg)!
                //switch self.imageFilter {
                //case .blackAndWhite:
                //    enhancedImage = self.contrastFilter(enhancedImage)
                //default:
                //    enhancedImage = self.enhanceFilter(enhancedImage)
               // }
                
                
                
                UIGraphicsBeginImageContext(CGSize(width: enhancedImage.extent.size.height, height: enhancedImage.extent.size.width))
                
                UIImage(ciImage: enhancedImage, scale: 1.0, orientation: UIImageOrientation.right).draw(in: CGRect(x: 0, y: 0, width: enhancedImage.extent.size.height, height: enhancedImage.extent.size.width))
                
                image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
            }
            print("abortedCapture: \(abortedCapture)")
            completion(image, newFeature , abortedCapture)
            
        })
        
        self.capturing = false
        
    }
    
    //MARK: Private Actions
    /**
     This method is for internal use only. But it must be public to subscribe to `NSNotificationCenter` events.
     */
    open func _backgroundMode() {
        self.forceStop = true
    }
    /**
     This method is for internal use only. But it must be public to subscribe to `NSNotificationCenter` events.
     */
    open func _foregroundMode() {
        self.forceStop = false
    }
    
    private func setupGLKView() {
        if let _ = self.context {
            return
        }
        
        self.context = EAGLContext(api: .openGLES2)
        self.glkView = GLKView(frame: self.bounds, context: self.context!)
        self.glkView!.autoresizingMask = ([UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight])
        self.glkView!.translatesAutoresizingMaskIntoConstraints = true
        self.glkView!.contentScaleFactor = 1.0
        self.glkView!.drawableDepthFormat = .format24
        self.insertSubview(self.glkView!, at: 0)
        glGenRenderbuffers(1, &self.renderBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), self.renderBuffer)
        
        self.coreImageContext = CIContext(eaglContext: self.context!, options: [kCIContextUseSoftwareRenderer: true])
        EAGLContext.setCurrent(self.context!)
    }
    /**
     This method is for internal use only. But it must be public to subscribe to `NSNotificationCenter` events.
     */

    
    /*
    fileprivate func contrastFilter(_ image: CIImage) -> CIImage {
        return CIFilter(name: "CIColorControls", withInputParameters: ["inputContrast":1.1, kCIInputImageKey: image])!.outputImage!
    }
    
    fileprivate func enhanceFilter(_ image: CIImage) -> CIImage {
        return CIFilter(name: "CIColorControls", withInputParameters: ["inputBrightness":0.0, "inputContrast":1.14, "inputSaturation":0.0, kCIInputImageKey: image])!.outputImage!
    }*/
    
    
    //MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    /**
     This method is for internal use only. But must be declared public because it matches a requirement in public protocol `AVCaptureVideoDataOutputSampleBufferDelegate`.
     */
    open func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        if self.forceStop {
            return
        }
        let sampleBufferValid: Bool = CMSampleBufferIsValid(sampleBuffer)
        if self.stopped || self.capturing || !sampleBufferValid {
            return
        }
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        var image = CIImage(cvPixelBuffer: pixelBuffer!)
        
        /*
        switch self.imageFilter {
        case .blackAndWhite:
            image = self.contrastFilter(image)
        default:
            image = self.enhanceFilter(image)
        }*/
        
        
        
        if let context = self.context, let ciContext = self.coreImageContext, let glkView = self.glkView {
            ciContext.draw(image, in: self.bounds, from: image.extent)
            context.presentRenderbuffer(Int(GL_RENDERBUFFER))
            glkView.setNeedsDisplay()
        }
    }
    
    
}
