//
//  CameraRollModel.swift
//  myFirstVideoEdit
//
//  Created by Guido Grassel on 27/09/14.
//  Copyright (c) 2014 Guido Grassel. All rights reserved.
//

import UIKit
import Photos
import AVFoundation;
import CoreMedia;

class CameraRollModel: NSObject, PHPhotoLibraryChangeObserver {
   
    var delegate : CameraModelDelegate!;
    
    // the user's camera roll
    var sharedPhotoLibrary : PHPhotoLibrary!
    var smartAlbumVideosFetchRequest : PHFetchResult!;
    
    // this structure will include all user's videos once the fetch has completed
    var cameraRollVideosFetchResults : PHFetchResult!;
    
    var imageManager : PHImageManager = PHImageManager.defaultManager();
    
    override init() {
        super.init();
    }
    
    init(delegate : CameraModelDelegate) {
        super.init();
        self.delegate = delegate;
    }
    
    var count : Int {
        get {
            return cameraRollVideosFetchResults == nil ? 0 :  cameraRollVideosFetchResults.count;
        }
    }
    
    // before being able to do anything on the PhotoLibrary, we need the user's permission
    // PHPhotoLibrary.requestAuthorization brings up a dialog asking the user.
    func requestAccessToPhotoLibraryAsync() {
        PHPhotoLibrary.requestAuthorization { (status : PHAuthorizationStatus) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                if (status == PHAuthorizationStatus.Authorized) {
                    self.sharedPhotoLibrary = PHPhotoLibrary.sharedPhotoLibrary();
                    self.delegate?.requestAccessToPhotoLibraryGranted?();
                } else {
                    println("Can not access PHPhotoLibrary!")
                    self.delegate?.requestAccessToPhotoLibraryDenied?()
                }
            });
        }
    }
    
    // to bootstrap things,
    func requestAllVideos() {
        // FIXME: needed?
        self.smartAlbumVideosFetchRequest  = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.Album, subtype: PHAssetCollectionSubtype.SmartAlbumVideos, options: nil)
        
        var options = PHFetchOptions();
        options.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: true) ]
        self.cameraRollVideosFetchResults = PHAsset.fetchAssetsWithMediaType(PHAssetMediaType.Video, options: options)
        
        self.sharedPhotoLibrary.registerChangeObserver(self)
        
        println ("smartAlbumVideosFetchRequest count: \(self.smartAlbumVideosFetchRequest.count) ");
        println ("cameraRollVideosFetchResults count: \(self.cameraRollVideosFetchResults.count) ");
    }
    
    
    func fetchAssetBasicInfoAtIndexAsync(index : Int, placeholderImage : UIImage, handler : ((Int, String, Float64, UIImage) -> Void) ) {
        if index < 0 || index >= self.count {
            println ("assetAtIndex: index \(index) out of range. Ignoring request.");
            handler(index, "unknown", 0, placeholderImage);
            return;
        }
        
        // PHFetchResult is a PHAsset class
        var asset : PHAsset = cameraRollVideosFetchResults[index] as PHAsset;

        // the PHImageManager delivers the AVAsset
        var assetOptions =  PHVideoRequestOptions();
        assetOptions.deliveryMode = PHVideoRequestOptionsDeliveryMode.FastFormat;
        self.imageManager.requestAVAssetForVideo(asset,
            options: assetOptions) { (videoAsset : AVAsset!, audioAsset : AVAudioMix!, info : [NSObject : AnyObject]!) -> Void in
                if (videoAsset == nil) {
                    println ("fetchAssetBasicInfoAtIndexAsync: index \(index), no video asset found");
                    handler(index, "unknown", 0, placeholderImage)
                    return;
                } else {
                    var generator : AVAssetImageGenerator = AVAssetImageGenerator(asset: videoAsset);
                    generator.appliesPreferredTrackTransform = true;
                    var time : CMTime = CMTimeMake(1,2);
                    generator.maximumSize = CGSize(width: 240, height: 160)
                    var oneRef : CGImageRef = generator.copyCGImageAtTime(time, actualTime: nil, error: nil);
                    var image : UIImage = UIImage(CGImage: oneRef);
                    var duration : Float64 = CMTimeGetSeconds(videoAsset.duration)
                    var creationDate : AVMetadataItem! = videoAsset.creationDate
                    var creationDateString = "unknown"
                    if (creationDate != nil) {
                        var dateNS : NSDate =  creationDate!.dateValue;
                        creationDateString = dateNS.description;
                    }
                    handler(index, creationDateString, duration, image);
                }
            }
    }
    
    func fetchAssetFullAsync(index : Int, handler : ((Int, AVPlayerItem! ) -> Void) ) {
        if index < 0 || index >= self.count {
            println ("fetchAssetFullAsync: index \(index) out of range. Ignoring request.");
            handler(index, nil);
            return;
        }
        
        // PHFetchResult is a PHAsset class
        var asset : PHAsset = cameraRollVideosFetchResults[index] as PHAsset;
        
        // the PHImageManager delivers the AVAsset
        var assetOptions =  PHVideoRequestOptions();
        assetOptions.deliveryMode = PHVideoRequestOptionsDeliveryMode.Automatic;
        
        self.imageManager.requestPlayerItemForVideo(asset, options: assetOptions) { ( avPlayerItemResult : AVPlayerItem!, info :[NSObject : AnyObject]!) -> Void in
            if (avPlayerItemResult == nil) {
                println ("fetchAssetFullAsync: index \(index), no video asset found");
                handler(index, nil)
                return;
            } else {
                 handler(index, avPlayerItemResult)
            }
        }
    }
    
    func photoLibraryDidChange(changeInstance: PHChange!) {
        // this call will happen in a background thread
        dispatch_async(dispatch_get_main_queue(), {
            
            /*
            var updatedCollectionsFetchResults : NSMutableArray!
            
            for index in 0 ... self.collectionsFetchResults.count {
                var collectionsFetchResult : PHFetchResult = self.collectionsFetchResults[index] as PHFetchResult;
                
                // we are only interested in changes related to collectionsFetchResult, i.e. Fetch results for user's video!
                var changeDetails : PHFetchResultChangeDetails! = changeInstance.changeDetailsForFetchResult(collectionsFetchResult);
                
                if (changeDetails != nil) {
                    if (updatedCollectionsFetchResults == nil) {
                        updatedCollectionsFetchResults = self.collectionsFetchResults.mutableCopy() as NSMutableArray
                    }
                    updatedCollectionsFetchResults.replaceObjectAtIndex(self.collectionsFetchResults.indexOfObject(collectionsFetchResult), withObject: changeDetails.fetchResultAfterChanges);
                }
            }
            
            if (updatedCollectionsFetchResults != nil) {
                self.collectionsFetchResults = updatedCollectionsFetchResults!;
                // FIXME: self.tableView reloadData
            }
*/
        });
    }
}
