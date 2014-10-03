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
    
    // FIXME: use AVPlayerItem instead of MPMoviePlayer? -
    // check if AVPlayerItem class can play AVMutableComposition without need to export first.
    var moviePlayer:VidPlayer!
    
    // the AVComposiiton that's  been created and playing in VidPlayer.
    // FIXME: move this property to VidPlayer
    var playingComposition : AVComposition!;
    
    // the view model
    var movieThumbsImageViews : [UIImageView] = [UIImageView]();
    var movieThumbsImages : [UIImage] = [UIImage]();
    
    var videoPicker : VideoPicker!
    var movieExporter : MovieExporter!
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
        
        movieExporter = MovieExporter(myViewcontroller: self);
        
        movieThumbsImageViews = [
            movieThumbImage1!, movieThumbImage2!, movieThumbImage3!, movieThumbImage4!
        ];
        movieThumbsImages = [UIImage](count: clipsModel.movieCountMax, repeatedValue: UIImage());
        
        /* self.moviePlayer = MPMoviePlayerController();
        self.moviePlayer.view.frame = viewForMovie.bounds;
        self.moviePlayer.view.autoresizingMask =
            UIViewAutoresizing.FlexibleWidth |
            UIViewAutoresizing.FlexibleHeight;
        moviePlayer.fullscreen = false;
        moviePlayer.controlStyle = MPMovieControlStyle.Embedded; // Controls for an embedded view are displayed. The controls include a start/pause button, a scrubber bar, and a button for toggling between fullscreen and embedded display modes.
        
        self.viewForMovie.addSubview(self.moviePlayer.view)
        */
        
        transitionStyle = transitionStyleEnum.crossDisolve
    }
    
    override func viewWillAppear(animated: Bool) {
        waitIndicator.hidesWhenStopped = true;
        waitIndicator.layer.zPosition = 9999; // always on top
        updateToolbarButtonStates();
        updateWaitIndicator();
        
        self.moviePlayer = VidPlayer(parentView: viewForMovie)
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        self.moviePlayer = nil;  // get rid of the VidPlayer object
        super.viewWillDisappear(animated)
    }
    
    func updateToolbarButtonStates() {
        addVideoButton.enabled = (!isExporting && clipsModel.movieCount < clipsModel.movieCountMax);
        exportButton.enabled = !isExporting &&  videoAddedSinceLastExport && (clipsModel.movieCount >= 2);
        clearButton.enabled = !isExporting && (clipsModel.movieCount > 0);
    }
    
    func updateWaitIndicator() {
        if isExporting {
            waitIndicator.startAnimating()
        } else {
            waitIndicator.stopAnimating()
        }
    }
    /*
    select a new video using UIImagePicker
    and append it to movieUrls
    */
    /*
    @IBAction func addVideoSelected(sender: AnyObject) {
    if (videoPicker == nil) {
    self.videoPicker = VideoPicker(viewController: self);
    }
    videoPicker.selectVideo();
    }
    */
    
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
    
    /*
    compositing the movie using AVFoundation
    and  QuartzCore for fade animations
    */
    
    @IBAction func exportMovieSelected(sender: AnyObject) {
        isExporting = true;
        switch transitionStyle{
        case transitionStyleEnum.rampInOut:
            movieExporter.exportVideoRampInOut(applicationDocumentsDirectory())
        case transitionStyleEnum.crossFade:
            movieExporter.exportVideoCrossFade(applicationDocumentsDirectory())
        case transitionStyleEnum.crossDisolve:
            movieExporter.exportVideoCrossFadeOpenGL(applicationDocumentsDirectory());
        }
    }
    
    
    func movieExportCompletedOK(url : NSURL) {
        isExporting = false;
        videoAddedSinceLastExport = false;
    }
    
    func playMovie(composition : AVComposition, videocomposition : AVVideoComposition) {
        if (self.playingComposition != nil) {
            self.moviePlayer.stopPlaying()
        }
        
        self.playingComposition = composition;
        self.moviePlayer.play(avcomposition: self.playingComposition, avvideocomposition: videocomposition)
    }
    
    func playMovie(url : NSURL) {
  //      println("playMovie: url=\(url)");
 //       moviePlayer.contentURL = url
 //       moviePlayer.movieSourceType = MPMovieSourceType.File
        
 //       moviePlayer.prepareToPlay();
 //       moviePlayer.play();
        
 //       println("playMovie: \(url) ... ");
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

