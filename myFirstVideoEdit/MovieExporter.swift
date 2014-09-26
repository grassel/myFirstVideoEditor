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
    
    func exportVideoRampInOut(outputPath:String) {
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
                self.myViewcontroller.movieExportCompletedOK(exporter.outputURL);
            }
        })
    }
    
    // FIXME, this currently only works for two videos!
    func exportVideoOneCrossFade(outputPath:String) {
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
                self.myViewcontroller.movieExportCompletedOK(exporter.outputURL);
            }
        })
    }
    
    
    func exportVideoCrossFade(outputPath:String) {
        if (myViewcontroller.model.movieCount < 2) {
            println("at least two movies needed for merging");
            return;
        }
        
        // the duration of a complete fade-in or a fade-out.
        let fadeDurSec = 2.0;
        let fadeDuration : CMTime = CMTimeMakeWithSeconds(fadeDurSec, 1);
        
        // the time two movies overlap == fadeDurSec
        let movieOverlapTimeSec = fadeDurSec;
        let movieOverlapTime : CMTime = CMTimeMakeWithSeconds(movieOverlapTimeSec, 1);
        
        // the cumulative startTime of the given track (clip)
        var trackStartTimes = [CMTime]();
        
        // passthrough is the temporal portion of the track that is not involved in a transition
        // ie. it can just be 'copied' when co,posing the final movie
        // each track has one passthrough time range in its middle part
        var passthroughTimeranges = [CMTimeRange]();
        
        // the time range at the end of a track when transitioning to the next clip.
        // for the ending clip these are the last 'fadeDurSec' secs, for the starting clip
        // these are the first 'fadeDurSec' secs, i.e. the time the two tracks temporarily overlap 
        // in the compoition.
        // note, the last track has no !
        var transitionTimeranges = [CMTimeRange]();
        
        var trackStartTime = kCMTimeZero
        var trackStartTimeSec = CMTimeGetSeconds(trackStartTime);
        
        var trackEndTime : CMTime = trackStartTime;
        
        // 1. step: compute times and populate above data structures with values.
        for index in 0 ... myViewcontroller.model.movieCount-1 {
            let moviePathUrl = myViewcontroller.model.movieUrlAt(index)
            let sourceAsset = AVURLAsset(URL: moviePathUrl, options: nil)

            trackStartTimes.append(trackStartTime);

            trackEndTime = CMTimeAdd(trackStartTime, sourceAsset.duration)
            var fadeOutStartTime : CMTime!
            if (index == myViewcontroller.model.movieCount-1) {
                fadeOutStartTime = trackEndTime; // no fade out
            } else {
                fadeOutStartTime = CMTimeSubtract(trackEndTime, fadeDuration)
            }
            transitionTimeranges.append(CMTimeRangeMake(fadeOutStartTime, fadeDuration));
            
            var fadeInEndTime : CMTime! = trackStartTime;
            var passthroughDuration = sourceAsset.duration
            if (index==0) {
                fadeInEndTime = trackStartTime; // there is no fade in for the first track
            } else {
                fadeInEndTime = CMTimeAdd(trackStartTime, fadeDuration);
                passthroughDuration = CMTimeSubtract(passthroughDuration, fadeDuration);
            }
            if (index < myViewcontroller.model.movieCount-1) {
                // the last clip has no fade out
                passthroughDuration = CMTimeSubtract(passthroughDuration, fadeDuration);
            }
            passthroughTimeranges.append(CMTimeRangeMake(fadeInEndTime, passthroughDuration));
            
            println ("track starts at \(CMTimeGetSeconds(trackStartTime)), ends at \(CMTimeGetSeconds(trackEndTime))");
            println (".... passthrough starts at \(CMTimeGetSeconds(fadeInEndTime)), duration \(CMTimeGetSeconds(passthroughDuration))");
            println (".... transition to next starts at \(CMTimeGetSeconds(fadeOutStartTime)), duration \(CMTimeGetSeconds(fadeDuration))");
            
            // start time of the next movie clip is the duration of previous clip minus the
            // time the clips overlap.
            trackStartTime = CMTimeSubtract(trackEndTime, movieOverlapTime);
            // non ovelap startTime = endTime;
        }
        var compositeDuration : CMTime  = CMTimeSubtract(trackEndTime, trackStartTimes[0]);
        println ("compositeDuration \(CMTimeGetSeconds(compositeDuration))");
        
        
        // 'composition': the final composition, consisting of video and audio track.
        var composition = AVMutableComposition()
        
        // 2nd step: put clips to temporal order:
        //   create and populate two audio and two video tracks.
        //   put clips to alternating tracks, clips overlap by fadeDuration
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
                trackVideos[index % 2].insertTimeRange(CMTimeRangeMake(kCMTimeZero,sourceAsset.duration), ofTrack: assetTrack, atTime: trackStartTimes[index], error: nil)
                
                if audios.count > 0 {
                    let assetTrackAudio:AVAssetTrack = audios[0] as AVAssetTrack
                    // same for audio as for video track.
                    trackAudios[index % 2].insertTimeRange(CMTimeRangeMake(kCMTimeZero,sourceAsset.duration), ofTrack: assetTrackAudio, atTime: trackStartTimes[index], error: nil)
                }
            }
        }
        
        // 3rd step: define instructions how to composite video from pre-defined two tracks into one output.
        // one AVMutableVideoComposition object has a list of AVMutableVideoCompositionInstruction objects. 
        // each AVMutableVideoCompositionInstruction defines the compostion for a 'timeRange'. Those time ranges
        // must cover the entire duration of the compositive movie, and they must not overlap each other.
        // Further, AVMutableVideoCompositionInstruction includes a list of AVMutableVideoCompositionLayerInstruction.
        // Exactly one AVMutableVideoCompositionLayerInstruction object is needed per AVMutableCompositionTrack (see 2nd step)
        // so it links the layer to its video track source. Therefore, for passthrough timeRange, only one 
        // AVMutableVideoCompositionLayerInstruction object is needed, and for a cross-fade two such objects refer to the 
        // two clips (and the track they are contained in).
        // opacity animation, transformations are defined on a AVMutableVideoCompositionLayerInstruction object.
        // note that the API only allows defining one opacity-ramp per AVMutableVideoCompositionLayerInstruction object.
        var compositionVideo = AVMutableVideoComposition();
        compositionVideo.renderSize = CGSizeMake(640, 480);  // render to VGA size, note same size in CALayer below!
        compositionVideo.frameDuration = CMTimeMake(1,30); // 30fps
        
        compositionVideo.instructions = [ AVMutableVideoCompositionInstruction ]();
        
        for index in 0 ... myViewcontroller.model.movieCount-1 {
            let moviePathUrl = myViewcontroller.model.movieUrlAt(index)
            let sourceAsset = AVURLAsset(URL: moviePathUrl, options: nil)
            let tracks = sourceAsset.tracksWithMediaType(AVMediaTypeVideo)
            
            if tracks.count > 0 {
                // append the first video and the first audio track to trackVideo / trackAudio
                let assetTrack : AVAssetTrack = tracks[0] as AVAssetTrack
                
                var transform : CGAffineTransform = assetTrack.preferredTransform;
                if (transform.a == 0 && transform.d == 0 && (transform.b == 1.0 || transform.b == -1.0) && (transform.c == 1.0 || transform.c == -1.0)) {
                    println("ERROR: video was shot in portrait mode: \(moviePathUrl)");
                }
                
                // composition instructions for passthrough part of the track first
                var videoCompositionInstructionPassThrough = AVMutableVideoCompositionInstruction();
                videoCompositionInstructionPassThrough.timeRange = passthroughTimeranges[index];
                videoCompositionInstructionPassThrough.layerInstructions = [AVMutableVideoCompositionLayerInstruction]();

                var videoLayerInstruction : AVMutableVideoCompositionLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: trackVideos[index % 2])
                videoLayerInstruction.setTransform(transform, atTime: passthroughTimeranges[index].start);
                videoCompositionInstructionPassThrough.layerInstructions.append (videoLayerInstruction);
                compositionVideo.instructions.append(videoCompositionInstructionPassThrough);
                
                if (index < myViewcontroller.model.movieCount-1) {
                    // composition instructions for transition  next, unless the last track
                    var videoCompositionInstructionTransition = AVMutableVideoCompositionInstruction();
                    videoCompositionInstructionTransition.timeRange = transitionTimeranges[index];
                    videoCompositionInstructionTransition.layerInstructions = [AVMutableVideoCompositionLayerInstruction]();
                    
                    // transition part: layer instructions for the fading out track
                    videoLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: trackVideos[index % 2])
                    videoLayerInstruction.setTransform(transform, atTime: transitionTimeranges[index].start);
                    videoLayerInstruction.setOpacityRampFromStartOpacity(1.0, toEndOpacity: 0.0, timeRange: transitionTimeranges[index])
                    videoCompositionInstructionTransition.layerInstructions.append (videoLayerInstruction);
                    
                    // transition part: layer instructions for the fading in track
                    videoLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: trackVideos[(index+1) % 2])
                    videoLayerInstruction.setTransform(transform, atTime: transitionTimeranges[index].start);
                    videoLayerInstruction.setOpacityRampFromStartOpacity(0.0, toEndOpacity: 1.0, timeRange: transitionTimeranges[index])
                    videoCompositionInstructionTransition.layerInstructions.append (videoLayerInstruction);
                    
                    // finall append to compositionVideo
                    compositionVideo.instructions.append(videoCompositionInstructionTransition);
                }
            }
        }
        
        // 4th step: prepare to export movie
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
                self.myViewcontroller.movieExportCompletedOK(exporter.outputURL);
            }
        })
    }
    
    // ----------------
    
    func exportVideoCrossFadeOpenGL(outputPath:String) {
        if (myViewcontroller.model.movieCount < 2) {
            println("at least two movies needed for merging");
            return;
        }
        
        // the duration of a complete fade-in or a fade-out.
        let fadeDurSec = 2.0;
        let fadeDuration : CMTime = CMTimeMakeWithSeconds(fadeDurSec, 1);
        
        // the time two movies overlap == fadeDurSec
        let movieOverlapTimeSec = fadeDurSec;
        let movieOverlapTime : CMTime = CMTimeMakeWithSeconds(movieOverlapTimeSec, 1);
        
        // the cumulative startTime of the given track (clip)
        var trackStartTimes = [CMTime]();
        
        // passthrough is the temporal portion of the track that is not involved in a transition
        // ie. it can just be 'copied' when co,posing the final movie
        // each track has one passthrough time range in its middle part
        var passthroughTimeranges = [CMTimeRange]();
        
        // the time range at the end of a track when transitioning to the next clip.
        // for the ending clip these are the last 'fadeDurSec' secs, for the starting clip
        // these are the first 'fadeDurSec' secs, i.e. the time the two tracks temporarily overlap
        // in the compoition.
        // note, the last track has no !
        var transitionTimeranges = [CMTimeRange]();
        
        var trackStartTime = kCMTimeZero
        var trackStartTimeSec = CMTimeGetSeconds(trackStartTime);
        
        var trackEndTime : CMTime = trackStartTime;
        
        // 1. step: compute times and populate above data structures with values.
        for index in 0 ... myViewcontroller.model.movieCount-1 {
            let moviePathUrl = myViewcontroller.model.movieUrlAt(index)
            let sourceAsset = AVURLAsset(URL: moviePathUrl, options: nil)
            
            trackStartTimes.append(trackStartTime);
            
            trackEndTime = CMTimeAdd(trackStartTime, sourceAsset.duration)
            var fadeOutStartTime : CMTime!
            if (index == myViewcontroller.model.movieCount-1) {
                fadeOutStartTime = trackEndTime; // no fade out
            } else {
                fadeOutStartTime = CMTimeSubtract(trackEndTime, fadeDuration)
            }
            transitionTimeranges.append(CMTimeRangeMake(fadeOutStartTime, fadeDuration));
            
            var fadeInEndTime : CMTime! = trackStartTime;
            var passthroughDuration = sourceAsset.duration
            if (index==0) {
                fadeInEndTime = trackStartTime; // there is no fade in for the first track
            } else {
                fadeInEndTime = CMTimeAdd(trackStartTime, fadeDuration);
                passthroughDuration = CMTimeSubtract(passthroughDuration, fadeDuration);
            }
            if (index < myViewcontroller.model.movieCount-1) {
                // the last clip has no fade out
                passthroughDuration = CMTimeSubtract(passthroughDuration, fadeDuration);
            }
            passthroughTimeranges.append(CMTimeRangeMake(fadeInEndTime, passthroughDuration));
            
            println ("track starts at \(CMTimeGetSeconds(trackStartTime)), ends at \(CMTimeGetSeconds(trackEndTime))");
            println (".... passthrough starts at \(CMTimeGetSeconds(fadeInEndTime)), duration \(CMTimeGetSeconds(passthroughDuration))");
            println (".... transition to next starts at \(CMTimeGetSeconds(fadeOutStartTime)), duration \(CMTimeGetSeconds(fadeDuration))");
            
            // start time of the next movie clip is the duration of previous clip minus the
            // time the clips overlap.
            trackStartTime = CMTimeSubtract(trackEndTime, movieOverlapTime);
            // non ovelap startTime = endTime;
        }
        var compositeDuration : CMTime  = CMTimeSubtract(trackEndTime, trackStartTimes[0]);
        println ("compositeDuration \(CMTimeGetSeconds(compositeDuration))");
        
        
        // 'composition': the final composition, consisting of video and audio track.
        var composition = AVMutableComposition()
        
        // 2nd step: put clips to temporal order:
        //   create and populate two audio and two video tracks.
        //   put clips to alternating tracks, clips overlap by fadeDuration
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
                trackVideos[index % 2].insertTimeRange(CMTimeRangeMake(kCMTimeZero,sourceAsset.duration), ofTrack: assetTrack, atTime: trackStartTimes[index], error: nil)
                
                if audios.count > 0 {
                    let assetTrackAudio:AVAssetTrack = audios[0] as AVAssetTrack
                    // same for audio as for video track.
                    trackAudios[index % 2].insertTimeRange(CMTimeRangeMake(kCMTimeZero,sourceAsset.duration), ofTrack: assetTrackAudio, atTime: trackStartTimes[index], error: nil)
                }
            }
        }
        
        // 3rd step: define instructions how to composite video from pre-defined two tracks into one output.
        var compositionVideo = AVMutableVideoComposition();
        compositionVideo.renderSize = CGSizeMake(640, 480);  // render to VGA size, note same size in CALayer below!
        compositionVideo.frameDuration = CMTimeMake(1,30); // 30fps
        
        compositionVideo.customVideoCompositorClass = APLCrossDissolveCompositor.self;
        
        compositionVideo.instructions = [ AVMutableVideoCompositionInstruction ]();
        
        for index in 0 ... myViewcontroller.model.movieCount-1 {
            let moviePathUrl = myViewcontroller.model.movieUrlAt(index)
            let sourceAsset = AVURLAsset(URL: moviePathUrl, options: nil)
            let tracks = sourceAsset.tracksWithMediaType(AVMediaTypeVideo)
            
            if tracks.count > 0 {
                // append the first video and the first audio track to trackVideo / trackAudio
                let assetTrack : AVAssetTrack = tracks[0] as AVAssetTrack
                
                var transform : CGAffineTransform = assetTrack.preferredTransform;
                if (transform.a == 0 && transform.d == 0 && (transform.b == 1.0 || transform.b == -1.0) && (transform.c == 1.0 || transform.c == -1.0)) {
                    println("ERROR: video was shot in portrait mode: \(moviePathUrl)");
                }
                
                var videoCompositionInstructionPassThrough =
                APLCustomVideoCompositionInstruction(passThroughTrackID: trackVideos[index % 2].trackID,
                    forTimeRange: passthroughTimeranges[index]);
                compositionVideo.instructions.append(videoCompositionInstructionPassThrough);
                
                if (index < myViewcontroller.model.movieCount-1) {
                    // what is this ?! = trackID is of type Int32, which is a basic type not a class. Int, though, is a class in Swift
                    // Below constructor expects an [NSObject]
                    var trackIDs : [ Int ] = [ Int(trackVideos[0].trackID), Int(trackVideos[1].trackID) ]
                    
                    var videoCompositionInstructionTransition =
                    APLCustomVideoCompositionInstruction(transitionWithSourceTrackIDs: trackIDs, forTimeRange: transitionTimeranges[index]);
                    videoCompositionInstructionTransition.foregroundTrackID = trackVideos[index % 2].trackID;
                    videoCompositionInstructionTransition.backgroundTrackID = trackVideos[1-(index % 2)].trackID;
                    
                    // finally append to compositionVideo
                    compositionVideo.instructions.append(videoCompositionInstructionTransition);
                }
            }
        }
        
        // 4th step: prepare to export movie
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
                self.myViewcontroller.movieExportCompletedOK(exporter.outputURL);
            }
        })
    }

}
