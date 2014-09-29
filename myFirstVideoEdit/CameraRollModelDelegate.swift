//
//  CameraRollModelDelegate.swift
//  myFirstVideoEdit
//
//  Created by Guido Grassel on 28/09/14.
//  Copyright (c) 2014 Guido Grassel. All rights reserved.
//

import Foundation
import UIKit

@objc protocol CameraModelDelegate {
    
    optional func requestAccessToPhotoLibraryGranted();
    optional func requestAccessToPhotoLibraryDenied();
}