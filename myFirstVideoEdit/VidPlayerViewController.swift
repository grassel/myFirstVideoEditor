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
    
    var avPlayerItem : AVPlayerItem!;
    var avPlayer : AVPlayer!
    
    // the return value of addBoundaryTimeObserverForTimes:queue:usingBlock:
    var avPlayerTimeObserverId : AnyObject!
    
    @IBOutlet weak var avPlayerContainingView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        instalAVPlayerToViewHierarchie();
        playAsset();
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.deinitAVPlayer();
        super.viewWillDisappear(animated)
    }
    
    func instalAVPlayerToViewHierarchie() {
        // see https://developer.apple.com/LIBRARY/ios/documentation/AVFoundation/Reference/AVPlayerLayer_Class/index.html#//apple_ref/occ/cl/AVPlayerLayer
        self.avPlayer = AVPlayer();
        var parentLayer : CALayer = self.avPlayerContainingView.layer;
        parentLayer.backgroundColor =  UIColor.orangeColor().CGColor
        
        var playerLayer : AVPlayerLayer = AVPlayerLayer(player: self.avPlayer)
        playerLayer.frame.origin = CGPoint(x: 0, y: 0)
        playerLayer.frame.size = CGSize(width: parentLayer.frame.width, height: parentLayer.frame.height)
        
        playerLayer.backgroundColor = UIColor.blueColor().CGColor
        
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        parentLayer.addSublayer(playerLayer)
    }
    
    func deinitAVPlayer() {
        if (self.avPlayer == nil) {
            return;
        }
        self.avPlayer.pause()
        
        // unregister for notifications
        var notifCtr = NSNotificationCenter.defaultCenter();
        if (self.avPlayerItem != nil) {
            notifCtr.removeObserver(self.avPlayerItem)
        }
        self.avPlayer.removeTimeObserver(self.avPlayerTimeObserverId)
    }
    
    func playAsset() {
        if (playingModelIndex == nil || cameraModel == nil) {
            println("prepareToPlayAsset: playingModelIndex or cameeraModel unset. Bailing out");
            return;
        }
        
        cameraModel!.fetchAssetFullAsync(playingModelIndex!, handler: { (indexBack : Int, avPlayerItemBack : AVPlayerItem!) -> Void in
            if (avPlayerItemBack == nil) {
                println("prepareToPlayAsset: failed to fetch playerItem Bailing out");
                return;
            }
            dispatch_async(dispatch_get_main_queue(), {
                self.setupAndPlayItem(avPlayerItemBack)
            });
        });
    }
    
    func setupAndPlayItem(item : AVPlayerItem!) {
        if (item == nil) {
            println("setupAndPlayerItem item is nil. Ignoring");
            return;
        }
        self.avPlayerItem = item!;
        self.avPlayer!.replaceCurrentItemWithPlayerItem(self.avPlayerItem)
        
        var notifCtr = NSNotificationCenter.defaultCenter();
        notifCtr.addObserverForName(AVPlayerItemDidPlayToEndTimeNotification, object: self.avPlayerItem, queue: NSOperationQueue.mainQueue(), usingBlock: self.playerItemDidReachEnd)
        
        self.avPlayer!.seekToTime(kCMTimeZero);
        self.avPlayerTimeObserverId = self.avPlayer.addPeriodicTimeObserverForInterval(CMTimeMake(5, 25) /* 30fps */, queue: nil, usingBlock: self.playerTimeUpdate)
        
        self.avPlayer!.play()
    }
    
    func playerTimeUpdate(time : CMTime) {
        println("playerTimeUpdate \(CMTimeGetSeconds(time))");
    }
    
    func playerItemDidReachEnd(notification : NSNotification!) {
        println("playerItemDidReachEnd");
    }
    
    // we do not use the observer mechanism, method is not used
    override func observeValueForKeyPath(keyPath: String!, ofObject object: AnyObject!, change: [NSObject : AnyObject]!, context: UnsafeMutablePointer<Void>) {
        if (keyPath != nil && object != nil) {
            println("observeValueForKeyPath: \(keyPath!), \(object!.description)");
        }
        
        super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context);
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
