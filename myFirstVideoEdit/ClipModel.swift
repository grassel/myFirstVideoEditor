//
//  Model.swift
//  myFirstVideoEdit
//
//  Created by Guido Grassel on 24/09/14.
//  Copyright (c) 2014 Guido Grassel. All rights reserved.
//

import UIKit
import AVFoundation;

class ClipModel: NSObject {
    // the model
    let movieCountMax : Int = 4
    
    var movieCount : Int = 0;
    
    override init () {
        movieAVAsset = [AVAsset]();
        movieCount = 0;
    }
    
    func addMovie(#avasset: AVAsset) {
        if movieCount < movieCountMax {
            movieAVAsset.append(avasset);
            movieCount++;
        } else {
            println ("Model:addMovie: Error: can not add another movie! Ignoring.");
        }
    }
    
    func movieAVAssetAt(index : Int) -> AVAsset! {
        return (index >= 0 && (index <= movieCount-1)) ? movieAVAsset[index] : nil
    }
    
    class func generateThumb(avasset : AVAsset) -> UIImage {
        // http://stackoverflow.com/questions/19105721/thumbnailimageattime-now-deprecated-whats-the-alternative
        var generator : AVAssetImageGenerator = AVAssetImageGenerator(asset: avasset);
        generator.appliesPreferredTrackTransform = true;
        var time : CMTime = CMTimeMake(1,2);
        var oneRef : CGImageRef = generator.copyCGImageAtTime(time, actualTime: nil, error: nil);
        var image : UIImage = UIImage(CGImage: oneRef)!;
        return image;
    }
    
    private var movieAVAsset : [AVAsset] = [AVAsset]();
}
