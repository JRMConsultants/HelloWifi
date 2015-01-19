//
//  ViewController.swift
//  HelloWifi
//
//  Created by Donald Burr on 1/17/15.
//  Copyright (c) 2015 Donald Burr. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIScrollViewDelegate {

    // The text box that will show output/log messages
    @IBOutlet weak var outputBox: UITextView!
    
    // This function is called automatically when the view loads (i.e. when first comes on screen)
    // Use this to perform some initial set up tasks (e.g. connect to databases, make network connections, etc.)
    override func viewDidLoad() {
        super.viewDidLoad()
        log("Program is now running.")
    }

    // This function is called when the OS is running out of memory.  It should be used to free up memory by deallocating
    // resources that are not in use and/or can be easily recreated when needed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // This function is run whenever the "Test" button is tapped.  For now we just log a test message.
    @IBAction func testOutputBox(sender: AnyObject) {
        let date = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateStyle = .LongStyle
        formatter.timeStyle = .LongStyle
        log("The time is now " + formatter.stringFromDate(date) + ".")
    }
    
    // Helper function that adds a date/time stamped message to the log window
    func log(message: String) {
        // Get the current date and time as a string in short format (i.e. "1/19/15 11:41 AM")
        let date = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        formatter.timeStyle = .ShortStyle
        let dateString = formatter.stringFromDate(date)
        
        // add message to log window
        outputBox.text = outputBox.text + "[\(dateString)] \(message)\n"
        
        // scroll the output box to the bottom
        outputBox.scrollRangeToVisible(NSMakeRange(countElements(outputBox.text), 0))
    }

    // This function is automatically called by the OS whenever a scroll view finishes its scrolling
    func scrollViewDidScroll(scrollView: UIScrollView) {
        // flash the scroll indicators as an indication to the user that some scrolling did occur
        scrollView.flashScrollIndicators()
    }
}

