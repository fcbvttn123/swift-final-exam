/*
 Author: Fizza Imran
 Group Name: Byte_Buddies
 Group Members:
 - Tran Thanh Ngan Vu 991663076
 - Chahat Jain 991668960
 - Fizza Imran 991670304
 - Chakshita Gupta 991653663
 - Joshua Jocson 991657009
 Description: This class allows users to add a play event, including selecting a campus, entering event details, and adding the event to Firestore.
 */
import UIKit
import FirebaseFirestore

class AddPlayScreen: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // MARK: - Properties
    var homeCampus: String? // variable to store home campus
    var availableCampuses: [(name: String, city: String, latitude: Double, longitude: Double, number: String, postalCode: String, state: String, street: String, url: String)] = [] // Dictionary to store Campus info
    var selectedCampusIndex: Int = 0 // Variable to store campus index
    
    // MARK: - Outlets
    @IBOutlet var campusPickerView: UIPickerView!
    @IBOutlet var eventNameTextField: UITextField!
    @IBOutlet var datePicker: UIDatePicker!
    @IBOutlet var contactNumberTextField: UITextField!
    @IBOutlet var eventAddressTextField: UITextField!
    @IBOutlet var cityTextField: UITextField!
    @IBOutlet var sportTypeTextField: UITextField!
    @IBOutlet var numberOfPlayersTextField: UITextField!
    @IBOutlet var countryTextField: UITextField!
    @IBOutlet var provinceTextField: UITextField!
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchAvailableCampuses()
    }
    
    // This function is used to make the keyboard disappear when we tap the "return" key
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
    
    // MARK: - UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return availableCampuses.count
    }
    
    // MARK: - UIPickerViewDelegate
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let campus = availableCampuses[row]
        return "\(campus.name) (\(campus.city))"
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.text = "\(availableCampuses[row].name) (\(availableCampuses[row].city))"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 9.0)
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedCampusIndex = row
    }
    
    // MARK: - Firestore Integration
    
    /// Fetches available campuses from Firestore for the current user.
    func fetchAvailableCampuses() {
        guard let currentUserUID = AppDelegate.shared.currentUserUID else {
            print("Error: Current user UID is nil")
            return
        }
        
        let profilesCollection = Firestore.firestore().collection("Profiles")
        
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
                    print("Available Campuses: \(self.availableCampuses)")
                }
            } else {
                print("Campuses data not found in profile document")
            }
        }
    }
    
    // MARK: - Action Methods
    @IBAction func addPlayButtonTapped(_ sender: UIButton) {
        guard let eventName = eventNameTextField.text, !eventName.isEmpty,
              let eventAddress = eventAddressTextField.text, !eventAddress.isEmpty,
              let city = cityTextField.text, !city.isEmpty,
              let sportType = sportTypeTextField.text, !sportType.isEmpty,
              let country = countryTextField.text, !country.isEmpty,
              let province = provinceTextField.text, !province.isEmpty
        else {
            // At least one mandatory field is missing, show alert
            displayAlertForMissingFields()
            return
        }
        
        // Check if contactNumber is numeric
        guard let contactNumber = contactNumberTextField.text, !contactNumber.isEmpty, let _ = Double(contactNumber) else {
            displayAlert(message: "Contact number must be numeric.")
            return
        }
        
        // Check if numberOfPlayers is numeric
        guard let numberOfPlayers = numberOfPlayersTextField.text, !numberOfPlayers.isEmpty, let _ = Int(numberOfPlayers) else {
            displayAlert(message: "Number of players must be numeric.")
            return
        }
        
        // All mandatory fields are filled out and numeric, proceed to add the event to Firestore
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = dateFormatter.string(from: datePicker.date)
        let campus = availableCampuses[selectedCampusIndex].name
        
        // Add the event to Firestore
        addEventToFirestore(eventName: eventName, date: dateString, contactNumber: contactNumber, eventAddress: eventAddress, city: city, sportType: sportType, numberOfPlayers: numberOfPlayers, campus: campus)
    }
    
    // MARK: - Helper Methods
    
    /// Displays an alert with the given message.
    func displayAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    /// Displays an alert for missing fields.
    func displayAlertForMissingFields() {
        let alert = UIAlertController(title: "Missing Fields", message: "Please fill out all mandatory fields.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    /// Normalizes the given campus name.
    func normalizeCampusName(_ campusName: String) -> String {
        // Remove non-alphanumeric characters and replace spaces with a consistent separator
        let allowedCharacters = CharacterSet.alphanumerics
        let normalized = campusName.components(separatedBy: allowedCharacters.inverted)
            .joined(separator: "-")
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
        return normalized
    }
    
    /// Adds the event to Firestore.
    func addEventToFirestore(eventName: String, date: String, contactNumber: String, eventAddress: String, city: String, sportType: String, numberOfPlayers: String, campus: String) {
        // Combine address, city, province, and country into a single address string
        let combinedAddress = "\(eventAddress), \(city), \(provinceTextField.text ?? ""), \(countryTextField.text ?? "")"
        
        // Add the event to Firestore collection "Plays"
        let db = Firestore.firestore()
        let playsCollection = db.collection("Plays")
        
        let selectedCampus = availableCampuses[selectedCampusIndex]
        let documentID = "\(normalizeCampusName(selectedCampus.name))_\(normalizeCampusName(selectedCampus.city))"
        
        // Retrieve existing data from Firestore
        playsCollection.document(documentID).getDocument { (document, error) in
            if let error = error {
                print("Error fetching document: \(error.localizedDescription)")
                return
            }
            
            var eventDataArray = [[String: Any]]()
            
            if let document = document, document.exists {
                if let existingEventDataArray = document.data()?["EventData"] as? [[String: Any]] {
                    eventDataArray = existingEventDataArray
                }
            }
            
            // Create new event data
            let newEventData: [String: Any] = [
                "EventName": eventName,
                "Date": date,
                "ContactNumber": contactNumber,
                "EventAddress": combinedAddress, // Use combined address
                "City": city,
                "SportType": sportType,
                "NumberOfPlayers": numberOfPlayers
            ]
            
            // Append new event data to existing array
            eventDataArray.append(newEventData)
            
            // Update Firestore document with the new data
            playsCollection.document(documentID).setData(["EventData": eventDataArray]) { error in
                if let error = error {
                    print("Error adding event: \(error.localizedDescription)")
                } else {
                    print("Event added successfully!")
                    // Show popup saying Event Added!
                    let alert = UIAlertController(title: "Success", message: "Event Added!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
}

