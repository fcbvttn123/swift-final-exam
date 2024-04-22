//
//  Booking.swift
//  group-project
//
//  Created by fizza imran on 2024-04-03.
//

import Foundation

// Class representing a booking made by a user
class Booking {
    var bookingID: Int
    var userID: Int
    var teamID: Int
    var status: String
    
    // Here wenitialize a new Booking instance with the provided information
    init(bookingID: Int, userID: Int, teamID: Int, status: String) {
        self.bookingID = bookingID
        self.userID = userID
        self.teamID = teamID
        self.status = status
    }
}
