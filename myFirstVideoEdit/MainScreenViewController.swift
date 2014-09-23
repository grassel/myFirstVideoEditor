//
//  ViewController.swift
//  myFirstVideoEdit
//
//  Created by Guido Grassel on 22/09/14.
//  Copyright (c) 2014 Guido Grassel. All rights reserved.
//

import UIKit
import AVFoundation;
import MediaPlayer
import CoreMedia;
import QuartzCore;

class MainScreenViewController: UIViewController,  UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var movieThumbImage1: UIImageView!
    @IBOutlet weak var movieThumbImage2: UIImageView!
    @IBOutlet weak var movieThumbImage3: UIImageView!
    @IBOutlet weak var movieThumbImage4: UIImageView!
    
    @IBOutlet weak var viewForMovie: UIView!
    @IBOutlet weak var waitIndicator: UIActivityIndicatorView!
    
    var movieThumbsImageViews : [UIImageView] = [UIImageView]();
    var movieThumbsImages : [UIImage] = [UIImage]();
    var movieUrls : [NSURL] = [NSURL]();
    
    var movieCount = 0;
    let movieCountMax = 4;
    
    var moviePlayer:MPMoviePlayerController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        movieThumbsImageViews = [
            movieThumbImage1!, movieThumbImage2!, movieThumbImage3!, movieThumbImage4!
        ];
        movieThumbsImages = [UIImage](count: 4, repeatedValue: UIImage());
        movieUrls = [NSURL](count: 4, repeatedValue: NSURL());
        
        self.moviePlayer = MPMoviePlayerController();
        self.moviePlayer.view.frame = viewForMovie.bounds;
        self.moviePlayer.view.autoresizingMask =
              	           UIViewAutoresizing.FlexibleWidth |
              	           UIViewAutoresizing.FlexibleHeight;
        moviePlayer.fullscreen = false;
        moviePlayer.controlStyle = MPMovieControlStyle.Embedded; // Controls for an embedded view are displayed. The controls include a start/pause button, a scrubber bar, and a button for toggling between fullscreen and embedded display modes.

        self.viewForMovie.addSubview(self.moviePlayer.view)
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
        var originalMediaUrl = info[UIImagePickerControllerMediaURL] as? NSURL;
        var editedMediaUrl = info[UIImagePickerControllerReferenceURL] as? NSURL;
        println("editedMediaUrl: \(editedMediaUrl), originalMediaUrl: \(originalMediaUrl)");
        picker.dismissViewControllerAnimated(true, completion: { var p = editedMediaUrl; self.addMovie(editedMediaUrl!) } )
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        println("user cancelled picking");
        picker.dismissViewControllerAnimated(true, completion: nil)
    }

    func addMovie(editedMediaUrl : NSURL) {
        if movieCount < movieCountMax {
            movieUrls[movieCount] = editedMediaUrl;
            movieThumbsImages[movieCount] = generateThumb(editedMediaUrl);
            movieThumbsImageViews[movieCount].image  =  movieThumbsImages[movieCount];
            movieCount++;
        }
    }
    
    func generateThumb(movieUrl : NSURL) -> UIImage {
        // http://stackoverflow.com/questions/19105721/thumbnailimageattime-now-deprecated-whats-the-alternative
        var asset : AVURLAsset = AVURLAsset (URL: movieUrl, options: nil);
        var generator : AVAssetImageGenerator = AVAssetImageGenerator(asset: asset);
        generator.appliesPreferredTrackTransform = true;
        var time : CMTime = CMTimeMake(1,2);
        var oneRef : CGImageRef = generator.copyCGImageAtTime(time, actualTime: nil, error: nil);
        var image : UIImage = UIImage(CGImage: oneRef);
        return image;
    }
    
    @IBAction func exportMovieSelected(sender: AnyObject) {
        exportVideo3(applicationDocumentsDirectory());
    }
    
    func exportVideo3(outputPath:String) {
        // http://stackoverflow.com/questions/25403315/ios-swift-merge-videos-using-avfoundation
        if (movieCount < 2) {
            println("at leats two movies needed for merging");
            return;
        }
        
        // the final composition, consisting of a video and an audio track.
        var composition = AVMutableComposition()
        var compositionVideo = AVMutableVideoComposition();
        compositionVideo.instructions = [ AVMutableVideoCompositionInstruction ]();
        compositionVideo.renderSize = CGSizeMake(640, 480);
        compositionVideo.frameDuration = CMTimeMake(1,30); // 30fs
        let trackVideo:AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID())
        let trackAudio:AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
        
        var insertTime = kCMTimeZero
        var index = 0;
        
        for index in 0 ... movieCount-1 {
            let moviePathUrl = movieUrls[index];
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
        waitIndicator.hidden = false;
        exporter.exportAsynchronouslyWithCompletionHandler({
            self.waitIndicator.hidden = true;
            switch exporter.status
                {
                case  AVAssetExportSessionStatus.Failed:
                    println("failed url=\(exporter.outputURL), error=\(exporter.error)")
                case AVAssetExportSessionStatus.Cancelled:
                    println("cancelled \(exporter.error)")
                default:
                    println("complete")
                    self.playMovie(exporter.outputURL);
                }
            })
    }
  
    
    func playMovie(url : NSURL) {
    
        println("playMovie: url=\(url)");
        moviePlayer.contentURL = url
        moviePlayer.movieSourceType = MPMovieSourceType.File
        
        moviePlayer.prepareToPlay();
        moviePlayer.play();

        println("playMovie: \(url) ... ");
    }
    
    
    
    func applicationDocumentsDirectory() -> String {

        var documentsDirectory : String?
        var paths:[AnyObject] = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true);
        
        if paths.count > 0 {
            if let pathString = paths[0] as? NSString {
                documentsDirectory = pathString
            }
        }
        
        return documentsDirectory!;
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

