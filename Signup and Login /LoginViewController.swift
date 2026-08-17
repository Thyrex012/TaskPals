//
//  LoginViewController.swift
//  TaskPals
//
//  Created by B Ouk on 29/9/25.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {
    
    weak var databaseController: DatabaseProtocol?
    var authHandle: AuthStateDidChangeListenerHandle?

    @IBOutlet weak var emailOutlet: UITextField!
    @IBOutlet weak var passwordOutlet: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
           let dbController = appDelegate.databaseController {
            databaseController = dbController
        }

        // Do any additional setup after loading the view.
    }
    
    /**
     This function gets called the moment the confirm button is pressed which will allow the user to login so long as they entered in
     the necessary info into the email and password text fields. the databseController uses the FirebaseConntroller's login method
     */
    @IBAction func confirmLogin(_ sender: Any) {
        guard let email = emailOutlet.text,
              let password = passwordOutlet.text else {
            showAlert(title: "Error", message: "Please fill in all fields")
            return
        }
        databaseController?.login(email: email, password: password){ [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("going to Taskpals menu")
                case .failure(let error):
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
            
        }
    }
    
    /**
     An authentication state listener is added the moment the view will appear
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
     The authentication state listener is removed as we get out of the login screen
     */
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Remove listener
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
