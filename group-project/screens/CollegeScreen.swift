/*
Author: Fizza Imran
Group Name: Byte_Buddies
Group Members:
- Tran Thanh Ngan Vu 991663076
- Chahat Jain 991668960
- Fizza Imran 991670304
- Chakshita Gupta 991653663
- Joshua Jocson 991657009
Description: This class manages the functionality related to setting and updating the user's home campus.
*/

import UIKit
import FirebaseFirestore
import AVFoundation

class CollegeScreen: UIViewController {
    
    var soundPlayer : AVAudioPlayer?
    @IBOutlet var volSlider : UISlider!
    
    @IBAction func viewDidChange(sender: UISlider){
        soundPlayer?.volume = volSlider.value
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let soundURL = Bundle.main
            .path(forResource: "song1", ofType: "mp3")
        let url = URL(fileURLWithPath: soundURL!)
        
        //sound player is initialized
        soundPlayer = try! AVAudioPlayer.init(contentsOf: url)
        
        //sound volume is set to a slider to play infinitely
        soundPlayer?.currentTime = 30
        soundPlayer?.volume = volSlider.value
        soundPlayer?.numberOfLoops = -1
        
        //sound is now played
        soundPlayer?.play()
        
    }
    
    // MARK: - Outlets
    @IBOutlet weak var addHomeCampusButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Check if HomeCampus is not set
        checkHomeCampus()
        
        // Updates our home campus button title if home campus is set
        updateHomeCampusButtonTitle()
        
