//
//  myFirstVideoEditFetchPlayerItemTests.swift
//  myFirstVideoEdit
//
//  Created by Guido Grassel on 30/09/14.
//  Copyright (c) 2014 Guido Grassel. All rights reserved.
//


import XCTest
import UIKit
import Photos
import AVFoundation;
import CoreMedia;
class myFirstVideoEditFetchPlayerItemTests: XCTestCase, CameraModelDelegate {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    var cameraModel : CameraRollModel!;
    
    var playerLoadedLoadedExpectation : XCTestExpectation!;
    
    func testFetchPlayerItem() {
        cameraModel = CameraRollModel(delegate: self);
        cameraModel.requestAccessToPhotoLibraryAsync();
        
        playerLoadedLoadedExpectation = self.expectationWithDescription("fetch AVPlayerItem for video");
        self.waitForExpectationsWithTimeout(60.0, handler: nil);
    }
    
    func requestAccessToPhotoLibraryGranted() {
        XCTAssert(cameraModel != nil, "testFetchPlayerItem / requestAccessToPhotoLibraryGranted: cameraModel != nil");
        
        cameraModel!.requestAllVideos();
        var playerItemsToload = cameraModel!.count;
        for index in 0 ... cameraModel!.count-1 {
            cameraModel.fetchAssetFullAsync(index, handler: { (indexBack : Int, playerItem : AVPlayerItem!) -> Void in
                    XCTAssert(playerItem != nil, "player item \(indexBack) is nil");
                    println("playerItem for video \(indexBack), \(playerItem!.debugDescription), playbackLikelyToKeepUp=\(playerItem.playbackLikelyToKeepUp)"
                );
                playerItemsToload--;
                if (playerItemsToload == 0) {
                    self.playerLoadedLoadedExpectation.fulfill();
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
