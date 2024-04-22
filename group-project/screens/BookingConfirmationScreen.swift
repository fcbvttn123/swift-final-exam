/*
 Author: Fizza Imran
Group Name: Byte_Buddies
Group Members:
- Tran Thanh Ngan Vu 991663076
- Chahat Jain 991668960
- Fizza Imran 991670304
- Chakshita Gupta 991653663
 - Joshua Jocson 991657009
Description: Class for handling booking confirmation and sending confirmation emails.
*/

import UIKit
import MessageUI
import FirebaseFirestore

class BookingConfirmationScreen: UIViewController, MFMailComposeViewControllerDelegate {
    
    // MARK: - Outlets
    //text field for entering recipient's email
    @IBOutlet var emailTextField: UITextField!
    //button for viewing bookings
    @IBOutlet var viewBookingsButton: UIButton!

    // MARK: - Variables
    
    // Booking Id recieved from privious view
    var bookingId: String?
    // Dictionary to store booking details
    var bookingDetails: [String: Any] = [:]

    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Fetch booking details if booking ID is available
        if let bookingId = bookingId {
            fetchBookingDetails(for: bookingId)
        }
    }

    // This function dismisses the keyboard when return key is pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - Firebase integration
    
    /**
        Fetches booking details from Firestore.
        
        - Parameter bookingId: The ID of the booking.
        */
    
    func fetchBookingDetails(for bookingId: String) {
        let db = Firestore.firestore()
        db.collection("Bookings").document(bookingId).getDocument { [weak self] (document, error) in
            guard let self = self else { return }

            if let error = error {
                print("Error fetching booking details: \(error.localizedDescription)")
                return
            }

            guard let document = document, document.exists else {
                print("Booking details document does not exist")
                return
            }

            if let bookingData = document.data()?["BookingData"] as? [[String: Any]] {
                if let bookingDetails = bookingData.first {
                    self.bookingDetails = bookingDetails
                }
            }

        }
    }

    // MARK: - Actions
       
       /**
        Action method for the send confirmation button.
        
        - Parameter sender: The button triggering the action.
        */
    
    @IBAction func sendConfirmationButtonTapped(_ sender: UIButton) {
        guard let recipientEmail = emailTextField.text else {
            displayAlert(message: "Please enter your email address.")
            return
        }

        sendConfirmationEmail(to: recipientEmail)
    }

    /**
        Action method for the view bookings button.
        
        - Parameter sender: The button triggering the action.
        */
    @IBAction func viewBookingsButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "toBookings", sender: nil)
    }

    // MARK: - Email Handling
        
        /**
         Sends a confirmation email to the given recipient email address.
         -------- Does not work in simulator  ---------
         - Parameter recipientEmail: The recipient email address.
         */
    func sendConfirmationEmail(to recipientEmail: String) {
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients([recipientEmail])
            mailComposer.setSubject("Booking Confirmation")

            let messageBody = """
            Dear Customer,

            Thank you for booking with us!

            Here are your booking details:
            Campus: \(bookingDetails["Campus"] as? String ?? "")
            Contact Number: \(bookingDetails["ContactNumber"] as? String ?? "")
            Date: \(bookingDetails["Date"] as? String ?? "")
            Event Address: \(bookingDetails["EventAddress"] as? String ?? "")
            Event Name: \(bookingDetails["EventName"] as? String ?? "")
            Number of Players: \(bookingDetails["NumberOfPlayers"] as? String ?? "")
            Sport Type: \(bookingDetails["SportType"] as? String ?? "")

            We look forward to seeing you at the event.

            Best regards,
            Your Booking Team
            """
            mailComposer.setMessageBody(messageBody, isHTML: false)

            present(mailComposer, animated: true, completion: nil)
        } else {
            print("Device is unable to send email")
        }
    }

    /**
         Displays a confirmation popup for the sent email.
         
         - Parameter email: The recipient email address.
         */
    
    func displayConfirmationPopup(to email: String) {
        let alertController = UIAlertController(title: "Confirmation Sent", message: "Confirmation sent to \(email). Thank you for booking!", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] (_) in
            self?.performSegue(withIdentifier: "toBookings", sender: nil)
        }))
        present(alertController, animated: true, completion: nil)
    }

    /**
         Displays an alert with the given message.
         
         - Parameter message: The alert message.
         */
    func displayAlert(message: String) {
        let alertController = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - MFMailComposeViewControllerDelegate

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true) { [weak self] in
            if result == .sent {
                if let email = self?.emailTextField.text {
                    self?.displayConfirmationPopup(to: email)
                }
            }
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toBookings", let destinationVC = segue.destination as? ViewBookingsScreen {
            destinationVC.bookingId = bookingId
        }
    }
}

