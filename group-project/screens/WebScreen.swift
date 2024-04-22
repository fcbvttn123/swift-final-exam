/*
Author: Fizza Imran
Group Name: Byte_Buddies
Group Members:
- Tran Thanh Ngan Vu 991663076
- Chahat Jain 991668960
- Fizza Imran 991670304
- Chakshita Gupta 991653663
- Joshua Jocson 991657009
Description: A screen to dispaly selected URL
*/

import UIKit
import WebKit

class WebScreen: UIViewController, WKNavigationDelegate {
    
    // Web view for displaying the URL
    @IBOutlet var webView  : WKWebView!
    // Activity indicator for loading state
    @IBOutlet var activity: UIActivityIndicatorView!
    
    // get URL from privious view
    var urlString: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load the URL in the web view
        if let urlString = urlString, let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        } else {
            // Handle error when URL string is nil or invalid
            print("Error: Invalid URL string")
        }

        webView.navigationDelegate = self
        
    }
    
    // This Fuction is called when navigation starts
    func webView(
        _ webView: WKWebView,
        didStartProvisionalNavigation navigation: WKNavigation!
    ) {
        activity.isHidden = false
        activity.startAnimating()
    }
    
    // This Function is called when navigation finishes
    func webView(
        _ webView: WKWebView,
        didFinish navigation: WKNavigation!
    ) {
        activity.isHidden = true
        activity.stopAnimating()
    }
    
}


