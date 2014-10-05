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
import Photos

class MainScreenViewController: UIViewController {
    
    @IBOutlet weak var movieThumbImage1: UIImageView!
    @IBOutlet weak var movieThumbImage2: UIImageView!
    @IBOutlet weak var movieThumbImage3: UIImageView!
    @IBOutlet weak var movieThumbImage4: UIImageView!
    
    @IBOutlet weak var transitionIndicatorButton1: UIButton!
    @IBOutlet weak var transitionIndicatorButton2: UIButton!
    @IBOutlet weak var transitionIndicatorButton3: UIButton!
    
    @IBOutlet weak var waitIndicator: UIActivityIndicatorView!
    
    // Storyboard does not allow us to add this MoviePlayer directly.
    // Insted, we only create a placeholder view  self.viewForMovie
    // in story board and add the MoviePlayer view programmatically
    @IBOutlet weak var viewForMovie: UIView!
    
    @IBOutlet weak var addVideoButton: UIBarButtonItem!
    @IBOutlet weak var clearButton: UIBarButtonItem!
    @IBOutlet weak var exportButton: UIBarButtonItem!
    @IBOutlet weak var playButton: UIButton!
    
    var vidPlayerViewController : VidPlayerViewController!
    
    // the view model
    var movieThumbsImageViews : [UIImageView] = [UIImageView]();
    var movieThumbsImages : [UIImage] = [UIImage]();
    
    var videoPicker : VideoPicker!
    var movieExporter : MovieCompositerExporter!
    var clipsModel : ClipModel!;
    
    var videoAddedSinceLastExport : Bool = false {
        didSet {
            if oldValue != videoAddedSinceLastExport {
                updateToolbarButtonStates()
            }
        }
    }
    
    var isExporting : Bool = false {
        didSet {
            if oldValue != isExporting {
                updateToolbarButtonStates()
                updateWaitIndicator();
            }
        }
    }
    
    enum transitionStyleEnum {
        case rampInOut
        case crossFade
        case crossDisolve
    };
    
    var transitionStyle : transitionStyleEnum = transitionStyleEnum.crossFade {
        didSet {
            if oldValue != transitionStyle {
                var image : UIImage!
                switch transitionStyle{
                case transitionStyleEnum.rampInOut:
                    image = UIImage(named: "cutTransitionButtonImage");
                case transitionStyleEnum.crossFade:
                    image = UIImage(named: "crossFadeTransitionButtonImage")
                case transitionStyleEnum.crossDisolve:
                    image = UIImage(named: "crossDisolveTransitionButtonImage")
                }
                transitionIndicatorButton1?.setBackgroundImage(image, forState: .Normal)
                transitionIndicatorButton2?.setBackgroundImage(image, forState: .Normal)
                transitionIndicatorButton3?.setBackgroundImage(image, forState: .Normal)
                videoAddedSinceLastExport = true;
            }
        }
    }
    
    var clipsCount : Int {
        get {
            return clipsModel.movieCount;
        }
    }
    
    var clipsCountMax : Int {
        get {
            return clipsModel.movieCountMax
        }
    }
    
