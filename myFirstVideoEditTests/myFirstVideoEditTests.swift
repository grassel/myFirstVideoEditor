//
//  myFirstVideoEditTests.swift
//  myFirstVideoEditTests
//
//  Created by Guido Grassel on 22/09/14.
//  Copyright (c) 2014 Guido Grassel. All rights reserved.
//

import UIKit
import XCTest

class myFirstVideoEditTests: XCTestCase, CameraModelDelegate {
    
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
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
        
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
            cameraModel.fetchAssetAtIndexAsync(index, placeholderImage: UIImage(named: "placeholderBlack"), handler: { (indexBack : Int, imageBack : UIImage) -> Void in
                println("thumbnail image for video \(indexBack), \(imageBack.debugDescription), width x height = \(imageBack.size.width) x \(imageBack.size.height)");
                imageBack.size.width
                thumbsToload--;
                if (thumbsToload == 0) {
                    self.thumbsLoadedExpectation.fulfill();
                }
            })
        }
    }
    
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
}
