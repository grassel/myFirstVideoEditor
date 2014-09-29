//
//  CameraRollTableViewController.swift
//  myFirstVideoEdit
//
//  Created by Guido Grassel on 27/09/14.
//  Copyright (c) 2014 Guido Grassel. All rights reserved.
//

import UIKit

class CameraRollTableViewController: UITableViewController, CameraModelDelegate {

    var cameraRollModel : CameraRollModel = CameraRollModel();
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraRollModel.delegate = self;
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func viewDidAppear(animated: Bool) {
        cameraRollModel.requestAccessToPhotoLibraryAsync();
    }
    
    func requestAccessToPhotoLibraryGranted() {
        cameraRollModel.requestAllVideos();
        
        // now its time to populate the table
        self.tableView.reloadData();
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return cameraRollModel.count;
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // configure the cell.
        let cellID : NSString = "videoCell"; // match what's been defined in the storyboard.
        var cellA = tableView.dequeueReusableCellWithIdentifier(cellID);
        var cell = cellA as UITableViewCell;

        var rowIndex = indexPath.row;
        
        // Configure the cell...
        // Increment the cell's tag
        var currentTag : NSInteger = cell.tag + 1;
        cell.tag = currentTag;
        
        cameraRollModel.fetchAssetAtIndexAsync(rowIndex,
            placeholderImage: UIImage(named: "placeholderBlack")!, handler: { (indexBack : Int, imageResult : UIImage) -> Void in
                // Only update the thumbnail if the cell tag hasn't changed. Otherwise, the cell has been re-used.
                if (cell.tag == currentTag) {
                    cell.imageView?.image  = imageResult;
                }
        });

        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView!, canEditRowAtIndexPath indexPath: NSIndexPath!) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView!, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath!) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView!, moveRowAtIndexPath fromIndexPath: NSIndexPath!, toIndexPath: NSIndexPath!) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView!, canMoveRowAtIndexPath indexPath: NSIndexPath!) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
