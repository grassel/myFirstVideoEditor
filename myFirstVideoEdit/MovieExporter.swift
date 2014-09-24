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
    
    
    func exportVideoCrossFade(outputPath:String) {
        if (myViewcontroller.model.movieCount < 2) {
            println("at least two movies needed for merging");
            return;
        }
        
        // the duration of a complete fade-in or a fade-out.
        let fadeDurSec = 1.0;
        let fadeDuration : CMTime = CMTimeMakeWithSeconds(fadeDurSec, 1);
        
        // the time two movies overlap == fadeDurSec
        let movieOverlapTimeSec = fadeDurSec;
        let movieOverlapTime : CMTime = CMTimeMakeWithSeconds(movieOverlapTimeSec, 1);
        
        var startTimes = [CMTime]();
        var fadeOutStartTimes = [CMTime]();
        
        var startTime = kCMTimeZero
        var startTimeSec = CMTimeGetSeconds(startTime);
        
        var endTime : CMTime = startTime;
        
        for index in 0 ... myViewcontroller.model.movieCount-1 {
            let moviePathUrl = myViewcontroller.model.movieUrlAt(index)
            let sourceAsset = AVURLAsset(URL: moviePathUrl, options: nil)
            
            endTime = CMTimeAdd(startTime, sourceAsset.duration)
            let fadeOutStartTime = CMTimeSubtract(endTime, fadeDuration)
            startTimes.append(startTime);
            fadeOutStartTimes.append(fadeOutStartTime);
            
            println ("video starts at \(CMTimeGetSeconds(startTime)), fadeOut starts at\(CMTimeGetSeconds(fadeOutStartTime)), video ends at \(CMTimeGetSeconds(endTime))");
            
            // start time of the next movie clip is the duration of previous clip minus the
            // time the clips overlap.
            startTime = CMTimeSubtract(endTime, movieOverlapTime);
            // non ovelap startTime = endTime;
        }
        var compositeDuration : CMTime  = CMTimeSubtract(endTime, startTimes[0]);
        println ("compositeDuration \(CMTimeGetSeconds(compositeDuration))");
        
        
        // the final composition, consisting of a video and an audio track.
        var composition = AVMutableComposition()
        
        // two tracks for audio and for video needed for cross fade
        var trackVideos = [AVMutableCompositionTrack]();
        trackVideos.append(composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID()))
        trackVideos.append(composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID()))
        
        var trackAudios = [AVMutableCompositionTrack]();
        trackAudios.append(composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID()))
        trackAudios.append(composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID()))
        
        for index in 0 ... myViewcontroller.model.movieCount-1 {
            let moviePathUrl = myViewcontroller.model.movieUrlAt(index)
            let sourceAsset = AVURLAsset(URL: moviePathUrl, options: nil)
            
            let tracks = sourceAsset.tracksWithMediaType(AVMediaTypeVideo)
            let audios = sourceAsset.tracksWithMediaType(AVMediaTypeAudio)
            
            if tracks.count > 0 {
                // append the first video and the first audio track to alternating trackVideo / trackAudio
                let assetTrack : AVAssetTrack = tracks[0] as AVAssetTrack
                // insert the entire (start to end) movie clip video track at computed start-time
                trackVideos[index % 2].insertTimeRange(CMTimeRangeMake(kCMTimeZero,sourceAsset.duration), ofTrack: assetTrack, atTime: startTimes[index], error: nil)
                
                if audios.count > 0 {
                    let assetTrackAudio:AVAssetTrack = audios[0] as AVAssetTrack
                    // same for audio as for video track.
                    trackAudios[index % 2].insertTimeRange(CMTimeRangeMake(kCMTimeZero,sourceAsset.duration), ofTrack: assetTrackAudio, atTime: startTimes[index], error: nil)
                }
            }
        }
        
        
        // instructions how to composite the video tracks together (the composite could also do other things, like overlaying images, masks, but we don't do this here
        var compositionVideo = AVMutableVideoComposition();
        compositionVideo.renderSize = CGSizeMake(640, 480);  // render to VGA size, note same size in CALayer below!
        compositionVideo.frameDuration = CMTimeMake(1,30); // 30fps
        
        compositionVideo.instructions = [ AVMutableVideoCompositionInstruction ]();
        var videoCompositionInstruction = AVMutableVideoCompositionInstruction();
        videoCompositionInstruction.timeRange = CMTimeRangeMake(startTimes[0], compositeDuration);
        videoCompositionInstruction.layerInstructions = [AVMutableVideoCompositionLayerInstruction](); // will add a layer instruction per video clip.
        
        for index in 0 ... myViewcontroller.model.movieCount-1 {
            let moviePathUrl = myViewcontroller.model.movieUrlAt(index)
            let sourceAsset = AVURLAsset(URL: moviePathUrl, options: nil)
            let tracks = sourceAsset.tracksWithMediaType(AVMediaTypeVideo)
            
            var startTime = startTimes[index];
            var fadeOutStartTime = fadeOutStartTimes[index];
            
            if tracks.count > 0 {
                // append the first video and the first audio track to trackVideo / trackAudio
                let assetTrack : AVAssetTrack = tracks[0] as AVAssetTrack
                
                var transform : CGAffineTransform = assetTrack.preferredTransform;
                if (transform.a == 0 && transform.d == 0 && (transform.b == 1.0 || transform.b == -1.0) && (transform.c == 1.0 || transform.c == -1.0)) {
                    println("ERROR: video was shot in portrait mode: \(moviePathUrl)");
                }
                
                var videoLayerInstruction : AVMutableVideoCompositionLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: trackVideos[index % 2])
                videoLayerInstruction.setTransform(transform, atTime: startTime);
                if (index == 0) {
                    // first video opacity ramp up
                    videoLayerInstruction.setOpacityRampFromStartOpacity(1.0, toEndOpacity: 0.0, timeRange: CMTimeRangeMake(fadeOutStartTime, fadeDuration))
                } else if (index == 1) {
                    // first video opacity ramp down
                    videoLayerInstruction.setOpacityRampFromStartOpacity(0.0, toEndOpacity: 1.0, timeRange: CMTimeRangeMake(startTime, fadeDuration))
                }
                videoCompositionInstruction.layerInstructions.append (videoLayerInstruction);
            }
        }
        compositionVideo.instructions.append(videoCompositionInstruction)
        
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
