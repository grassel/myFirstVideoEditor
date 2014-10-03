//
//  myFirstVideoEditTests.swift
//  myFirstVideoEditTests
//
//  Created by Guido Grassel on 22/09/14.
//  Copyright (c) 2014 Guido Grassel. All rights reserved.
//

import UIKit
import XCTest

class myFirstVideoEditFetchVideoThumbsTests: XCTestCase, CameraModelDelegate {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    var cameraModel : CameraRollModel!;
    
    var thumbsLoadedExpectation : XCTestExpectation!;
    
    func testLoadThumbsOfAllVideosInCameraRoll() {
        
        cameraModel = CameraRollModel(delegate: self);
        cameraModel.requestAccessToPhotoLibraryAsync();
        
        thumbsLoadedExpectation = self.expectationWithDescription("fetch all thumbnails");
        self.waitForExpectationsWithTimeout(60.0, handler: nil);
    }
    
    func requestAccessToPhotoLibraryGranted() {
        XCTAssert(cameraModel != nil, "requestAccessToPhotoLibraryGranted: cameraModel != nil");
        
        cameraModel!.requestAllVideos();
        var thumbsToload = cameraModel!.count;
        for index in 0 ... cameraModel!.count-1 {
            cameraModel.fetchAssetBasicInfoAtIndexAsync(index, placeholderImage: UIImage(named: "placeholderBlack")!, handler: { (indexBack : Int, createDateString : String, duration : Float64, imageBack : UIImage) -> Void in
                println("thumbnail image for video \(indexBack), created: \(createDateString), dur=\(duration)sec, \(imageBack.debugDescription), width x height = \(imageBack.size.width) x \(imageBack.size.height)");
                thumbsToload--;
                if (thumbsToload == 0) {
                    self.thumbsLoadedExpectation.fulfill();
                }
            })
        }
    }
}
