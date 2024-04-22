/*
Author: Fizza Imran
Group Name: Byte_Buddies
Group Members:
- Tran Thanh Ngan Vu 991663076
- Chahat Jain 991668960
- Fizza Imran 991670304
- Chakshita Gupta 991653663
 - Joshua Jocson 991657009
Description: This view controller displays a screen for picking and displaying events for different campuses.
*/

import UIKit
import FirebaseFirestore

class PickPlayScreen: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource ,UITableViewDelegate, UITableViewDataSource{

    // MARK: - Properties
    
    var homeCampus: String? // variable to store home campus
    var availableCampuses: [(name: String, city: String, latitude: Double, longitude: Double, number: String, postalCode: String, state: String, street: String, url: String)] = [] // Dictionary to store Campus info
    var selectedCampusIndex: Int = 0  // Variable to store campus index
    var events: [Event] = [] // Array to store events
    
    // Event struct
    struct Event {
        let eventName: String
        let eventDate: Date
        let eventLocation: String
    }
    
    @IBOutlet var urlButton: UIButton! // Variable for URL
    @IBOutlet var phoneNumberLabel: UILabel! // variable for phone number
    @IBOutlet var campusPickerView: UIPickerView! // variable for picker
    @IBOutlet var tableView: UITableView! // Variable for table

    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up picker view
        campusPickerView.delegate = self
        campusPickerView.dataSource = self

        // Set up table view
        tableView.delegate = self
        tableView.dataSource = self

        // Fetch available campuses from Firestore
        fetchAvailableCampuses()

        // Add action to the URL button
        urlButton.addTarget(self, action: #selector(urlButtonTapped), for: .touchUpInside)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Fetch events for the initially selected campus
        let selectedCampus = "\(normalizeCampusName(availableCampuses[selectedCampusIndex].name))_\(normalizeCampusName(availableCampuses[selectedCampusIndex].city))"
        fetchEvents(for: selectedCampus)
    }

    // This function is used to make the keyboard disappear when we tap the "return" key
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
    
    // MARK: - UIPickerViewDataSource

