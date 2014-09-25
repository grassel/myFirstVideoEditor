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
    var moviePlayer:MPMoviePlayerController!

    // the view model
    var movieThumbsImageViews : [UIImageView] = [UIImageView]();
    var movieThumbsImages : [UIImage] = [UIImage]();
    
    var videoPicker : VideoPicker!
    var movieExporter : MovieExporter!
    var model : Model!;
    
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
    
    var useCrossFadeTransition : Bool = true {
        didSet {
            if oldValue != useCrossFadeTransition {
                var image = useCrossFadeTransition ? UIImage(named: "transitionButtonImage") : UIImage(named: "cutTransitionButtonImage");
                transitionIndicatorButton1?.setBackgroundImage(image, forState: .Normal)
                transitionIndicatorButton2?.setBackgroundImage(image, forState: .Normal)
                transitionIndicatorButton3?.setBackgroundImage(image, forState: .Normal)
                videoAddedSinceLastExport = true;
            }
        }
    }
    
    var clipsCount : Int {
        get {
            return model.movieCount;
        }
    }
    
    var clipsCountMax : Int {
        get {
            return model.movieCountMax
        }
    }

    func addMovie(#originalMediaUrl: NSURL, editedMediaUrl : NSURL) {
        model.addMovie(originalMediaUrl: originalMediaUrl, editedMediaUrl: editedMediaUrl)
        videoAddedSinceLastExport = true;
        updateToolbarButtonStates();
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        model = Model();
        videoAddedSinceLastExport = false;
        isExporting = false;
        
        movieExporter = MovieExporter(myViewcontroller: self);
        
        movieThumbsImageViews = [
            movieThumbImage1!, movieThumbImage2!, movieThumbImage3!, movieThumbImage4!
        ];
        movieThumbsImages = [UIImage](count: model.movieCountMax, repeatedValue: UIImage());
        
        self.moviePlayer = MPMoviePlayerController();
        self.moviePlayer.view.frame = viewForMovie.bounds;
        self.moviePlayer.view.autoresizingMask =
              	           UIViewAutoresizing.FlexibleWidth |
              	           UIViewAutoresizing.FlexibleHeight;
        moviePlayer.fullscreen = false;
        moviePlayer.controlStyle = MPMovieControlStyle.Embedded; // Controls for an embedded view are displayed. The controls include a start/pause button, a scrubber bar, and a button for toggling between fullscreen and embedded display modes.

        self.viewForMovie.addSubview(self.moviePlayer.view)
    }

    override func viewWillAppear(animated: Bool) {
        waitIndicator.hidesWhenStopped = true;
        waitIndicator.layer.zPosition = 9999; // always on top
        updateToolbarButtonStates();
        updateWaitIndicator();
    }
    
    func updateToolbarButtonStates() {
        addVideoButton.enabled = (!isExporting && model.movieCount < model.movieCountMax);
        exportButton.enabled = !isExporting &&  videoAddedSinceLastExport && (model.movieCount >= 2);
        clearButton.enabled = !isExporting && (model.movieCount > 0);
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
    @IBAction func addVideoSelected(sender: AnyObject) {
        if (videoPicker == nil) {
            self.videoPicker = VideoPicker(viewController: self);
        }
        videoPicker.selectVideo();
    }
    
    func addMovie(#originalMediaUrl: NSURL, editedMediaUrl : NSURL, thumbnail: UIImage)  {
        if clipsCount < clipsCountMax {
            movieThumbsImages[clipsCount] = thumbnail;
            movieThumbsImageViews[clipsCount].image  =
                movieThumbsImages[clipsCount];
            
            addMovie(originalMediaUrl: originalMediaUrl, editedMediaUrl: editedMediaUrl)
        }
    }
    
    @IBAction func clearClipsSelected(sender: AnyObject) {
        model = Model();
        for index in 0 ... model.movieCountMax-1 {
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
        if (useCrossFadeTransition) {
            movieExporter.exportVideoCrossFade(applicationDocumentsDirectory());
        } else {
            movieExporter.exportVideo(applicationDocumentsDirectory());
        }
    }

    func movieExportCompletedOK(url : NSURL) {
        isExporting = false;
        videoAddedSinceLastExport = false;
        
        playMovie(url);
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
    
    
    
    @IBAction func transitionSelected(sender: AnyObject) {
        useCrossFadeTransition = !useCrossFadeTransition;
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