        //sports ball animation is called
        dropBalls()
    }
    
    // This function is used to make the keyboard disappear when we tap the "return" key
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
    
    // This function is used to navigate back to this view controller
    @IBAction func toHomeScreen(sender: UIStoryboardSegue) {
        // No action needed
    }
    
    // MARK: - Home Campus Management
    
    // This function checks if the home campus is set for the current user
    func checkHomeCampus() {
        guard let currentUserUID = AppDelegate.shared.currentUserUID else {
            return
        }
        
        let profilesCollection = Firestore.firestore().collection("Profiles")
        profilesCollection.document(currentUserUID).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error getting document: \(error)")
                return
            }
            
            if let document = document, document.exists {
                // Document exists, check if HomeCampus is set
                let data = document.data()
                if let homeCampus = data?["HomeCampus"] as? String, !homeCampus.isEmpty {
                    // HomeCampus is set, proceed with functionality
                    self.handleProceed()
                } else {
                    // HomeCampus is not set, show pop-up to add HomeCampus
                    self.showHomeCampusPopUp()
                }
            } else {
                // Document doesn't exist, show pop-up to add HomeCampus
                self.showHomeCampusPopUp()
            }
        }
    }
    
    // This function presents a pop-up to add the home campus
    func showHomeCampusPopUp() {
        let alertController = UIAlertController(title: "Enter HomeCampus", message: "Please enter your HomeCampus to continue.", preferredStyle: .alert)
        
        // Add action to add HomeCampus
        let addAction = UIAlertAction(title: "Add HomeCampus", style: .default, handler: { [weak self] action in
            // Go to AddHomeCampusScreen
            self?.performSegue(withIdentifier: "toMaps", sender: nil)
        })
        alertController.addAction(addAction)
        
        // Add action to cancel
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.showPopUpAgain()
        }
        alertController.addAction(cancelAction)
        
        // Present the alert controller
        present(alertController, animated: true, completion: nil)
    }
    
    // This function shows a warning pop-up if the user chooses to continue without setting the home campus
    func showPopUpAgain() {
        let alertController = UIAlertController(title: "Warning!", message: "Not setting a Home Campus might impact your experience.", preferredStyle: .alert)
        
        // Add action to continue without setting
        let cancelAction = UIAlertAction(title: "Continue Without Setting", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        // Add action to add HomeCampus
        let addAction = UIAlertAction(title: "Add Home Campus", style: .default, handler: { [weak self] action in
            // Go to AddHomeCampusScreen
            self?.performSegue(withIdentifier: "toMaps", sender: nil)
        })
        alertController.addAction(addAction)
        
        // Present the warning alert controller
        present(alertController, animated: true, completion: nil)
    }
    
    // This function updates the title of the home campus button
    func updateHomeCampusButtonTitle() {
        guard let currentUserUID = AppDelegate.shared.currentUserUID else {
            return
        }
        
        let profilesCollection = Firestore.firestore().collection("Profiles")
        profilesCollection.document(currentUserUID).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error getting document: \(error)")
                return
            }
            
            if let document = document, document.exists {
                let data = document.data()
                if let homeCampus = data?["HomeCampus"] as? String {
                    // HomeCampus is set, update the button's title
                    self.addHomeCampusButton.setTitle(homeCampus, for: .normal)
                }
            }
        }
    }
    
    //Created by Joshua Jocson
    //This function allows for a "ball drop" and "bounce" animation of different sports balls, once the view has been loaded
    func dropBalls() {
        let ballTypes = ["soccerball", "tennisball", "volleyball", "basketball"]
        
        for (index, ballType) in ballTypes.enumerated() {
            let ball = CALayer()
            ball.contents = UIImage(named: "\(ballType).png")?.cgImage
            ball.bounds = CGRect(x: 0, y: 0, width: 50, height: 50)
            //initial position is set up top
            ball.position = CGPoint(x: CGFloat(50 + index * 100), y: view.bounds.height / 2 - 100)
            
            view.layer.addSublayer(ball)
            
            let fallAnimation = CABasicAnimation(keyPath: "position.y")
            fallAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)
            fallAnimation.fromValue = -25
            fallAnimation.toValue = view.bounds.height - 25
            //balls drop between a duration of 1.5 to 2.0 seconds
            fallAnimation.duration = Double.random(in: 1.5...2.0)
            fallAnimation.fillMode = .forwards
            fallAnimation.isRemovedOnCompletion = true
            //0.25 second delay for each ball
            fallAnimation.beginTime = CACurrentMediaTime() + Double(index) * 0.25
            
            ball.add(fallAnimation, forKey: "fallAnimation")
            
            //bounce animation as soon as the fall animation completesa
            DispatchQueue.main.asyncAfter(deadline: .now() + fallAnimation.duration) {
                let bounceAnimation = CABasicAnimation(keyPath: "position.y")
                bounceAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                bounceAnimation.fromValue = self.view.bounds.height - 25
                bounceAnimation.toValue = self.view.bounds.height - 100
                bounceAnimation.duration = 0.5
                bounceAnimation.autoreverses = true
                bounceAnimation.repeatCount = 5
                
                ball.add(bounceAnimation, forKey: "bounceAnimation")
                
            //balls are removed after having bounced a few times
            DispatchQueue.main.asyncAfter(deadline: .now() + (bounceAnimation.duration * Double(bounceAnimation.repeatCount))) {
                    ball.removeFromSuperlayer()
                }
            }
        }
    }
    
    
    // MARK: - Button Actions
    
    // This function handles the tap on the "Add Home Campus" button
    @IBAction func addHomeCampusButtonTapped(_ sender: UIButton) {
        guard let currentUserUID = AppDelegate.shared.currentUserUID else {
            return
        }
        
        let profilesCollection = Firestore.firestore().collection("Profiles")
        profilesCollection.document(currentUserUID).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error getting document: \(error)")
                return
            }
            
            if let document = document, document.exists {
                let data = document.data()
                
                // Check if HomeCampus is set
                if let _ = data?["HomeCampus"] as? String {
                    // HomeCampus is set, proceed with functionality (in this case, navigate to Maps screen)
                    self.performSegue(withIdentifier: "toMaps", sender: nil)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // This function handles functionality after checking HomeCampus
    func handleProceed() {
        // Handle the functionality after checking HomeCampus
        // For now we dont need anything since we are handling the conditional seague
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toBookings" {
            if let destinationVC = segue.destination as? ViewBookingsScreen,
               let bookingId = sender as? String {
                destinationVC.bookingId = bookingId
            }
        }
    }

    // MARK: - Other Button Actions

    @IBAction func pickPlayButtonTapped(_ sender: UIButton) {
        // For now we dont need anything since we are handling the conditional seague
    }
    
    @IBAction func viewBookingsButtonTapped(_ sender: UIButton) {
        guard let currentUserUID = AppDelegate.shared.currentUserUID else {
            return
        }

        // Perform segue to ViewBookingsScreen with identifier toBookings
        performSegue(withIdentifier: "toBookings", sender: currentUserUID)
    }

    
    @IBAction func addPlayButtonTapped(_ sender: UIButton) {
        // For now we dont need anything since we are handling the conditional seague
    }
}

