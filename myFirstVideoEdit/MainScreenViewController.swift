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
    var videoAddedSinceLastExport : Bool = false;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        model = Model();
        videoAddedSinceLastExport = false;

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
        updateToolbarButtonStates();
        waitIndicator.hidesWhenStopped = true;
        waitIndicator.stopAnimating()
        waitIndicator.layer.zPosition = 9999; // always on top
    }
    
    func updateToolbarButtonStates() {
        addVideoButton.enabled = (model.movieCount < model.movieCountMax);
        exportButton.enabled = videoAddedSinceLastExport && (model.movieCount >= 2);
        clearButton.enabled = (model.movieCount > 0);
    }
    
    /*
    select a new video using UIImagePicker
    and append it to movieUrls
    
     FIXME: This functionality should be moved to an own class.
    */
    @IBAction func addVideoSelected(sender: AnyObject) {
        if (videoPicker == nil) {
            self.videoPicker = VideoPicker(viewController: self);
        }
        videoPicker.selectVideo();
    }
    
    func addMovie(#originalMediaUrl: NSURL, editedMediaUrl : NSURL, thumbnail: UIImage)  {
        if model.movieCount < model.movieCountMax {
            movieThumbsImages[model.movieCount] = thumbnail;
            movieThumbsImageViews[model.movieCount].image  =
                movieThumbsImages[model.movieCount];
            
            videoAddedSinceLastExport = true;
            model.addMovie(originalMediaUrl: originalMediaUrl, editedMediaUrl: editedMediaUrl)
        }
        updateToolbarButtonStates();
    }
    
    @IBAction func clearClipsSelected(sender: AnyObject) {
        model = Model();
        for index in 0 ... model.movieCountMax-1 {
            movieThumbsImages[index] = UIImage(named: "Image") // from assets
            movieThumbsImageViews[index].image = movieThumbsImages[index];
        }
        videoAddedSinceLastExport = false;
        updateToolbarButtonStates();
    }
    
    /*
      compositing the movie using AVFoundation
        and  QuartzCore for fade animations
    */
    
    @IBAction func exportMovieSelected(sender: AnyObject) {
        waitIndicator.startAnimating()
        // FIXME: toggle two implementation options
   //     movieExporter.exportVideo(applicationDocumentsDirectory());
        movieExporter.exportVideoCrossFade(applicationDocumentsDirectory());
    }
    
    func movieExportCompletedOK(url : NSURL) {
        self.waitIndicator.stopAnimating()
        videoAddedSinceLastExport = false;
        updateToolbarButtonStates();
        
        
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

