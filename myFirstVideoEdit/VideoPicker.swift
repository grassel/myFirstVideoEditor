//
//  VideoPicker.swift
//  myFirstVideoEdit
//
//  Created by Guido Grassel on 24/09/14.
//  Copyright (c) 2014 Guido Grassel. All rights reserved.
//

import UIKit
import AVFoundation;
import CoreMedia;

class VideoPicker: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
   
    let myViewController : MainScreenViewController!
    
    init(viewController : MainScreenViewController) {
        myViewController = viewController;
    }
    
    /*
    lauches UIImagePicker
    return true if successful
    */
    func selectVideo() -> Bool {
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
            println("UIImagePickerController source type not avail!");
            return false;
        }
        
        var videoPickerVC = UIImagePickerController();
        videoPickerVC.sourceType = UIImagePickerControllerSourceType.PhotoLibrary;
        var availMediaTypesAny : [AnyObject]? = UIImagePickerController.availableMediaTypesForSourceType(UIImagePickerControllerSourceType.PhotoLibrary);
        if (availMediaTypesAny == nil) {
            println ("No media found");
            return false;
        }
        
        // heck, Array has not indexOf method?!
        var availMediaTypes = availMediaTypesAny! as [String];
        while (availMediaTypes.count > 0) {
            if (availMediaTypes.last == "public.movie") {
                break;
            } else {
                availMediaTypes.removeLast();
            }
        }
        
        if (availMediaTypes.count == 0) {
            println ("No movies found");
            return false;
        }
        
        videoPickerVC.mediaTypes = [ "public.movie" ];
        videoPickerVC.setEditing(true, animated: false)
        videoPickerVC.delegate = self;
        myViewController.presentViewController(videoPickerVC, animated: true, nil)
        return true;
    }
    
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        var originalMediaUrl = info[UIImagePickerControllerMediaURL] as? NSURL;
        var editedMediaUrl = info[UIImagePickerControllerReferenceURL] as? NSURL;
        println("editedMediaUrl: \(editedMediaUrl), originalMediaUrl: \(originalMediaUrl)");
        picker.dismissViewControllerAnimated(true, completion: {
            if (originalMediaUrl != nil && editedMediaUrl != nil) {
            self.addMovie(originalMediaUrl: originalMediaUrl!, editedMediaUrl: editedMediaUrl!)
            }
        } )
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        println("user cancelled picking");
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func addMovie(#originalMediaUrl: NSURL, editedMediaUrl : NSURL) {
        myViewController.addMovie(originalMediaUrl: originalMediaUrl, editedMediaUrl: editedMediaUrl, thumbnail: generateThumb(editedMediaUrl));
    }
    
    func generateThumb(movieUrl : NSURL) -> UIImage {
        // http://stackoverflow.com/questions/19105721/thumbnailimageattime-now-deprecated-whats-the-alternative
        var asset : AVURLAsset = AVURLAsset (URL: movieUrl, options: nil);
        var generator : AVAssetImageGenerator = AVAssetImageGenerator(asset: asset);
        generator.appliesPreferredTrackTransform = true;
        var time : CMTime = CMTimeMake(1,2);
        var oneRef : CGImageRef = generator.copyCGImageAtTime(time, actualTime: nil, error: nil);
        var image : UIImage = UIImage(CGImage: oneRef);
        return image;
    }
}
