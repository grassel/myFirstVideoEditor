
import UIKit
import Photos
import CoreMedia;
import QuartzCore;

class VidPlayer: NSObject {
    
    
    init(viewController: VidPlayerController){
        self.vc = viewController;
        super.init()
        self.instalAVPlayerToViewHierarchie();
    }
    
    deinit {
        self.deinstalAVPlayerFromViewHierarchie();
    }
    
    private func instalAVPlayerToViewHierarchie() {
        // see https://developer.apple.com/LIBRARY/ios/documentation/AVFoundation/Reference/AVPlayerLayer_Class/index.html#//apple_ref/occ/cl/AVPlayerLayer
        self.avPlayer = AVPlayer();
        var parentLayer : CALayer = self.vc.getView().layer
        parentLayer.backgroundColor =  UIColor.blackColor().CGColor
        
        self.playerLayer = AVPlayerLayer(player: self.avPlayer)
        var rect = self.vc.playerRect()
        playerLayer.frame.origin = rect.origin
        playerLayer.frame.size = rect.size
        playerLayer.backgroundColor = UIColor.blackColor().CGColor
        
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        parentLayer.addSublayer(playerLayer)
    }
    
    func deinstalAVPlayerFromViewHierarchie() {
        self.playerLayer?.removeFromSuperlayer();
        self.playerLayer = nil;
        self.avPlayer = nil;
    }
    
    
    func play (phasset asset: PHAsset) {
        CameraRollModel.fetchAssetFullAsync(asset, reference: 0, handler: { (indexBack : Int, avPlayerItemBack : AVPlayerItem!) -> Void in
            if (avPlayerItemBack == nil) {
                println("prepareToPlayAsset: failed to fetch playerItem, bailing out");
                return;
            }
            dispatch_async(dispatch_get_main_queue(), {
                self.setupAndPlayItem(avPlayerItemBack)
            });
        });
    }
    
    // this is the play command to be used for the composite movie
    func play (avcomposition composition : AVComposition, avvideocomposition: AVVideoComposition) {
        var playerItem : AVPlayerItem = AVPlayerItem(asset: composition)
        playerItem.videoComposition = avvideocomposition;
        
        self.setupAndPlayItem(playerItem);
    }
    
    private func setupAndPlayItem(item : AVPlayerItem!) {
        if (item == nil) {
            println("setupAndPlayItem item is nil. Ignoring");
            return;
        }
        
        if (self.avPlayerItem  != nil) {
            // we have a previous playerItem, for which we need to unregister as an observer
            self.stopPlaying();
        }
        
        self.avPlayerItem = item!;
        self.avPlayer!.replaceCurrentItemWithPlayerItem(self.avPlayerItem)

        self.avPlayerItem.seekingWaitsForVideoCompositionRendering = true;

        var notifCtr = NSNotificationCenter.defaultCenter();
        notifCtr.addObserverForName(AVPlayerItemDidPlayToEndTimeNotification, object: self.avPlayerItem, queue: NSOperationQueue.mainQueue(), usingBlock: self.playerItemDidReachEnd)
        
        println ("playeritem duration: \(CMTimeGetSeconds(self.avPlayerItem.duration)) ");
        if (self.avPlayerItem.status != AVPlayerItemStatus.ReadyToPlay) {
            println ("playeritem not ready to play!");
        }
        
        self.avPlayer!.seekToTime(kCMTimeZero)
        
        self.avPlayerTimeObserverId = self.avPlayer.addPeriodicTimeObserverForInterval(CMTimeMake(5, 25) /* 30fps */, queue: nil, usingBlock: self.playerTimeUpdate)
        
        self.avPlayerItem.addObserver(self, forKeyPath: "status", options: nil, context: nil)
        // wait for the observed status to become readToPlay: self.avPlayer!.play()
    }
    
    
    func stopPlaying() {
        if (self.avPlayer == nil) {
            return;
        }
        self.avPlayer.pause()
        unregisterObservers()
    }

    func pausePlaying() {
        self.avPlayer.pause()
    }
    
    func resumePlaying() {
        self.avPlayer.play()
    }
    
    func seekPlaying(newTemporalPosition : Float64) {
        self.avPlayer.seekToTime(CMTimeMakeWithSeconds(newTemporalPosition, 30))
    }
    
    private func unregisterObservers() {
        var notifCtr = NSNotificationCenter.defaultCenter();
        if (self.avPlayerItem != nil) {
            self.avPlayerItem.removeObserver(self, forKeyPath: "status")
            NSNotificationCenter.defaultCenter().removeObserver(self.avPlayerItem)
            self.avPlayerItem = nil
        }
        if (self.avPlayer != nil && self.avPlayerTimeObserverId != nil) {
            self.avPlayer.removeTimeObserver(self.avPlayerTimeObserverId)
            self.avPlayerTimeObserverId = nil;
        }
    }
    
    
    
    private func playerTimeUpdate(time : CMTime) {
        println("playerTimeUpdate \(CMTimeGetSeconds(time))");
        self.vc.playerTemporalPosition = CMTimeGetSeconds(time);
    }
    
    
    internal func playerItemDidReachEnd(notification : NSNotification!) {
        println("playerItemDidReachEnd, rewining and playing again.");
        self.vc.looped?()
        self.vc.playerProgressUpdate?(0.0)
        self.avPlayer.seekToTime(kCMTimeZero)
        self.avPlayer.play()
    }
    
    // we do not use the observer mechanism, method is not used
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if (keyPath == "status" && ((object as NSObject) == self.avPlayerItem)) {
            if (self.avPlayerItem.status == AVPlayerItemStatus.ReadyToPlay) {
                // ready to play
                println("VidPlayer: PlayerItem ready to play");
                self.vc.readyToPlay?(CMTimeGetSeconds(self.avPlayerItem.duration))
                if self.vc.autoStartOnPlay == true {
                    self.vc.startedPlaying?()
                    self.avPlayer!.play()
                }
            } else {
                self.vc.stoppedPlaying?();
            }
        } else {
            println("VidPlayer: observeValueForKeyPath unexpected object / keyPath=\(keyPath)")
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context);
        }
    }
    
    
    var avPlayerItem : AVPlayerItem!;
    var avPlayer : AVPlayer!
    
    // the UIView that is the parent to this player
    var vc : VidPlayerController!
    
    // the QuarzCore layer containing this player, sublayer of parentView.layer
    private var playerLayer : AVPlayerLayer!
    
    // the return value of addBoundaryTimeObserverForTimes:queue:usingBlock:
    var avPlayerTimeObserverId : AnyObject!
}
