/*
Author: Tran Thanh Ngan Vu
Group Name: Byte_Buddies
Group Members:
- Tran Thanh Ngan Vu 991663076
- Chahat Jain 991668960
- Fizza Imran 991670304
- Chakshita Gupta 991653663
- Joshua Jocson 991657009
Description: Utilizing the EventKit framework, this view controller  manages (adds, modifies, deletes) PLAY events
*/

import UIKit
import EventKitUI
import EventKit

class LastTechViewController: UIViewController, EKEventViewDelegate, EKEventEditViewDelegate {
    
    func eventViewController(_ controller: EKEventViewController, didCompleteWith action: EKEventViewAction) {
        
    }
    
    //Handles event store instances
    let store = EKEventStore()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))
        navigationItem.title = "Events" //Sets navigation title
    }
    
    // Function to handle add button tap
    @objc func didTapAdd() {
        store.requestAccess(to: .event) { [weak self] success, error in
            if success, error == nil {
                DispatchQueue.main.async {
                    guard let store = self?.store else { return }
                    
                    // Create a new event
                    let newEvent = EKEvent(eventStore: store)
                    newEvent.startDate = Date()
                    newEvent.endDate = Date()
                    
                    // Create an event edit view controller
                    let vc = EKEventEditViewController()
                    vc.eventStore = store
                    vc.event = newEvent
                    vc.editViewDelegate = self // Set the delegate
                    self?.present(vc, animated: true, completion: nil)
                }
            }
        }
    }
    
    // This function handles event edit completion
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        switch action {
        case .saved:
            if let event = controller.event {
                // Event saved successfully, you can access the event data here
                print("Event Title: \(event.title ?? "Untitled Event")")
                print("Start Date: \(event.startDate)")
                print("End Date: \(event.endDate)")
                print("Location: \(event.location ?? "No Location")")
                print("Notes: \(event.notes ?? "No Notes")")
                print("All-Day: \(event.isAllDay ? "Yes" : "No")")
                print("Calendar: \(event.calendar.title)")
            }
        case .canceled:
            print("Event creation canceled")
        case .deleted:
            print("Event deleted")
        @unknown default:
            fatalError("Unknown action")
        }
        dismiss(animated: true, completion: nil)
    }
}
