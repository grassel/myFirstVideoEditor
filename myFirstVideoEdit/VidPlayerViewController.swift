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

class VidPlayerViewController: UIViewController {

    var playingModelIndex : Int!
    var cameraModel : CameraRollModel!
    var vidPlayer : VidPlayer!;
      
    @IBOutlet weak var avPlayerContainingView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.vidPlayer = VidPlayer(parentView: avPlayerContainingView!, cameraModel: cameraModel)
        self.vidPlayer.playAsset(playingModelIndex);
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.vidPlayer.deinitAVPlayer();
        super.viewWillDisappear(animated)
    }
    

   @IBAction func cancelSelected(sender: AnyObject) {
        // got back to the list of my videos
        self.navigationController?.popViewControllerAnimated(true)
    }

    @IBAction func saveSelected(sender: AnyObject) {
        // go to the roo / main page
        // FIXME inform the selected video
        
  //      if let vcStack = self.navigationController?.viewControllers {
        //    var mainScreenVC = vcStack[vcStack.count-2] as MainScreenViewController;
        //    mainScreenVC.addMovie(..)
            
//self.cameraModel[self.playingModelIndex]
            
        //    self.navigationController?.popToViewController(mainScreenVC, animated: true);
 //       }
        
       self.navigationController?.popToRootViewControllerAnimated(true)
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
