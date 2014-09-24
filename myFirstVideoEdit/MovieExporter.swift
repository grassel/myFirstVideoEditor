//
//  MovieExporter.swift
//  myFirstVideoEdit
//
//  Created by Guido Grassel on 24/09/14.
//  Copyright (c) 2014 Guido Grassel. All rights reserved.
//

import UIKit
import CoreMedia;
import AVFoundation;
import MediaPlayer
import QuartzCore;

class MovieExporter: NSObject {
    var myViewcontroller : MainScreenViewController!;
    
    init(myViewcontroller : MainScreenViewController) {
        self.myViewcontroller = myViewcontroller;
    }
    
    func exportVideo(outputPath:String) {
        if (myViewcontroller.model.movieCount < 2) {
            println("at least two movies needed for merging");
            return;
        }
        
        // the final composition, consisting of a video and an audio track.
        var composition = AVMutableComposition()
        var compositionVideo = AVMutableVideoComposition();
        compositionVideo.instructions = [ AVMutableVideoCompositionInstruction ]();
        compositionVideo.renderSize = CGSizeMake(640, 480);  // render to VGA size, note same size in CALayer below!
        compositionVideo.frameDuration = CMTimeMake(1,30); // 30fps
        let trackVideo:AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID())
        let trackAudio:AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
        
        var insertTime = kCMTimeZero
        var index = 0;
        
        for index in 0 ... myViewcontroller.model.movieCount-1 {
            let moviePathUrl = myViewcontroller.model.movieUrlAt(index)
            let sourceAsset = AVURLAsset(URL: moviePathUrl, options: nil)
            
            let tracks = sourceAsset.tracksWithMediaType(AVMediaTypeVideo)
            let audios = sourceAsset.tracksWithMediaType(AVMediaTypeAudio)
            
            if tracks.count > 0 {
                // append the first video and the first audio track to trackVideo / trackAudio
                let assetTrack : AVAssetTrack = tracks[0] as AVAssetTrack
                trackVideo.insertTimeRange(CMTimeRangeMake(kCMTimeZero,sourceAsset.duration), ofTrack: assetTrack, atTime: insertTime, error: nil)
                
                var transform : CGAffineTransform = assetTrack.preferredTransform;
                if (transform.a == 0 && transform.d == 0 && (transform.b == 1.0 || transform.b == -1.0) && (transform.c == 1.0 || transform.c == -1.0)) {
                    println("ERROR: video was shot in portrait mode: \(moviePathUrl)");
                }
                
                if audios.count > 0 {
                    let assetTrackAudio:AVAssetTrack = audios[0] as AVAssetTrack
                    trackAudio.insertTimeRange(CMTimeRangeMake(kCMTimeZero,sourceAsset.duration), ofTrack: assetTrackAudio, atTime: insertTime, error: nil)
                }
                
                var videoCompositionInstruction : AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction();
                videoCompositionInstruction.timeRange = CMTimeRangeMake(insertTime,sourceAsset.duration);
                
                var videoLayerInstruction : AVMutableVideoCompositionLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: trackVideo)
                videoLayerInstruction.setTransform(assetTrack.preferredTransform, atTime: insertTime);
                
                videoCompositionInstruction.layerInstructions = [ videoLayerInstruction ]
                compositionVideo.instructions.append(videoCompositionInstruction)
                
                println ("video starts at \(CMTimeGetSeconds(insertTime))");
                insertTime = CMTimeAdd(insertTime, sourceAsset.duration)
            }
        }
        
        // Quarz animation parent Layer
        var caRootLayer : CALayer = CALayer();
        let layerRec = CGRect(x: 0.0, y: 0.0, width: 640.0, height: 480.0)
        caRootLayer.frame = layerRec;
        var caParentLayer = caRootLayer;
        
        // Quarz animation / fade-in transformation
        var caVideoFadeInLayer : CALayer = CALayer();
        caVideoFadeInLayer.frame = layerRec
        
        var animationFadeIn : CABasicAnimation = CABasicAnimation(keyPath: "opacity");
        animationFadeIn.duration=2.0;
        animationFadeIn.repeatCount=1;
        animationFadeIn.autoreverses=false;
        
        animationFadeIn.fromValue=0.0
        animationFadeIn.toValue=1.0
        animationFadeIn.beginTime = AVCoreAnimationBeginTimeAtZero;
        
        println("animationFadeIn.beginTime \(animationFadeIn.beginTime)");
        
        caVideoFadeInLayer.addAnimation(animationFadeIn, forKey: "fadeIn")
        caParentLayer.addSublayer(caVideoFadeInLayer)
        caParentLayer = caVideoFadeInLayer;
        
        // Quarz animation / fade-in transformation
        var caVideoFadeOutLayer : CALayer = CALayer();
        caVideoFadeOutLayer.frame = layerRec
        
        var animationFadeOut : CABasicAnimation = CABasicAnimation(keyPath: "opacity");
        animationFadeOut.duration=2.0;
        animationFadeOut.repeatCount=1;
        animationFadeOut.autoreverses=false;
        
        animationFadeOut.fromValue=1.0
        animationFadeOut.toValue=0.0
        animationFadeOut.beginTime = CMTimeGetSeconds(insertTime) - animationFadeOut.duration;
        
        caVideoFadeOutLayer.addAnimation(animationFadeOut, forKey: "fadeOut")
        caParentLayer.addSublayer(caVideoFadeOutLayer)
        caParentLayer = caVideoFadeOutLayer;
        
        // using the CA Layers to transform the video, this is where iOS does all the magic!
        // Note: it appears, to chain transformations, one needs to build a chain of layers (by using addSubLayer(childLayer)
        // use the most senior parent to inLayer, and the youngest layer as postProcessingAsVideoLayer) in below call.
        compositionVideo.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: caParentLayer, inLayer: caRootLayer);
        
        // prepare to export movie
        let guid = NSProcessInfo.processInfo().globallyUniqueString
        let completeMovie = outputPath.stringByAppendingPathComponent(guid + "--generated-movie.mov")
        let completeMovieUrl = NSURL(fileURLWithPath: completeMovie)
        
        var exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        exporter.videoComposition = compositionVideo;
        exporter.outputURL = completeMovieUrl
        exporter.outputFileType = AVFileTypeMPEG4   //AVFileTypeQuickTimeMovie
        
        
        exporter.exportAsynchronouslyWithCompletionHandler({
            // this handler gets called in a background thread!
            switch exporter.status
                {
            case  AVAssetExportSessionStatus.Failed:
                println("failed url=\(exporter.outputURL), error=\(exporter.error)")
                return;
            case AVAssetExportSessionStatus.Cancelled:
                println("cancelled \(exporter.error)")
                return;
            default:
                println("complete")
            }
            
            NSOperationQueue.mainQueue().addOperationWithBlock(){
                self.myViewcontroller.playMovie(exporter.outputURL);
            }
        })
    }
}
