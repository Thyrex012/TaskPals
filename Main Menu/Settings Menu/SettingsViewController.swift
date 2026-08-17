//
//  SettingsViewController.swift
//  TaskPals
//
//  Created by B Ouk on 29/9/25.
//

import UIKit
import FirebaseAuth

class SettingsViewController: UIViewController {
    
    weak var databaseController: DatabaseProtocol?
    var authHandle: AuthStateDidChangeListenerHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
           let dbController = appDelegate.databaseController {
            databaseController = dbController
        }
        // Do any additional setup after loading the view.
    }

    //Button used to log the user out of their account
    @IBAction func logoutOfAccount(_ sender: Any) {
        databaseController?.logout()
    }
    
    /**
     The authentication listener is added to listen to any changes as the screen comes into view
     */
    override func viewWillAppear(_ animated: Bool) {
        guard let firebaseController = databaseController as? FirebaseController else { return }
        authHandle = firebaseController.authController.addStateDidChangeListener { [weak self] auth, user in
            guard let self = self else { return }
            if user == nil {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let WelcomeVC = storyboard.instantiateViewController(withIdentifier: "WelcomeVC") as? WelcomeViewController {
                    self.navigationController?.setViewControllers([WelcomeVC], animated: true)
                }
            }
        }
    }
    
    /**
     The authentication state listener is removed as we get out of the settings screen
     */
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Remove listener
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
