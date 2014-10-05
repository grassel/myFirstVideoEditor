//
//  VidPlayerViewController.swift
//  myFirstVideoEdit
//
//  Created by Guido Grassel on 04/10/14.
//  Copyright (c) 2014 Guido Grassel. All rights reserved.
//

import UIKit
import Photos

class VidPlayerViewController: UIViewController, VidPlayerController {
    
    init (myView : UIView) {
        super.init();
        self.view = myView;
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        println ("VidPlayerViewController nibName init called")
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        // NOP
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.vidPlayer = VidPlayer(viewController: self)
        
        self.playButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
         self.playButton.frame = CGRect(x: 5, y: self.view.frame.height-50, width: 50, height: 30);
     //   playButton.imageView?.image = UIImage(named: "PlayButtonImage")
     //   playButton.setBackgroundImage(UIImage(named: "PlayButtonImage"), forState: UIControlState.Normal)
     //   playButton.setBackgroundImage(UIImage(named: "PlayButtonImage"), forState: UIControlState.Disabled)
        playButton.titleLabel?.text =  "Play";
        playButton.userInteractionEnabled = true;
        playButton.enabled = false;
        playButton.addTarget(self, action: Selector("buttonTouchUpInside:"), forControlEvents: UIControlEvents.TouchUpInside)
        
        self.videoTemporalPositionSlider = UISlider(frame: CGRect(x: 70, y: self.view.frame.height-50, width: self.view.frame.width-70, height: 30));
        videoTemporalPositionSlider.maximumValue = 100;
        videoTemporalPositionSlider.minimumValue = 0;
        videoTemporalPositionSlider.continuous = true;
        videoTemporalPositionSlider.userInteractionEnabled = true;
        var swipeDragRecognizer : UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: Selector("handleSwipeDrag:"));
        swipeDragRecognizer.direction = UISwipeGestureRecognizerDirection.Left;
        videoTemporalPositionSlider.addGestureRecognizer(swipeDragRecognizer);
        
        swipeDragRecognizer = UISwipeGestureRecognizer(target: self, action: Selector("handleSwipeDrag:"))
        swipeDragRecognizer.direction = UISwipeGestureRecognizerDirection.Right;
        videoTemporalPositionSlider.addGestureRecognizer(swipeDragRecognizer);
        
        videoTemporalPositionSlider.addTarget(self, action: Selector("sliderMoveStart:"), forControlEvents: UIControlEvents.TouchDown)
        videoTemporalPositionSlider.addTarget(self, action: Selector("sliderMoveEnd:"), forControlEvents: UIControlEvents.TouchCancel)
        videoTemporalPositionSlider.addTarget(self, action: Selector("sliderMoveEnd:"), forControlEvents: UIControlEvents.TouchUpOutside)
        videoTemporalPositionSlider.addTarget(self, action: Selector("sliderMoveEnd:"), forControlEvents: UIControlEvents.TouchCancel)
        
