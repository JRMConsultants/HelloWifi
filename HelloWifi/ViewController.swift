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
    
    // The "Auto Update" button.  We need a reference to it so that we can change its title (text) depending on whether
    // auto updates are on or off.
    @IBOutlet weak var autoUpdateButton: UIButton!

    // What zip code should we be downloading weather for?
    // This would probably normally be requested from the user in some way (on-screen UI) but I am in a quick and dirty mood now
    let zipCode = "93101"
    
    // This app uses the Weather Underground API ( http://www.wunderground.com/weather/api/ ) to download weather data.
    // It requires that you sign up for a (free) API key.  (or just use this one, which is mine.)
    let apiKey = "3db8576e12fd87f4"
    
    // Create a timer that periodically calls a function
    var timer = NSTimer()
    
    // Flag to indicate whether we are running or not
    var autoUpdateEnabled = false
    
    // This function is called automatically when the view loads (i.e. when first comes on screen)
    // Use this to perform some initial set up tasks (e.g. connect to databases, make network connections, etc.)
    override func viewDidLoad() {
        super.viewDidLoad()
        log("Greetings.")
        // set the title of the Auto Update button
        updateButtonText()
    }

    // This function is called when the OS is running out of memory.  It should be used to free up memory by deallocating
    // resources that are not in use and/or can be easily recreated when needed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // not doing anything here at the moment
    }

    // This function is run whenever the "Manual Update" button is tapped.
    @IBAction func initiateManualUpdate(sender: AnyObject) {
        // kick off a manual update
        update()
    }
    
    // Handle taps on the "Auto Update" button - this will toggle the state of auto updating (switch it on or off)
    @IBAction func toggleAutoUpdate(sender: AnyObject) {
        if (autoUpdateEnabled) {
            // auto update is enabled, switch it off
            log("Turning auto updates OFF.")
            autoUpdateEnabled = false
            // Invalidate the timer (that is, stop it from firing)
            timer.invalidate()
        } else {
            // auto update is disabled, turn it on
            log("Turning auto updates ON.")
            autoUpdateEnabled = true
            // Set up an NSTimer, this will fire off every 5 minutes and call our update function
            // Time interval is in seconds, so multiply 60 * 5 to get 5 minutes = 300 seconds
            timer = NSTimer.scheduledTimerWithTimeInterval(60*5, target: self, selector: Selector("update"), userInfo: nil, repeats: true)
            // the timer does not start immediately, so manually run our first update
            update()
        }
        
        // update the button text
        updateButtonText()
    }

    // A function that updates the title of the "Auto Update" button depending on whether or not auto updates are enabled or not
    func updateButtonText() {
        // Update the text of the auto update button depending on whether auto updates are on or off
        if autoUpdateEnabled {
            // set the title of the button's "default" state
            autoUpdateButton.setTitle("Auto Update: ON", forState: .Normal)
        } else {
            autoUpdateButton.setTitle("Auto Update: OFF", forState: .Normal)
        }
    }
    
    // Fetch the latest weather data
    func update() {
        log("Downloading latest weather data...")

        // Use the Weather Underground API to fetch weather data for the desired Zip code
        // Here we are constructing the URL to send to Weather Underground, it must be constructed to a specific format
        // as dictated by the API documentation: http://www.wunderground.com/weather/api/d/docs?d=data/conditions
        let urlPath = "http://api.wunderground.com/api/\(apiKey)/conditions/q/CA/\(zipCode).json"
        // Create an NSURL object based on the above string, this is what the system normally uses when dealing with URLs
        let url: NSURL = NSURL(string: urlPath)!
        // Create an NSURLSession, this object handles all the tasks of managing Internet communications (downloading data,
        // handling HTTP errors, etc.)
        let session = NSURLSession.sharedSession()
        // Create a task to fetch data from the above URL
        // The completion handler is called by the system when the URL fetch has finished (either successfully or
        // with an error) and is specified as a clojure (an inline block of code)
        let task = session.dataTaskWithURL(url, completionHandler: {data, response, error -> Void in
            // "error" will be set if the URL download failed for whatever reason (no network connection, connection
            // dropped, etc.)  It is nil if the connection was successful.
            if error != nil {
                // If there is an error in the web request, print it to the console
                println(error.localizedDescription)
            }
            
            // The connection itself succeeded, and theoretically has returned to us a bunch of data in JSON format.
            // However, it is possible that we received faulty data, so we have to check to make sure as we attempt to decode it.
            var err: NSError?
            // Attempt to decode the data we received
            var jsonResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err) as NSDictionary
            if err != nil {
                // If there is an error parsing JSON, print it to the console
                println("JSON Error \(err!.localizedDescription)")
                self.log("Error retrieving weather data: \(err!.localizedDescription)")
            }
            
            // Data parsing was successful
            self.log("Successfully fetched weather data.")
            
            // Now comes the tricky task of actually reading out the JSON.  Because of Swift's strict typed nature, parsing
            // JSON is notoriously difficult.  Fortunately someone has created a helper code to make this a lot easier, called
            // SwiftyJSON.  Read more about it, and how to use it, at its github page: https://github.com/lingoer/SwiftyJSON
            // More info on the troubles with parsing JSON data in Swift: http://www.topcoder.com/blog/calling-apis-parsing-json-with-swift/
            
            // Use SwiftyJSON to parse the JSON into objects that we can directly use
            let json = JSON(jsonResult)
            println("GOT JSON: \(json)")
            
            // Parse out the individual bits of data from the JSON
            let cityName = json["current_observation"]["display_location"]["full"].string
            let stationId = json["current_observation"]["station_id"].string
            let obsTime = json["current_observation"]["observation_time"].string
            let weather = json["current_observation"]["weather"].string
            let temperature = json["current_observation"]["temp_f"].double
            var tempFeelsLike = json["current_observation"]["feelslike_f"].double
            let windString = json["current_observation"]["wind_string"].string
            let windDegrees = json["current_observation"]["wind_degrees"].double
            let windDirection = json["current_observation"]["wind_dir"].string
            let windMPH = json["current_observation"]["wind_mph"].double
            var windGustMPH = json["current_observation"]["wind_gust_mph"].double
            let pressureMB = json["current_observation"]["pressure_mb"].string
            var pressureTrend = json["current_observation"]["pressure_trend"].string
            let relativeHumidity = json["current_observation"]["relative_humidity"].string

            // Work arounds for some odd behavior from the API...
            
            // this is a little weird, sometimes the value of "feelslike_f" is not specified.  If this is the case,
            // then just assume the "feels like" temperature is equal to the current temperature (a reasonable assumption.)
            if (tempFeelsLike == nil) {
                tempFeelsLike = temperature
            }

            // this is a little weird, sometimes the value of "wind_gust_mph" is not specified.  If this is the case,
            // then just assume the wind gust speed is equal to the current wind speed (a reasonable assumption.)
            if (windGustMPH == nil) {
                windGustMPH = windMPH
            }
            
            // The trend is given to us as a single character, either "0" (unchanging), "-" (decreasing) or "+" (increasing.)
            // This bit of hacky code just turns that into a more human readable/user friendly string.
            var trend = ""
            let trendTemp:String = pressureTrend as String!
            switch trendTemp {
                case "0": trend = "no change"
                case "+": trend = "increasing"
                case "-": trend = "decreasing"
            default: pressureTrend = "unknown"
            }

            // Log it out to the screen
            self.log("Weather report for \(cityName!) (\(stationId!)), \(obsTime!):")
            self.log("Conditions: \(weather!)")
            self.log("Temperature: \(temperature!)°F (feels like \(tempFeelsLike!)°F)")
            self.log("Winds: \(windString!)")
            self.log("Pressure: \(pressureMB!) MB (trend: \(trend))")
            self.log("Relative Humidity: \(relativeHumidity!)")
            
            self.log("*** END OF REPORT***")
        })
        
        // NSURLSession tasks don't automatically start, we must explicitly start them by calling their resume() method.
        task.resume()
    }
    
    // Helper function that adds a date/time stamped message to the log window
    func log(message: String) {
        dispatch_async(dispatch_get_main_queue(),{
            // Get the current date and time as a string in short format (i.e. "1/19/15 11:41 AM")
            let date = NSDate()
            let formatter = NSDateFormatter()
            formatter.dateStyle = .ShortStyle
            formatter.timeStyle = .ShortStyle
            let dateString = formatter.stringFromDate(date)
            
            // add message to log window
            self.outputBox.text = self.outputBox.text + "[\(dateString)] \(message)\n"
            
            // scroll the output box to the bottom
            self.outputBox.scrollRangeToVisible(NSMakeRange(countElements(self.outputBox.text), 0))
        });
    }

    // This function is automatically called by the OS whenever a scroll view finishes its scrolling
    func scrollViewDidScroll(scrollView: UIScrollView) {
        // flash the scroll indicators as an indication to the user that some scrolling did occur
        scrollView.flashScrollIndicators()
    }
}