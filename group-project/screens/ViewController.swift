/*
Author: Tran Thanh Ngan Vu
Group Name: Byte_Buddies
Group Members:
- Tran Thanh Ngan Vu 991663076
- Chahat Jain 991668960
- Fizza Imran 991670304
- Chakshita Gupta 991653663
- Joshua Jocson 991657009
Description: This class manages user authentication using Firebase Authentication, including manual sign-in and sign-in with Google.
*/

import UIKit
import GoogleSignIn
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import CryptoKit
import FBSDKLoginKit
import FacebookLogin
import AVFoundation

class ViewController: UIViewController, UITextFieldDelegate, LoginButtonDelegate {

    func loginButton(_ loginButton: FBLoginButton!, didCompleteWith result: LoginManagerLoginResult!, error: Error!) {
      if let error = error {
        print(error.localizedDescription)
        return
      }
        print(result)
        performSegue(withIdentifier: "toHome", sender: nil)
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginKit.FBLoginButton) {
        print("Log out")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize Google Sign-In
        AppDelegate.shared.setupGoogleSignIn()
        
        // Set password field to secure text entry
        password.isSecureTextEntry = true
        
        // Facebook Signin
        let loginButton = FBLoginButton()
        loginButton.permissions = ["public_profile", "email"]
        loginButton.center = view.center
        loginButton.delegate = self
        //view.addSubview(loginButton)
    }
    
    // MARK: - Actions
    
    // This function is used to navigate back to this view controller
    @IBAction func toLoginScreen(sender: UIStoryboardSegue) {
        // No action needed
    }
    
    // MARK: - Outlets
    
    // Variables for username and password
    @IBOutlet var username: UITextField!
    @IBOutlet var password: UITextField!
    
    // Variable for submit button
    @IBOutlet var btn: UIButton!
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
    
    // MARK: - Database Operations
    
    // This function fetches all documents from a specified table
    func fetchDocuments(tableName: String) async throws -> [String: Any] {
        let collection = Firestore.firestore().collection(tableName)
        let querySnapshot = try await collection.getDocuments()
        var data = [String: Any]()
        for document in querySnapshot.documents {
            data[document.documentID] = document.data()
        }
        return data
    }
    
    // MARK: - Hash fuctionality
    
    // Author : Fizza Imran - hash Fuctionality
    // This function hashes the password using SHA-256 algorithm
    func hashPassword(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashedString = hashedData.compactMap { String(format: "%02x", $0) }.joined()
        return hashedString
    }
    
    // This function checks entered credentials against account information retrieved from Firestore
    func checkCredentials(userNameEntered: String, passwordEntered: String) async -> Bool {
        do {
            let fetchedData = try await fetchDocuments(tableName: "Profiles")
            
            for (documentId, value) in fetchedData {
                guard let userData = value as? [String: Any],
                      let username = userData["Username"] as? String,
                      let storedPasswordHash = userData["password"] as? String else {
                    continue
                }
                if username == userNameEntered {
                    let enteredPasswordHash = hashPassword(passwordEntered)
                    if storedPasswordHash == enteredPasswordHash {
                        AppDelegate.shared.currentUserUID = documentId
                        return true
                    }
                }
            }
            return false
        } catch {
            print("Error fetching data from Firestore: \(error)")
            return false
        }
    }
    
    // MARK: - Sign In Actions
    
    // This function handles manual sign-in
    @IBAction func signIn(_ sender: UIButton) {
        guard let usernameText = username.text, let passwordText = password.text else {
            return
        }
        
        Task {
            let success = await checkCredentials(userNameEntered: usernameText, passwordEntered: passwordText)
            if success {
                print(AppDelegate.shared.currentUserUID)
                self.performSegue(withIdentifier: AppDelegate.shared.segueIdentiferForSignIn, sender: nil)
                AppDelegate.shared.isLoggedIn = true
            } else {
                let alert = UIAlertController(title: "Error", message: "No Account with these credentials", preferredStyle: .alert)
                let closeAlertAction = UIAlertAction(title: "Close", style: .cancel)
                alert.addAction(closeAlertAction)
                self.present(alert, animated: true)
            }
        }
    }
    
    // This function adds a new document to Firestore for manual sign-in
    func addNewDocument(for documentReference: DocumentReference) {
        documentReference.setData([
            "Username": AppDelegate.shared.username
        ]) { error in
            if let error = error {
                print("Error adding document to profiles (Manual Sign-in): \(error)")
            } else {
                print("Document added successfully to profiles (Manual Sign-in)!")
                self.performSegue(withIdentifier: AppDelegate.shared.segueIdentiferForSignIn, sender: nil)
                AppDelegate.shared.isLoggedIn = true
            }
        }
    }
    
    // This function handles sign-in with Google
    @IBAction func signInWithGoogle(_ sender: UIButton) {
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [self] authentication, error in
            
            if error != nil {
                print("Google Sign-In error")
                return
            }
            
            guard let user = authentication?.user,
                  let idToken = user.idToken?.tokenString else { return }
            
            // Set values in AppDelegate
            AppDelegate.shared.username = user.profile?.name ?? ""
            AppDelegate.shared.givenName = user.profile?.givenName ?? ""
            AppDelegate.shared.email = user.profile?.email ?? ""
            
            if let currentUser = Auth.auth().currentUser {
                // Set values in AppDelegate
                AppDelegate.shared.currentUserUID = currentUser.uid
                
                // Print user info from App Delegate
                print("userID: \(AppDelegate.shared.currentUserUID!) \n" )
                print("username: \(AppDelegate.shared.username) \n" )
                print("givenname: \(AppDelegate.shared.givenName) \n" )
                print("email: \(AppDelegate.shared.email) \n" )
                print("Date of Birth: \(AppDelegate.shared.DOB) \n" )
                print("Home Campus: \(AppDelegate.shared.homeCampus) \n" )
                
                // Check if a document exists for the current user
                let collection = Firestore.firestore().collection("Profiles")
                let userDocument = collection.document(AppDelegate.shared.currentUserUID!)
                
                userDocument.getDocument { document, error in
                    if let document = document, document.exists {
                        print("Document already exists for the user")
                        // No need to add a new document, proceed with segue
                        self.performSegue(withIdentifier: AppDelegate.shared.segueIdentiferForSignIn, sender: nil)
                        AppDelegate.shared.isLoggedIn = true
                    } else {
                        // Document doesn't exist, add a new one
                        self.addNewDocument(for: userDocument)
                    }
                }
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            Auth.auth().signIn(with: credential) { _, _ in }
        }
    }
}