    func clipAt(index : Int) -> AVAsset {
        return clipsModel.movieAVAssetAt(index)
    }
    
    
    func addMovie(avasset : AVAsset) {
        if clipsCount < clipsCountMax {
            // generate and add thumnail
            movieThumbsImages[clipsCount] = ClipModel.generateThumb(avasset);
            movieThumbsImageViews[clipsCount].image  = movieThumbsImages[clipsCount];
            
            clipsModel.addMovie(avasset: avasset)
            
            videoAddedSinceLastExport = true;
            updateToolbarButtonStates();
        } else {
            println("addMovie - capacity reached, can not add another movie");
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        clipsModel = ClipModel();
        videoAddedSinceLastExport = false;
        isExporting = false;
        
        movieExporter = MovieCompositerExporter(myViewcontroller: self);
        
        movieThumbsImageViews = [
            movieThumbImage1!, movieThumbImage2!, movieThumbImage3!, movieThumbImage4!
        ];
        movieThumbsImages = [UIImage](count: clipsModel.movieCountMax, repeatedValue: UIImage());
        
        transitionStyle = transitionStyleEnum.crossDisolve
        
        vidPlayerViewController = VidPlayerViewController(myView: viewForMovie);
    }
    
    override func viewWillAppear(animated: Bool) {
        waitIndicator.hidesWhenStopped = true;
        waitIndicator.layer.zPosition = 9999; // always on top
        updateToolbarButtonStates();
        updateWaitIndicator();
        
        vidPlayerViewController.autoStartOnPlay = false
        vidPlayerViewController.viewWillAppear(animated)
    }
    
     override func viewDidAppear(animated: Bool) {
        self.generateCompositeVideo();
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.vidPlayerViewController.viewWillDisappear(animated)
        super.viewWillDisappear(animated)
    }
    
 //   override func viewDidUnload() {
 //       self.vidPlayerViewController = nil;  // get rid of the VidPlayer object
 //   }
    
    
    func updateToolbarButtonStates() {
        addVideoButton.enabled = (!isExporting && clipsModel.movieCount < clipsModel.movieCountMax);
        exportButton.enabled = !isExporting &&  videoAddedSinceLastExport && (clipsModel.movieCount >= 2);
        clearButton.enabled = !isExporting && (clipsModel.movieCount > 0);
      //  playButton.enabled = (clipsModel.movieCount >= 2)
    }
    
    func updateWaitIndicator() {
        if isExporting {
            waitIndicator.startAnimating()
        } else {
            waitIndicator.stopAnimating()
        }
    }
    
    
    @IBAction func addVideoSelected(sender: AnyObject) {
        var vc = CameraRollTableViewController();
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    @IBAction func clearClipsSelected(sender: AnyObject) {
        clipsModel = ClipModel();
        for index in 0 ... clipsModel.movieCountMax-1 {
            movieThumbsImages[index] = UIImage(named: "placeholderBlack") // from image assets
            movieThumbsImageViews[index].image = movieThumbsImages[index];
        }
        videoAddedSinceLastExport = false;
    }
    
    func generateCompositeVideo() {
        // sync with exporting
        // enable this button when composiotion are not nil
        
        if clipsCount < 2 {
            return;
        }
        
        switch transitionStyle {
        case transitionStyleEnum.rampInOut:
            println("FIXME AVCoreAnimationTool not working with AVPlayer");
            // movieExporter.compositeVideoRampInOut();
        case transitionStyleEnum.crossFade:
            movieExporter.compositeVideoCrossFade();
            self.vidPlayerViewController.play(avcomposition: self.movieExporter.composition,
                avvideocomposition: self.movieExporter.videocomposition)
        case transitionStyleEnum.crossDisolve:
            movieExporter.compositeVideoCrossFadeOpenGL();
            self.vidPlayerViewController.play(avcomposition: self.movieExporter.composition,
                avvideocomposition: self.movieExporter.videocomposition)
        default:
            println("FIXME: unsupported transition type, ignoring.");
            return;
        }
    }
    
    @IBAction func exportMovieSelected(sender: AnyObject) {
        isExporting = true;
        movieExporter.exportVideo(applicationDocumentsDirectory(),
            whenDone: { () -> Void in
                self.isExporting = false;
            },
            whenFailed: { () -> Void in
                self.isExporting = false;
                // FIXME
        })
    }
    
    
    func playMovie(composition : AVComposition, videocomposition : AVVideoComposition) {
        self.vidPlayerViewController.play(avcomposition: composition, avvideocomposition: videocomposition)
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
    
    
    
    @IBAction func transitionSelected(sender: AnyObject) {
        switch transitionStyle{
        case transitionStyleEnum.rampInOut:
            transitionStyle = transitionStyleEnum.crossFade
        case transitionStyleEnum.crossFade:
            transitionStyle = transitionStyleEnum.crossDisolve
        case transitionStyleEnum.crossDisolve:
            transitionStyle = transitionStyleEnum.rampInOut
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "PickVideoSeque") {
            // let vc : CameraRollTableViewController = segue.destinationViewController as CameraRollTableViewController;
            // pass parameters to  vc
        }
    }
}

