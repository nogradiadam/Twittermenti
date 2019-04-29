//
//  ViewController.swift
//  Twittermenti
//
//  Created by Angela Yu on 17/07/2018.
//  Copyright © 2018 London App Brewery. All rights reserved.
//

import UIKit
import SwifteriOS
import CoreML
import SwiftyJSON

class ViewController: UIViewController {
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sentimentLabel: UILabel!
    
    let tweetCount = 100
    
    let sentimentClasssifier = TweetSentimentClassifier()
    
    var swifter : Swifter?

    override func viewDidLoad() {
        super.viewDidLoad()
        readPropertyList()
    }
    
    func readPropertyList() {
        var format = PropertyListSerialization.PropertyListFormat.xml
        var plistData:[String:AnyObject] = [:]
        let plistPath:String? = Bundle.main.path(forResource: "TwitterCredentials", ofType: "plist")!
        let plistXML = FileManager.default.contents(atPath: plistPath!)!
        
        do{
            plistData = try PropertyListSerialization.propertyList(from: plistXML,options: .mutableContainersAndLeaves,format: &format)as! [String:AnyObject]
            
            swifter = Swifter(consumerKey: plistData["CONSUMER KEY"] as! String, consumerSecret: plistData["CONSUMER SECRET"] as! String)
        }
        catch{
            print("Error reading plist: \(error), format: \(format)")
        }
    }

    @IBAction func predictPressed(_ sender: Any) {
        fetchTweets()
    }
    
    func fetchTweets() {
        if let searchText = textField.text {
            swifter?.searchTweet(using: searchText, lang: "en", count: tweetCount, tweetMode: .extended, success: { (results, metadata) in
                var tweets = [TweetSentimentClassifierInput]()
                for i in 0..<self.tweetCount {
                    if let tweet = results[i]["full_text"].string {
                        let tweetForClassification = TweetSentimentClassifierInput(text: tweet)
                        tweets.append(tweetForClassification)
                    }
                }
                self.makePrediction(with: tweets)
            }) { (error) in
                print("Error with the Twitter API request: \(error)")
            }
        }
    }
    
    func makePrediction(with tweets: [TweetSentimentClassifierInput]) {
        do {
            var sentimentScore = 0
            let predictions = try self.sentimentClasssifier.predictions(inputs: tweets)
            for prediction in predictions {
                if prediction.label == "Pos" {
                    sentimentScore += 1
                } else if prediction.label == "Neg" {
                    sentimentScore -= 1
                }
            }
            updateUI(with: sentimentScore)
        } catch {
            print("There was an error making a prediction: \(error)")
        }
    }
    
    func updateUI(with sentimentScore: Int) {
        if sentimentScore > 20 {
            self.sentimentLabel.text = "😍"
        } else if sentimentScore > 10 {
            self.sentimentLabel.text = "😀"
        } else if sentimentScore > 0 {
            self.sentimentLabel.text = "🙂"
        } else if sentimentScore == 0 {
            self.sentimentLabel.text = "😐"
        } else if sentimentScore > -10 {
            self.sentimentLabel.text = "🙁"
        } else if sentimentScore > -20 {
            self.sentimentLabel.text = "😡"
        } else {
            self.sentimentLabel.text = "🤮"
        }
    }
    
}

