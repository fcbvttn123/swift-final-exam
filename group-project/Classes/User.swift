//
//  User.swift
//  group-project
//
//  Created by fizza imran on 2024-04-03.
//

import Foundation

// Class representing a user with basic information
class User {
    var username: String
    var email: String
    var homeCampus: String
    
    // Here we itialize a new User instance with the necessary information
    init(username: String, email: String, homeCampus: String) {
        self.username = username
        self.email = email
        self.homeCampus = homeCampus
    }
}

