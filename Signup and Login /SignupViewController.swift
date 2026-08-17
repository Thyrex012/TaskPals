//
//  SignupViewController.swift
//  TaskPals
//
//  Created by B Ouk on 29/9/25.
//

import UIKit
import FirebaseAuth

class SignupViewController: UIViewController {
    
    weak var databaseController: DatabaseProtocol?
    var authHandle: AuthStateDidChangeListenerHandle?
    
    @IBOutlet weak var firstNameOutlet: UITextField!
    @IBOutlet weak var lastNameOutlet: UITextField!
    @IBOutlet weak var emailOutlet: UITextField!
    @IBOutlet weak var passwordOutlet: UITextField!
    @IBOutlet weak var confirmPasswordOutlet: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set self as the auth listener
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
           let dbController = appDelegate.databaseController {
            databaseController = dbController
        }

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    /**
     this function is called the moment the confirm button is pressed, the firstname and outlets will be checked first to see if they're empty and if everything checks out
     we'll call on the databseController's signup function where the databseController was instantiated from the app delegate
     */
    @IBAction func confirmSignup(_ sender: Any) {
        guard let firstName = firstNameOutlet.text, !firstName.isEmpty,
              let lastName = lastNameOutlet.text, !lastName.isEmpty,
              let email = emailOutlet.text, !email.isEmpty,
              let password = passwordOutlet.text, !password.isEmpty,
              let confirmPassword = confirmPasswordOutlet.text, !confirmPassword.isEmpty else {
            showAlert(title: "Error", message: "Please fill in all fields")
            return
        }
        
        guard password == confirmPassword else {
            showAlert(title: "Error", message: "Passwords do not match")
            return
        }
        
        databaseController?.signup(email: email, password: password, firstName: firstName, lastName: lastName) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    //Cant have an alert being shown as the view controller will be changed to the settings vc
                   print("going to TaskPals menu")
                case .failure(let error):
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    /**
     The authentication listener is added to listen to any changes as the screen comes into view
     */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        authHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            guard let self = self else { return }
            if let _ = user {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let tabBarController = storyboard.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController {
                    self.navigationController?.setViewControllers([tabBarController], animated: true)
                }
            }
        }
    }

    /**
     The authentication listener is removed as we leave the signup screen
     */
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Remove listener
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
