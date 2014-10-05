//
//  VidPlayerController.swift
//  myFirstVideoEdit
//
//  Created by Guido Grassel on 04/10/14.
//  Copyright (c) 2014 Guido Grassel. All rights reserved.
//

import Foundation
import UIKit

@objc protocol VidPlayerController {
    
    // returns the UIView into which the player anchors
    func getView() -> UIView
    
    // the player frame position and dimension
    func playerRect() -> CGRect
    
    // the player is ready to play, note: play(..) is asynchronous
    optional func readyToPlay(movieDuration : Float64)

    // the player started to play, note: play(..) is asynchronous
    optional func startedPlaying();
    
    // player paused playing.
    // does not get called when VC called stop
    optional func stoppedPlaying();
    
    // player rewinded to beginning and started to play the movie again.
    optional func looped();
    
    var playerTemporalPosition : Float64 { get set }
    
    // indicate if call to play causes video to autostart, or paused state
    var autoStartOnPlay : Bool { get set }
    
    optional func playerProgressUpdate(playerTemporalPosition : Float64)
}