        self.view.addSubview(videoTemporalPositionSlider);
        self.view.addSubview(playButton);
    }
    
    override func viewWillDisappear(animated: Bool) {
        if (self.vidPlayer != nil) {
            self.videoTemporalPositionSlider?.removeFromSuperview()
            self.videoTemporalPositionSlider?.removeTarget(self, action: Selector("sliderMoveStart:"), forControlEvents: UIControlEvents.TouchDown)
            self.videoTemporalPositionSlider?.removeTarget(self, action: Selector("sliderMoveEnd:"), forControlEvents: UIControlEvents.TouchUpInside)
            self.videoTemporalPositionSlider?.removeTarget(self, action: Selector("sliderMoveEnd:"), forControlEvents: UIControlEvents.TouchUpOutside)
            self.videoTemporalPositionSlider?.removeTarget(self, action: Selector("sliderMoveEnd:"), forControlEvents: UIControlEvents.TouchCancel)

            videoTemporalPositionSlider?.removeFromSuperview()
            self.videoTemporalPositionSlider = nil;

            playButton?.removeTarget(self, action: Selector("buttonTouchUpInside:"), forControlEvents: UIControlEvents.TouchUpInside)
            playButton?.removeFromSuperview()
            self.playButton = nil;
            
            self.stopPlaying();
            self.vidPlayer.deinstalAVPlayerFromViewHierarchie();
            self.vidPlayer = nil;  // get rid of the VidPlayer object
        }
    }
    
     func play (phasset asset: PHAsset) {
        self.vidPlayer.play(phasset: asset);
    }
    
    func play (avcomposition composition : AVComposition, avvideocomposition: AVVideoComposition) {
        self.vidPlayer.play(avcomposition: composition, avvideocomposition: avvideocomposition)
    }
    
    func pausePlaying() {
        if (self.videoReadyToPlay) {
            self.vidPlayer.pausePlaying()
            isVideoPlaying = false;
        }
    }
    
    func resumePlaying() {
        if (self.videoReadyToPlay) {
            self.vidPlayer.resumePlaying()
            isVideoPlaying = true
        }
    }
    
    func stopPlaying() {
        self.vidPlayer.stopPlaying()
        isVideoPlaying = false;
        videoReadyToPlay = false;
    }
    

    
    // VidPlayerController protocol
    // returns the UIView into which the player anchors
    func getView() -> UIView {
        return self.view;
    }
    
    // VidPlayerController protocol
    // the player frame position and dimension
    func playerRect() -> CGRect {
        return CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height-50)
    }
    
    // VidPlayerController protocol
    // note: play(..) is asynchronous, this delegate method informs that the async
    // processing has been completed OK,
    // AVPlayer/Item ready, e.g. content has been rendered / loaded
    func readyToPlay(movieDuration : Float64) {
        playDuration = movieDuration
        videoReadyToPlay = true;
    }
    
    // VidPlayerController protocol
    // the player started to play
    func startedPlaying() {
        isVideoPlaying = true;
    }
    
    // VidPlayer stopped playing.
    // not called when the VC called stop
    func stoppedPlaying() {
        isVideoPlaying = false;
    }
    
    // VidPlayerController protocol
    var playerTemporalPosition : Float64 = 0.0 {
        didSet {
            if !isScrubbing {
                // don't update the slider position if the user is scrubbing and the video temp position update
                // comes in response to the caused seek.
                self.videoTemporalPositionSlider?.value = Float(self.playerTemporalPosition);
                println ("\(playerTemporalPosition), slider position updated")
            } else {
                println ("\(playerTemporalPosition), slider position untouched")
            }
        }
    }
    
    var autoStartOnPlay : Bool = false;
    
    // properties and observation code
    // only available when videoReadyToPlay
    var playDuration : Float64  = 100.0 {
        didSet {
            self.videoTemporalPositionSlider?.maximumValue = Float(self.playDuration);
        }
    }
    
    // don't set this property to true unless videoReadyToPlay
    var isVideoPlaying : Bool = false {
        didSet {
          //  self.playButton?.imageView?.image = self.isVideoPlaying ? UIImage(named: "PauseButtonImage") : UIImage(named: "PlayButtonImage")
            self.playButton?.titleLabel?.text = self.isVideoPlaying ? "Pause" : "Play";
        }
    }
    
    // prerequisite to pause/resume.
    var videoReadyToPlay : Bool = false {
        didSet {
            self.playButton?.enabled = videoReadyToPlay;
            isVideoPlaying = isVideoPlaying && videoReadyToPlay;
        }
    }

    var wasPlayingWhenScrubbingStarted = false;
    var isScrubbing = false;
    
    // pause/resume button
    func buttonTouchUpInside(sender : UIButton) {
        if (self.videoReadyToPlay) {
            if (self.isVideoPlaying) {
                self.pausePlaying()
            } else {
                self.resumePlaying()
            }
        }
    }
    
    // called when user starts the interact with the slider
    // 'scrubbing' starts
    func sliderMoveStart(sender : UISlider) {
        if (videoReadyToPlay) {
            println ("sliderMoveStart");
             // remember if video was playing when scrubbing started, so to resume upon scrubbing ends.
            wasPlayingWhenScrubbingStarted = self.isVideoPlaying;
            self.pausePlaying();
            isScrubbing = true;
        }
    }
    
    // called when user starts the interact with the slider
    // 'scrubbing' ends
    func sliderMoveEnd(sender : UISlider) {
        if (videoReadyToPlay) {
            println ("sliderMoveEnd, new slider value: \(self.videoTemporalPositionSlider.value)");
            self.vidPlayer.seekPlaying(Float64(self.videoTemporalPositionSlider.value));
            isScrubbing = false;
            if (self.wasPlayingWhenScrubbingStarted) {
                self.resumePlaying();
            }
        }
    }
    
    // delivers continuous updates while user drags the slider
    // 'scrubbing'.
    func handleSwipeDrag(sender : UIGestureRecognizer) {
        if (videoReadyToPlay) {
            println ("handleSwipeDrag, new slider value: \(self.videoTemporalPositionSlider.value)");
            self.vidPlayer.seekPlaying(Float64(self.videoTemporalPositionSlider.value));
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var playButton : UIButton!;
    var videoTemporalPositionSlider : UISlider!;
    var vidPlayer : VidPlayer!;
}
