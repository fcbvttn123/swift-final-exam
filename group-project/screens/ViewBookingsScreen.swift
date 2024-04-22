/*
Author: Fizza Imran
Group Name: Byte_Buddies
Group Members:
- Tran Thanh Ngan Vu 991663076
- Chahat Jain 991668960
- Fizza Imran 991670304
- Chakshita Gupta 991653663
- Joshua Jocson 991657009
Description: A screen for displaying the list of bookings made by the user.
*/
import UIKit
import FirebaseFirestore

// Protocol to handle delete action
protocol DeleteBookingDelegate: AnyObject {
    func deleteBooking(at index: Int)
}

// Custom UITableViewCell for booking display
class BookingTableViewCell: UITableViewCell {
    @IBOutlet var eventNameLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var campusLabel: UILabel!
    weak var delegate: DeleteBookingDelegate?

    // Configure cell with booking details
       func configure(with bookingDetails: [String: Any], at index: Int) {
           eventNameLabel.text = bookingDetails["EventName"] as? String ?? ""
           dateLabel.text = "Date: \(bookingDetails["Date"] as? String ?? "")"
           addressLabel.text = "Address: \(bookingDetails["EventAddress"] as? String ?? "")"
           
           // Format and set the campus name
           if let campus = bookingDetails["Campus"] as? String {
               let formattedCampus = campus.replacingOccurrences(of: "_", with: " ").capitalized
               campusLabel.text = "Campus: \(formattedCampus)"
           } else {
               campusLabel.text = "Campus: N/A"
           }
       }


    // Handle delete button tap
    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        delegate?.deleteBooking(at: tag)
    }
}

/*
 This view controller presents a list of bookings retrieved from Firestore. It conforms to UITableViewDataSource and
 UITableViewDelegate protocols to manage the table view displaying the bookings.
 */
class ViewBookingsScreen: UIViewController, UITableViewDataSource, UITableViewDelegate, DeleteBookingDelegate {

    @IBOutlet var tableView: UITableView!

    var bookingId: String?
    var bookingData: [[String: Any]] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        fetchBookingData()
    }

    // This function dismisses the keyboard when return key is pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    /**
     Fetches the booking data from Firestore.

     This method retrieves the booking data associated with the provided booking ID from Firestore. It updates the `bookingData` property and reloads the table view to reflect the changes.

     - Note: This method requires a valid booking ID to fetch the data from Firestore.
     - Throws:
        - If there is an error fetching the booking data from Firestore, it prints an error message.
     */
    
    func fetchBookingData() {
        guard let bookingId = bookingId else {
            print("Booking ID is nil")
            return
        }

        let db = Firestore.firestore()
        db.collection("Bookings").document(bookingId).getDocument { [weak self] (document, error) in
            guard let self = self else { return }

            if let error = error {
                print("Error fetching booking data: \(error.localizedDescription)")
                return
            }

            guard let document = document, document.exists else {
                print("Booking document does not exist")
                return
            }

            if let bookingData = document.data()?["BookingData"] as? [[String: Any]] {
                self.bookingData = bookingData
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - DeleteBookingDelegate

    /**
     Deletes a booking at the specified index.

     This method removes the booking data from the `bookingData` array at the specified index. It then updates Firestore to reflect the deletion. If the update fails, it re-adds the removed booking data to the array and reloads the table view.

     - Parameter index: The index of the booking to be deleted.

     - Note: This method requires a valid booking ID to update the data in Firestore.

     - Throws:
        - If there is an error updating the booking data in Firestore, it prints an error message.
     */
    
    func deleteBooking(at index: Int) {
        guard let bookingId = bookingId else {
            print("Booking ID is nil")
            return
        }

        // Remove the booking data from the array
        let removedBooking = bookingData.remove(at: index)
        tableView.reloadData()

        // Delete the booking from Firestore
        let db = Firestore.firestore()
        db.collection("Bookings").document(bookingId).updateData(["BookingData": bookingData]) { error in
            if let error = error {
                print("Error updating booking data: \(error.localizedDescription)")
                // If updating Firestore fails, re-add the removed booking data
                self.bookingData.insert(removedBooking, at: index)
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookingData.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "bookingCell", for: indexPath) as? BookingTableViewCell else {
            fatalError("Failed to dequeue BookingTableViewCell.")
        }

        cell.tag = indexPath.row
        cell.delegate = self
        cell.configure(with: bookingData[indexPath.row], at: indexPath.row)

        return cell
    }
}

