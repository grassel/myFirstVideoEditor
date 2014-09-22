//
//  ViewController.swift
//  myFirstVideoEdit
//
//  Created by Guido Grassel on 22/09/14.
//  Copyright (c) 2014 Guido Grassel. All rights reserved.
//

import UIKit
import MediaPlayer;

class MainScreenViewController: UIViewController,  UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var movieThumbImage1: UIImageView!
    @IBOutlet weak var movieThumbImage2: UIImageView!
    @IBOutlet weak var movieThumbImage3: UIImageView!
    @IBOutlet weak var movieThumbImage4: UIImageView!
    
    var movieThumbsImageViews : [UIImageView] = nil;
    var movieThumbsImages : [UIImage] =
    
    var editedMediaUrl : NSURL!;
    var originalMediaUrl : NSURL!;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        movieThumbsImageViews = [
            movieThumbImage1!, movieThumbImage2!, movieThumbImage3!, movieThumbImage4!
        ];
        // Do any additional setup after loading the view, typically from a nib.
    }

 
    @IBAction func addVideoSelected(sender: AnyObject) {
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
            println("UIImagePickerController source type not avail!");
            return;
        }
        
        var videoPickerVC = UIImagePickerController();
        videoPickerVC.sourceType = UIImagePickerControllerSourceType.PhotoLibrary;
        var availMediaTypesAny : [AnyObject]? = UIImagePickerController.availableMediaTypesForSourceType(UIImagePickerControllerSourceType.PhotoLibrary);
        if (availMediaTypesAny == nil) {
            println ("No media found");
            return;
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
            return;
        }
        
        videoPickerVC.mediaTypes = [ "public.movie" ];
        videoPickerVC.setEditing(true, animated: false)
        videoPickerVC.delegate = self;
        self.presentViewController(videoPickerVC, animated: true, nil)
    }

    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        self.originalMediaUrl = info[UIImagePickerControllerMediaURL] as? NSURL;
        self.editedMediaUrl = info[UIImagePickerControllerReferenceURL] as? NSURL;
        println("editedMediaUrl: \(editedMediaUrl), originalMediaUrl: \(originalMediaUrl)");
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        println("user cancelled picking");
        picker.dismissViewControllerAnimated(true, completion: nil)
    }

    func generateThumb(movieUrl : NSURL) -> UIImage {
        var player = MPMoviePlayerController(contentURL: movieUrl);
        var image = player.thumbnailImageAtTime(1.0, timeOption:MPMovieTimeOptionNearestKeyFrame);
        
        return image;
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

