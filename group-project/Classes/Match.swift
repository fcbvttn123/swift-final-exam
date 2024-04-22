//
//  Match.swift
//  group-project
//
//  Created by fizza imran on 2024-04-03.
//

import Foundation

// Class representing a match event betwen player and place
class Match {
    var matchID: Int
    var dateTime: String
    var contact: Int
    var playercount : Int
    var instituelocation: String
    var address : String
    var createdBy : Int
    
    // Initialize a new Booking instance with provided information
    init(matchID: Int, dateTime: String, instituelocation: String, contact: Int, playerCount : Int, address : String, createdBy :Int) {
        self.matchID = matchID
        self.dateTime = dateTime
        self.contact = contact
        self.instituelocation = instituelocation
        self.playercount = playerCount
        self.address = address
        self.createdBy = createdBy
    }
}

