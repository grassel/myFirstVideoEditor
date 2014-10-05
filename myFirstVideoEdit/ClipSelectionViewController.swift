//
//  VidPlayerViewController.swift
//  myFirstVideoEdit
//
//  Created by Guido Grassel on 30/09/14.
//  Copyright (c) 2014 Guido Grassel. All rights reserved.
//

import UIKit
import Photos
import CoreMedia;
import QuartzCore;

class ClipSelectionViewController: UIViewController {

    var playingAsset : PHAsset!
    var vidPlayerViewController : VidPlayerViewController!;
    
    @IBOutlet weak var avPlayerContainingView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        vidPlayerViewController = VidPlayerViewController(myView: avPlayerContainingView);
        vidPlayerViewController.autoStartOnPlay = true
        vidPlayerViewController.viewWillAppear(animated)
        
        if (playingAsset != nil) {
            self.vidPlayerViewController.play(phasset: playingAsset)
        } else {
            println("VidPlayerViewController - viewWillAppear: no PHAsset to play!");
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    

    @IBAction func cancelSelected(sender: AnyObject) {
        self.vidPlayerViewController.stopPlaying();

        // got back to the list of my videos
        self.navigationController?.popViewControllerAnimated(true)
    }

    @IBAction func saveSelected(sender: AnyObject) {
        // go to the rooT == main page
        // inform the selected video
        
        CameraRollModel.fetchAVAssetAsync(self.playingAsset, handler: { (addAVAsset : AVAsset) -> Void in
            
            dispatch_async(dispatch_get_main_queue(), {
                if let vcStack = self.navigationController?.viewControllers {
                    
                    self.vidPlayerViewController.stopPlaying();
                    
                    var mainScreenVC = vcStack[vcStack.count-3] as MainScreenViewController;
                    mainScreenVC.addMovie(addAVAsset);
                    self.navigationController?.popToViewController(mainScreenVC, animated: true);
                    return;
                } else {
                    println ("saveSelected: failed to get MainScreenViewController")
                }
            })
        })
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}