    // This method returns the number of components (columns) in the picker view.
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    // This method returns the number of rows in the specified component (column) in the picker view.
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return availableCampuses.count
    }

    // This method returns the title for the row specified by the picker view for a given component.
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let campus = availableCampuses[row]
        return "\(campus.name) (\(campus.city))"
    }
    
    // This method returns the view used for the row specified by the picker view for a given component.
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.text = "\(availableCampuses[row].name) (\(availableCampuses[row].city))"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 9.0)
        return label
    }
    
    // This method is called when a row is selected in the picker view.
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedCampusIndex = row
        updateLabels(for: row)
        let selectedCampus = "\(normalizeCampusName(availableCampuses[row].name))_\(normalizeCampusName(availableCampuses[row].city))"
        fetchEvents(for: selectedCampus) // Fetch events for the selected campus
    }

    // MARK: - Firestore Integration
    
    // Fetch available campuses from Firestore
    func fetchAvailableCampuses() {
        guard let currentUserUID = AppDelegate.shared.currentUserUID else {
            print("Error: Current user UID is nil")
            return
        }

        // store collection Profiles to profilesCollection
        let profilesCollection = Firestore.firestore().collection("Profiles")

        // check if there is documment with current ID
        profilesCollection.document(currentUserUID).getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            if let error = error {
                print("Error fetching profile document: \(error.localizedDescription)")
                return
            }

            guard let document = document, document.exists else {
                print("Profile document does not exist")
                return
            }

            // store info into campusesData variable
            if let campusesData = document.data()?["Campuses"] as? [[String: Any]] {
                self.availableCampuses.removeAll()
                for campusData in campusesData {
                    if let name = campusData["name"] as? String,
                       let city = campusData["city"] as? String,
                       let latitude = campusData["latitude"] as? Double,
                       let longitude = campusData["longitude"] as? Double,
                       let number = campusData["number"] as? String,
                       let postalCode = campusData["postalCode"] as? String,
                       let state = campusData["state"] as? String,
                       let street = campusData["street"] as? String,
                       let url = campusData["url"] as? String {
                        self.availableCampuses.append((name: name, city: city, latitude: latitude, longitude: longitude, number: number, postalCode: postalCode, state: state, street: street, url: url))
                    }
                }
                DispatchQueue.main.async {
                    self.campusPickerView.reloadAllComponents()
                    self.updateLabels(for: self.selectedCampusIndex)
                    // Debugging: Print available campuses
                    print("Available Campuses: \(self.availableCampuses)")
                }
            } else {
                print("Campuses data not found in profile document")
            }
        }
    }

    // Fetch events for the very first campus in picker view - so dispaly is not empty
    func fetchEvents() {
        let selectedRow = campusPickerView.selectedRow(inComponent: 0)
        let selectedCampus = availableCampuses[selectedRow]
        let campusName = "\(normalizeCampusName(selectedCampus.name))_\(normalizeCampusName(selectedCampus.city))"
        print(campusName)
        let playsCollection = Firestore.firestore().collection("Plays")

        playsCollection.document(campusName).getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            if let error = error {
                print("Error fetching events document: \(error.localizedDescription)")
                return
            }

            guard let document = document, document.exists else {
                print("Events document does not exist for campus: \(campusName)")
                // Show pop-up message indicating no events registered for this campus
                self.showNoEventsAlert()
                return
            }

            // save event details in eventData
            if let eventData = document.data()?["EventData"] as? [[String: Any]] {
                self.events.removeAll()
                for eventItem in eventData {
                    if let eventName = eventItem["EventName"] as? String,
                       let eventDateStr = eventItem["Date"] as? String,
                       let eventDate = self.date(from: eventDateStr),
                       let eventLocation = eventItem["EventAddress"] as? String {
                        let event = Event(eventName: eventName, eventDate: eventDate, eventLocation: eventLocation)
                        self.events.append(event)
                    }
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData() // Reload TableView with fetched events
                }
            } else {
                print("EventData not found in events document for campus: \(campusName)")
                // Show pop-up message indicating no events registered for this campus
                self.showNoEventsAlert()
            }
        }
    }
    
    // Fetch events for the specified campus from Firestore
    func fetchEvents(for campusName: String) {
        let playsCollection = Firestore.firestore().collection("Plays")

        playsCollection.document(campusName).getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            if let error = error {
                print("Error fetching events document: \(error.localizedDescription)")
                return
            }

            guard let document = document, document.exists else {
                print("Events document does not exist for campus: \(campusName)")
                // Show pop-up message indicating no events registered for this campus
                self.showNoEventsAlert()
                return
            }

            if let eventData = document.data()?["EventData"] as? [[String: Any]] {
                self.events.removeAll()
                for eventItem in eventData {
                    if let eventName = eventItem["EventName"] as? String,
                       let eventDateStr = eventItem["Date"] as? String,
                       let eventDate = self.date(from: eventDateStr),
                       let eventLocation = eventItem["EventAddress"] as? String {
                        let event = Event(eventName: eventName, eventDate: eventDate, eventLocation: eventLocation)
                        self.events.append(event)
                    }
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData() // Reload TableView with fetched events
                }
            } else {
                print("EventData not found in events document for campus: \(campusName)")
                // Show pop-up message indicating no events registered for this campus
                self.showNoEventsAlert()
            }
        }
    }
    
    // MARK: - TableView Delegate and DataSource
    
    // This method returns the number of rows in the table view section.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    // This method returns the height for each row in the table view.
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    // This method configures and returns a cell for a given index path in the table view.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath)
        let event = events[indexPath.row]
        
        // Configure the cell
        let eventNameAttributedString = attributedEventName(event.eventName)
        let eventDateTimeAttributedString = attributedDateTime(for: event.eventDate)
        let eventAddressAttributedString = attributedAddress(for: event.eventLocation)
        
        // Combine all attributed strings
        let combinedAttributedString = NSMutableAttributedString()
        combinedAttributedString.append(eventNameAttributedString)
        combinedAttributedString.append(NSAttributedString(string: "\n"))
        combinedAttributedString.append(eventDateTimeAttributedString)
        combinedAttributedString.append(NSAttributedString(string: "\n"))
        combinedAttributedString.append(eventAddressAttributedString)
        
        // Assign the combined attributed string to the cell's text label
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.attributedText = combinedAttributedString
        
        // Configure other properties of the cell as needed
        
        return cell
    }
    
    // Configure table view cell with event details
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Populate TableView with fetched events
        let selectedCampus = "\(normalizeCampusName(availableCampuses[selectedCampusIndex].name))_\(normalizeCampusName(availableCampuses[selectedCampusIndex].city))"
        let selectedRow = indexPath.row
        let selectedCampusInfo = (campus: selectedCampus, row: selectedRow)
        performSegue(withIdentifier: "toViewEvent", sender: selectedCampusInfo)
    }

    // MARK: - Other Methods
    // Creates attributed string for event name
    func attributedEventName(_ eventName: String) -> NSAttributedString {
        let attributedString = NSAttributedString(string: eventName, attributes: [.font: UIFont.boldSystemFont(ofSize: 16), .foregroundColor: UIColor.blue])
        return attributedString
    }

    // Creates attributed string for Date and Time
    func attributedDateTime(for date: Date) -> NSAttributedString {
        // Create a formatter for date and time
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy 'at' HH:mm"
        
        // Create attributed string for date and time
        let dateString = dateFormatter.string(from: date)
        let attributedString = NSAttributedString(string: "Date & Time: \(dateString)", attributes: [.font: UIFont.italicSystemFont(ofSize: 14)])
        
        return attributedString
    }
    
    // Creates attributed string for address
    func attributedAddress(for address: String) -> NSAttributedString {
        let attributedString = NSAttributedString(string: "Address: \(address)", attributes: [.font: UIFont.italicSystemFont(ofSize: 14)])
        
        return attributedString
    }

    // Creates attributed string for sport type
    func attributedSportType(for sportType: String) -> NSAttributedString {
        let attributedString = NSAttributedString(string: sportType, attributes: [.font: UIFont.italicSystemFont(ofSize: 14)])
        
        return attributedString
    }

    // MARK: - Helper Functions
    // Update labels and button title based on selected campus
    func updateLabels(for index: Int) {
        guard !availableCampuses.isEmpty else {
            return
        }
        let campus = availableCampuses[index]
        phoneNumberLabel.text = campus.number
        // Update button title with URL
        urlButton.setTitle("Website", for: .normal)
    }
    
    // Show alert when no events are available for the selected campus
    func showNoEventsAlert() {
        let alertController = UIAlertController(title: "No Events", message: "There are no events registered for this campus.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

    // Converts string to date
    func date(from dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.date(from: dateString)
    }

    // Normalize campus name for standarized database storage
    func normalizeCampusName(_ campusName: String) -> String {
        // Remove non-alphanumeric characters and replace spaces with a consistent separator
        let allowedCharacters = CharacterSet.alphanumerics
        let normalized = campusName.components(separatedBy: allowedCharacters.inverted)
                                  .joined(separator: "-")
                                  .lowercased()
                                  .replacingOccurrences(of: "-", with: "_")
        return normalized
    }
    
    // MARK: - Button Action
    // based on URL displays the website
    @objc func urlButtonTapped() {
        guard let urlString = urlButton.title(for: .normal), let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        performSegue(withIdentifier: "toWebView", sender: url.absoluteString)
    }


    // MARK: - Navigation
    // Prepare for segue
    // Condditional navigation to WebView or EventDisplayScreen

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toWebView", let urlString = sender as? String, let destinationVC = segue.destination as? WebScreen {
            destinationVC.urlString = urlString
        }
        
        if segue.identifier == "toViewEvent", let destinationVC = segue.destination as? EventDispalyScreen {
            if let selectedCampusInfo = sender as? (campus: String, row: Int) {
                destinationVC.selectedCampus = selectedCampusInfo.campus
                destinationVC.selectedRow = selectedCampusInfo.row
            }
        }
    }


    
}



