
import UIKit
import Photos
import CoreMedia;
import QuartzCore;

class VidPlayer: NSObject {
    
    // model of all user's videos
    var cameraModel : CameraRollModel!;
    
    // index of the PHAsset in cameraModel this player is playing.
    var playingModelIndex : Int!
    
    var avPlayerItem : AVPlayerItem!;
    var avPlayer : AVPlayer!
    
    // the UIView that is the parent to this player
    var parentView : UIView
    
    // the QuarzCore layer containing this player, sublayer of parentView.layer
    private var playerLayer : AVPlayerLayer!
    
    // the return value of addBoundaryTimeObserverForTimes:queue:usingBlock:
    var avPlayerTimeObserverId : AnyObject!

    init(parentView : UIView, cameraModel : CameraRollModel){
        self.parentView = parentView;
        self.cameraModel = cameraModel;
        super.init()
        self.instalAVPlayerToViewHierarchie();
    }
    
    deinit {
        self.deinstalAVPlayerFromViewHierarchie();
    }
    
    private func instalAVPlayerToViewHierarchie() {
        // see https://developer.apple.com/LIBRARY/ios/documentation/AVFoundation/Reference/AVPlayerLayer_Class/index.html#//apple_ref/occ/cl/AVPlayerLayer
        self.avPlayer = AVPlayer();
        var parentLayer : CALayer = self.parentView.layer;
        parentLayer.backgroundColor =  UIColor.orangeColor().CGColor
        
        self.playerLayer = AVPlayerLayer(player: self.avPlayer)
        playerLayer.frame.origin = CGPoint(x: 0, y: 0)
        playerLayer.frame.size = CGSize(width: parentLayer.frame.width, height: parentLayer.frame.height)
        
        playerLayer.backgroundColor = UIColor.blueColor().CGColor
        
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        parentLayer.addSublayer(playerLayer)
    }
    
    private func deinstalAVPlayerFromViewHierarchie() {
        self.playerLayer.removeFromSuperlayer();
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
    
    // this is the play command to be used for PHAsset as included in PHFetchResult array
    // (the user's videos in camera roll).
    func playAsset(assetIndex : Int) {
        self.playingModelIndex = assetIndex;
        
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
    
    // this is the play command to be used for the composite movie
    func playAVComposiiton (composition : AVComposition) {
        var playerItem = AVPlayerItem(asset: composition)
        self.setupAndPlayItem(playerItem);
    }

    private func setupAndPlayItem(item : AVPlayerItem!) {
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
    
    private func playerTimeUpdate(time : CMTime) {
        println("playerTimeUpdate \(CMTimeGetSeconds(time))");
    }
    
    internal func playerItemDidReachEnd(notification : NSNotification!) {
        println("playerItemDidReachEnd");
    }
    
    // we do not use the observer mechanism, method is not used
    internal override func observeValueForKeyPath(keyPath: String!, ofObject object: AnyObject!, change: [NSObject : AnyObject]!, context: UnsafeMutablePointer<Void>) {
        if (keyPath != nil && object != nil) {
            println("observeValueForKeyPath: \(keyPath!), \(object!.description)");
        }
        
        super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context);
    }
}
