//
//  Model.swift
//  myFirstVideoEdit
//
//  Created by Guido Grassel on 24/09/14.
//  Copyright (c) 2014 Guido Grassel. All rights reserved.
//

import UIKit

class Model: NSObject {
    // the model
    var originalMovieUrls : [NSURL] = [NSURL]();
    var editedMovieUrls : [NSURL] = [NSURL]();
    var movieCount : Int = 0
    let movieCountMax : Int = 4

    override init () {
        originalMovieUrls = [NSURL](count: movieCountMax, repeatedValue: NSURL());
        editedMovieUrls = [NSURL](count: movieCountMax, repeatedValue: NSURL());
    }
    
    func addMovie(#originalMediaUrl: NSURL, editedMediaUrl : NSURL) {
         if movieCount < movieCountMax {
        originalMovieUrls[movieCount] = originalMediaUrl;
        editedMovieUrls[movieCount] = editedMediaUrl;
        movieCount++;
         } else {
            println ("Model:addMovie: Error: can not add another movie! Ignoring.");
        }
    }
    
    func movieUrlAt(index : Int) -> NSURL! {
        return (index >= 0 && index < movieCount) ? editedMovieUrls[index] : nil
    }
}
