//
//  MyData.swift
//  group-project
//
//  Created by Default User on 4/12/24.
//

import UIKit

// Class representing data used in the project
class MyData: NSObject {
    var id : Int?
    var Username : String?
    var Password : String?
    
    // Initialize data with provided information
    func initWithData(theRow i:Int, theName n:String, thePass p:String)
    {
        id = i
        Username = n
        Password = p
    }
        
}
