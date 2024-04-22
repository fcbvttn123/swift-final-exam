import UIKit
import SQLite3

// Created by David
// These Imports are used for Firebase - Authentication
import FirebaseCore
import GoogleSignIn
import FirebaseAuth

//Created by David
// These Imports are used for Firebase - Firestore Database
import FirebaseFirestore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    //For Sqlite Database
    var window: UIWindow?
    var databaseName : String? = "group.db"
    var databasePath : String?
    var people : [Data] = []

    // Created by David
    // Currently Sign-in User Information
    // Will be changed after successful sign-in
    var isLoggedIn: Bool = false
    var username: String = ""
    var givenName: String = ""
    var email: String = ""
    var imgUrl: URL?
    var homeCampus = ""
    var DOB = "" 
    var AvailableCampuses : [String] = []
    
    static let shared = AppDelegate()
       
    var currentUserUID: String?
    
    // Created by David
    // This code is used for Google Sign-in
    var segueIdentiferForSignIn: String = "toHome"
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        
        let documentPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDir = documentPaths[0]
        databasePath = documentsDir.appending("/" + databaseName!)
        
        // Google Sign-in
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }
        
        // Handle database operations
        checkAndCreateDatabase()
        readDataFromDatabase()
        
        // Return true if the URL was handled by either Facebook or Google sign-in
        return false
    }

    
    // Function to check if the database exists, if not, create it
    func checkAndCreateDatabase()
    {
        var success = false
        let fileManager = FileManager.default
        
        success = fileManager.fileExists(atPath: databasePath!)
    
        if success
        {
            return
        }
    
        let databasePathFromApp = Bundle.main.resourcePath?.appending("/" + databaseName!)
        
        
            try? fileManager.copyItem(atPath: databasePathFromApp!, toPath: databasePath!)
       
        return;
    }
    
    // Function to read data from the SQLite database
    func readDataFromDatabase()
    {
    people.removeAll()
    
    
        var db: OpaquePointer? = nil
        
        if sqlite3_open(self.databasePath, &db) == SQLITE_OK {
            print("Successfully opened connection to database at \(self.databasePath)")
            
            var queryStatement: OpaquePointer? = nil
            var queryStatementString : String = "select * from data"
            
            if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                
                while( sqlite3_step(queryStatement) == SQLITE_ROW ) {
            
                    let id: Int = Int(sqlite3_column_int(queryStatement, 0))
                    let cuser = sqlite3_column_text(queryStatement, 1)
                    let cpass = sqlite3_column_text(queryStatement, 2)
                    
                    let uname = String(cString: cuser!)
                    let pass = String(cString: cpass!)
           
                    let data : MyData = MyData.init()
                    data.initWithData(theRow: id, theName: uname, thePass: pass)
                   // people.append(data)
                    
                    print("Query Result:")
                    print("\(id) | \(uname)")
                    
                }
                sqlite3_finalize(queryStatement)
            } else {
                print("SELECT statement could not be prepared")
            }
            
        
            sqlite3_close(db);

        } else {
            print("Unable to open database.")
        }
    
    }
    
    // Function to insert data into the SQLite database
    func insertIntoDatabase(person : MyData) -> Bool
    {
        var db: OpaquePointer? = nil
        var returnCode : Bool = true
        
        if sqlite3_open(self.databasePath, &db) == SQLITE_OK {
            print("Successfully opened connection to database at \(self.databasePath)")
            
            var insertStatement: OpaquePointer? = nil
            var insertStatementString : String = "insert into data values(NULL, ?, ?)"
            print("step1 done")
            
            if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
               
                let nameStr = person.Username! as NSString
                let passStr = person.Password! as NSString
                print("step3 done")
                sqlite3_bind_text(insertStatement, 1, nameStr.utf8String, -1, nil)
                sqlite3_bind_text(insertStatement, 2, passStr.utf8String, -1, nil)
                
                if sqlite3_step(insertStatement) == SQLITE_DONE {
                    let rowID = sqlite3_last_insert_rowid(db)
                    print("Successfully inserted row. \(rowID)")
                } else {
                    print("Could not insert row.")
                    returnCode = false
                }
                sqlite3_finalize(insertStatement)
            } else {
                print("INSERT statement could not be prepared.")
                returnCode = false
            }
     
            sqlite3_close(db);
            
        } else {
            print("Unable to open database.")
            returnCode = false
        }
        return returnCode
    }
    
    // Function to setup Google Sign-in
    func setupGoogleSignIn() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
    }
    
    // Created by David
    // This function is used to fetch all account information from firestore
    // This function is mostly used for checkCredentials() function
    func fetchAccountInformationFromFirestore() async throws -> [String: Any] {
        let collection = Firestore.firestore().collection("accounts")
        let querySnapshot = try await collection.getDocuments()
        var data = [String: Any]()
        for document in querySnapshot.documents {
            data[document.documentID] = document.data()
        }
        return data
    }
    
    // Created by David
    // This function is used to check entered credentials with all account information retrieved form the fetchAccountInformationFromFirestore()
    // Check the README file for how to use this function 
    func checkCredentials(userNameEntered: String, passwordEntered: String) async -> Bool {
        do {
            let fetchedData = try await fetchAccountInformationFromFirestore()
            
            for (_, value) in fetchedData {
                // Check if value is a dictionary
                guard let userData = value as? [String: Any],
                      let username = userData["username"] as? String,
                      let password = userData["password"] as? String else {
                    continue
                }
                // Check if username and password match the arguments
                if username == userNameEntered && password == passwordEntered {
                    
                    return true // Credentials match, return true
                }
            }
            // No matching credentials found
            return false
        } catch {
            print("Error fetching data from Firestore: \(error)")
            // Return false in case of any error
            return false
        }
    }
    
    // System Generated
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Created by David
        // This code is used to configure Google Firebase
        FirebaseApp.configure()
        
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }


}

